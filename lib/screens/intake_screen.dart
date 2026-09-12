import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/case_score_response.dart';
import '../services/tulip_api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tulip_case.dart';
import '../theme/colors.dart';
import '../widgets/t_card.dart';

// ── ENUMS ──────────────────────────────────────────────────────────────────────
enum _ScanState { empty, loading, done }

enum _TriageState { waiting, ready, running, complete }

enum _StepState { done, active, future }

// ── DEMO SCENARIO ─────────────────────────────────────────────────────────────
class _ViewMock {
  final String label, detail;
  final double conf;
  final bool urgent;
  const _ViewMock({
    required this.label,
    required this.detail,
    required this.conf,
    required this.urgent,
  });
}

class _DemoScenario {
  final Map<String, _ViewMock> views;
  final CaseStatus status;
  final String finding;
  final double confidence;
  final String impression;
  final String resultTitle;
  final String resultSub;
  final String bannerText;
  final String bannerBadge;
  const _DemoScenario({
    required this.views,
    required this.status,
    required this.finding,
    required this.confidence,
    required this.impression,
    required this.resultTitle,
    required this.resultSub,
    required this.bannerText,
    required this.bannerBadge,
  });
}

const _placeholderMock =
    _ViewMock(label: '', detail: '', conf: 0, urgent: false);

/// Shown before a real triage result exists — has all 4 view keys so
/// `_scenario.views[view]!` never throws while the case is still pending.
const _emptyScenario = _DemoScenario(
  views: {
    'L-CC': _placeholderMock,
    'L-MLO': _placeholderMock,
    'R-CC': _placeholderMock,
    'R-MLO': _placeholderMock,
  },
  status: CaseStatus.pending,
  finding: '',
  confidence: 0,
  impression: '',
  resultTitle: '',
  resultSub: '',
  bannerText: '',
  bannerBadge: '',
);

FindingResult? _topValidatedFinding(List<FindingResult> findings) {
  final validated = findings.where((f) => f.validated).toList()
    ..sort((a, b) => b.probability.compareTo(a.probability));
  return validated.isEmpty ? null : validated.first;
}

Map<String, _ViewMock> _viewMocksFromResponse(CaseScoreResponse r) {
  final map = <String, _ViewMock>{};
  for (final v in r.views) {
    final top = _topValidatedFinding(v.findings);
    map[v.view] = _ViewMock(
      label: top?.name ?? 'No finding',
      detail: top != null ? 'Validated finding' : 'Normal breast tissue',
      conf: top?.probability ?? (1 - v.diagnosisProbability).clamp(0.0, 1.0),
      urgent: top != null,
    );
  }
  return map;
}

/// Maps a real backend response into the same shape the UI already renders,
/// so _StatusCard / _TriageCompleteCard / _TriageResultBanner need no changes.
_DemoScenario _scenarioFromResponse(CaseScoreResponse r) {
  final status = switch (r.caseSummary.recommendation) {
    'Tissue Biopsy Recommended' => CaseStatus.urgent,
    'Short Interval Follow Up (6 months)' => CaseStatus.review,
    'Routine Follow Up (1 year)' => CaseStatus.cleared,
    'Additional Imaging Needed' => CaseStatus.pending,
    _ => CaseStatus.pending,
  };

  final breast = r.breasts[r.caseSummary.diagnosisLaterality];
  final topFinding =
      breast != null ? _topValidatedFinding(breast.findings) : null;
  final findingText = topFinding != null
      ? '${topFinding.name}, ${r.caseSummary.diagnosisLaterality} breast'
      : 'No significant finding — bilateral';

  final (title, sub) = switch (status) {
    CaseStatus.urgent => (
        'Urgent — review required',
        'Case assigned to urgent queue'
      ),
    CaseStatus.review => (
        'Needs radiologist review',
        'Case added to review queue'
      ),
    CaseStatus.cleared => (
        'Auto-cleared ✓',
        'High-confidence bilateral screening'
      ),
    CaseStatus.pending => (
        'Additional imaging needed',
        '${r.caseSummary.missingViews.length} view(s) missing'
      ),
  };

  final confPct = (r.caseSummary.probabilityMalignant * 100).round();

  return _DemoScenario(
    views: _viewMocksFromResponse(r),
    status: status,
    finding: findingText,
    confidence: r.caseSummary.probabilityMalignant,
    impression: r.report.text, // shown verbatim, per FRONTEND.md §6
    resultTitle: title,
    resultSub: sub,
    bannerText:
        'AI analysis complete · $findingText — ${r.caseSummary.recommendation}.',
    bannerBadge: '$confPct% conf.',
  );
}

int _intakeCounter = 521;

class IntakeScreen extends StatefulWidget {
  final ValueChanged<TulipCase>? onIntakeComplete;
  final VoidCallback? onViewInWorklist;
  const IntakeScreen({this.onIntakeComplete, this.onViewInWorklist, super.key});
  @override
  State<IntakeScreen> createState() => _IntakeScreenState();
}

class _IntakeScreenState extends State<IntakeScreen> {
  final _scanStates = <String, _ScanState>{
    'L-CC': _ScanState.empty,
    'L-MLO': _ScanState.empty,
    'R-CC': _ScanState.empty,
    'R-MLO': _ScanState.empty,
  };
  final _scanFiles = <String, PlatformFile?>{
    'L-CC': null,
    'L-MLO': null,
    'R-CC': null,
    'R-MLO': null,
  };

  static const _acceptedExtensions = [
    'dcm',
    'dicom',
    'png',
    'jpg',
    'jpeg',
    'tif',
    'tiff',
  ];

  Uint8List? _previewBytes(String view) {
    final f = _scanFiles[view];
    if (f == null) return null;
    final ext = (f.extension ?? '').toLowerCase();
    if (ext == 'dcm' || ext == 'dicom') return null;
    return f.bytes;
  }

  _TriageState _triageState = _TriageState.waiting;
  final _api = const TulipApiService();

  late String _patientId;
  late final TextEditingController _ageCtrl;
  String _studyType = 'Bilateral screening';
  String _familyHistory = 'Yes — 1st degree';
  _DemoScenario _scenario = _emptyScenario;

  @override
  void initState() {
    super.initState();
    _patientId = 'VDR-00$_intakeCounter';
    _ageCtrl = TextEditingController(text: 'F, 52');
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    super.dispose();
  }

  int get _uploaded =>
      _scanStates.values.where((s) => s == _ScanState.done).length;
  bool get _allDone => _uploaded == 4;

  void _reset() => setState(() {
        for (final k in _scanStates.keys) {
          _scanStates[k] = _ScanState.empty;
          _scanFiles[k] = null;
        }
        _triageState = _TriageState.waiting;
        _patientId = 'VDR-00$_intakeCounter';
        _scenario = _emptyScenario;
      });

  Future<void> _pickAndUpload(String view) async {
    if (_scanStates[view] != _ScanState.empty) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _acceptedExtensions,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.bytes == null) return;

    setState(() {
      _scanStates[view] = _ScanState.loading;
      _scanFiles[view] = file;
    });

    Future.delayed(const Duration(milliseconds: 1300), () {
      if (!mounted) return;
      setState(() {
        _scanStates[view] = _ScanState.done;
        if (_allDone) _triageState = _TriageState.ready;
      });
    });
  }

  Future<void> _runTriage() async {
    final id = _patientId;
    final demographics = _ageCtrl.text.trim();
    final studyType = _studyType;
    setState(() => _triageState = _TriageState.running);

    try {
      final response = await _api.scoreCase(
        lCc: _scanFiles['L-CC'],
        lMlo: _scanFiles['L-MLO'],
        rCc: _scanFiles['R-CC'],
        rMlo: _scanFiles['R-MLO'],
      );
      if (!mounted) return;

      final scenario = _scenarioFromResponse(response);
      _intakeCounter++;
      setState(() {
        _scenario = scenario;
        _triageState = _TriageState.complete;
      });

      widget.onIntakeComplete?.call(TulipCase(
        id: id,
        demographics: demographics,
        finding: scenario.finding,
        confidence: scenario.confidence,
        status: scenario.status,
        waitTime: 'just now',
        studyType: studyType,
        impression: scenario.impression,
        ageYears: response.caseSummary.ageYears,
        probabilityMalignant: response.caseSummary.probabilityMalignant,
        viewResults: {for (final v in response.views) v.view: v},
        caseId: response.caseSummary.caseId,
        birads: response.caseSummary.birads,
        recommendation: response.caseSummary.recommendation
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _triageState = _TriageState.ready);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Triage failed: $e')),
      );
    }
  }

  _StepState _step(int i) {
    switch (i) {
      case 0:
        return _StepState.done;
      case 1:
        if (_triageState != _TriageState.waiting) return _StepState.done;
        return _StepState.active;
      case 2:
        if (_triageState == _TriageState.complete) return _StepState.done;
        if (_triageState == _TriageState.running ||
            _triageState == _TriageState.ready) return _StepState.active;
        return _StepState.future;
      case 3:
        return _triageState == _TriageState.complete
            ? _StepState.active
            : _StepState.future;
      default:
        return _StepState.future;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showResult = _triageState == _TriageState.complete;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        // ── Step bar ─────────────────────────────────────────────────────────
        TCard(
            child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Row(children: [
            _StepNode(n: '1', label: 'Patient info', state: _step(0)),
            _StepLine(done: _step(0) == _StepState.done),
            _StepNode(n: '2', label: 'Upload scans', state: _step(1)),
            _StepLine(done: _step(1) == _StepState.done),
            _StepNode(n: '3', label: 'Run triage', state: _step(2)),
            _StepLine(done: _step(2) == _StepState.done),
            _StepNode(n: '4', label: 'Route case', state: _step(3)),
          ]),
        )),
        const SizedBox(height: 16),
        // ── Patient details (full width) ─────────────────────────────────────
        TCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(children: [
            Expanded(child: _FormField(label: 'Patient ID', value: _patientId)),
            const SizedBox(width: 12),
            Expanded(
                child:
                    _EditableField(label: 'Age / Sex', controller: _ageCtrl)),
            const SizedBox(width: 12),
            Expanded(
                child: _DropdownField(
              label: 'Study type',
              value: _studyType,
              items: const [
                'Bilateral screening',
                'Diagnostic',
                'Unilateral screening',
                'Follow-up',
                'Problem solving',
              ],
              onChanged: (v) => setState(() => _studyType = v),
            )),
            const SizedBox(width: 12),
            Expanded(
                child: _DropdownField(
              label: 'Family history',
              value: _familyHistory,
              items: const [
                'None',
                'Yes — 1st degree',
                'Yes — 2nd degree',
                'Yes — multiple relatives',
                'Unknown',
              ],
              onChanged: (v) => setState(() => _familyHistory = v),
            )),
          ]),
        ),
        const SizedBox(height: 16),
        // ── Main content row ──────────────────────────────────────────────────
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Scan upload 2×2 grid
          Expanded(
              flex: 7,
              child: TCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text('MAMMOGRAM VIEWS',
                            style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: TulipColors.textT,
                                letterSpacing: 0.6)),
                        const Spacer(),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text('$_uploaded / 4 uploaded',
                              key: ValueKey(_uploaded),
                              style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: _allDone
                                      ? TulipColors.green400
                                      : TulipColors.textS)),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      // Row 1 — L-CC | L-MLO
                      Row(children: [
                        Expanded(
                            child: _ScanTile(
                                view: 'L-CC',
                                state: _scanStates['L-CC']!,
                                mock: _scenario.views['L-CC']!,
                                imageBytes: _previewBytes('L-CC'),
                                showResult: showResult,
                                onTap: () => _pickAndUpload('L-CC'))),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _ScanTile(
                                view: 'L-MLO',
                                state: _scanStates['L-MLO']!,
                                mock: _scenario.views['L-MLO']!,
                                imageBytes: _previewBytes('L-MLO'),
                                showResult: showResult,
                                onTap: () => _pickAndUpload('L-MLO'))),
                      ]),
                      const SizedBox(height: 10),
                      // Row 2 — R-CC | R-MLO
                      Row(children: [
                        Expanded(
                            child: _ScanTile(
                                view: 'R-CC',
                                state: _scanStates['R-CC']!,
                                mock: _scenario.views['R-CC']!,
                                imageBytes: _previewBytes('R-CC'),
                                showResult: showResult,
                                onTap: () => _pickAndUpload('R-CC'))),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _ScanTile(
                                view: 'R-MLO',
                                state: _scanStates['R-MLO']!,
                                mock: _scenario.views['R-MLO']!,
                                imageBytes: _previewBytes('R-MLO'),
                                showResult: showResult,
                                onTap: () => _pickAndUpload('R-MLO'))),
                      ]),
                      // Result banner
                      if (showResult) ...[
                        const SizedBox(height: 16),
                        _TriageResultBanner(scenario: _scenario),
                      ],
                    ],
                  ))),
          const SizedBox(width: 16),
          // Routing logic + dynamic status card
          Expanded(
              flex: 5,
              child: Column(children: [
                TCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Routing logic',
                            style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: TulipColors.text)),
                        const SizedBox(height: 12),
                        _RoutingCard(
                            title: 'Confidence > 85% — Auto-clear',
                            body:
                                'Pre-read report sent to radiologist for sign-off.',
                            color: TulipColors.green50,
                            textColor: TulipColors.green800),
                        const SizedBox(height: 8),
                        _RoutingCard(
                            title: 'Confidence 60–85% — Needs review',
                            body:
                                'Routed to worklist, sorted by urgency score.',
                            color: TulipColors.amber50,
                            textColor: TulipColors.amber800),
                        const SizedBox(height: 8),
                        _RoutingCard(
                            title: 'Confidence < 60% — High priority',
                            body:
                                'Pushed to urgent queue with immediate notification.',
                            color: TulipColors.red50,
                            textColor: TulipColors.red800),
                      ],
                    )),
                const SizedBox(height: 16),
                _StatusCard(
                  scanStates: Map.unmodifiable(_scanStates),
                  triageState: _triageState,
                  uploaded: _uploaded,
                  onRunTriage: _runTriage,
                  onViewInWorklist: widget.onViewInWorklist,
                  onNewIntake: _reset,
                  scenario: _scenario,
                ),
              ])),
        ]),
      ]),
    );
  }
}

// ── SCAN TILE ─────────────────────────────────────────────────────────────────
class _ScanTile extends StatelessWidget {
  final String view;
  final _ScanState state;
  final _ViewMock mock;
  final Uint8List? imageBytes;
  final bool showResult;
  final VoidCallback onTap;
  const _ScanTile({
    required this.view,
    required this.state,
    required this.mock,
    required this.showResult,
    required this.onTap,
    this.imageBytes,
  });

  Color get _accent => mock.urgent
      ? TulipColors.red400
      : mock.conf < 0.75
          ? TulipColors.amber400
          : TulipColors.green400;

  @override
  Widget build(BuildContext context) {
    final borderColor = showResult && state == _ScanState.done
        ? _accent.withValues(alpha: 0.75)
        : state == _ScanState.loading
            ? TulipColors.p400.withValues(alpha: 0.5)
            : state == _ScanState.done
                ? Colors.white24
                : Colors.white12;

    return GestureDetector(
      onTap: state == _ScanState.empty ? onTap : null,
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: showResult && state == _ScanState.done ? 1.5 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Stack(fit: StackFit.expand, children: [
              // Background: real image or faux gradient
              if (state != _ScanState.empty)
                imageBytes != null
                    ? Image.memory(imageBytes!, fit: BoxFit.cover)
                    : Container(
                        decoration: const BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(-0.15, -0.2),
                            radius: 0.9,
                            colors: [Color(0xFF3A3A3A), Color(0xFF0A0A0A)],
                          ),
                        ),
                      ),
              // Content layer
              if (state == _ScanState.empty)
                _EmptyContent(view: view)
              else if (state == _ScanState.loading)
                const _LoadingContent()
              else
                _DoneContent(
                  view: view,
                  mock: mock,
                  showResult: showResult,
                  accent: _accent,
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _EmptyContent extends StatelessWidget {
  final String view;
  const _EmptyContent({required this.view});
  @override
  Widget build(BuildContext context) => Center(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: Colors.white12, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.add_photo_alternate_outlined,
                size: 20, color: Colors.white38),
          ),
          const SizedBox(height: 8),
          Text(view,
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70)),
          const SizedBox(height: 3),
          Text('Click to upload',
              style: GoogleFonts.dmSans(fontSize: 10, color: Colors.white30)),
        ],
      ));
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent();
  @override
  Widget build(BuildContext context) => Center(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: TulipColors.p400),
          ),
          const SizedBox(height: 10),
          Text('Processing…',
              style: GoogleFonts.dmSans(fontSize: 10, color: Colors.white38)),
        ],
      ));
}

class _DoneContent extends StatelessWidget {
  final String view;
  final _ViewMock mock;
  final bool showResult;
  final Color accent;
  const _DoneContent({
    required this.view,
    required this.mock,
    required this.showResult,
    required this.accent,
  });
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        // Checkmark
        Positioned(
          top: 7,
          right: 7,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
                color: Colors.black38, shape: BoxShape.circle),
            child: const Icon(Icons.check, size: 12, color: Colors.white60),
          ),
        ),
        // View label
        Positioned(
          bottom: showResult ? 44 : 7,
          left: 7,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
                color: Colors.black54, borderRadius: BorderRadius.circular(4)),
            child: Text(view,
                style: GoogleFonts.dmSans(fontSize: 10, color: Colors.white60)),
          ),
        ),
        // Result overlay
        if (showResult)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 18, 8, 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.88),
                    Colors.transparent
                  ],
                ),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mock.label,
                        style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: accent)),
                    Text('${(mock.conf * 100).toInt()}% conf.',
                        style: GoogleFonts.dmMono(
                            fontSize: 9, color: Colors.white54)),
                  ]),
            ),
          ),
      ]);
}

// ── STATUS CARD ───────────────────────────────────────────────────────────────
class _StatusCard extends StatelessWidget {
  final Map<String, _ScanState> scanStates;
  final _TriageState triageState;
  final int uploaded;
  final VoidCallback onRunTriage;
  final VoidCallback? onViewInWorklist;
  final VoidCallback? onNewIntake;
  final _DemoScenario scenario;
  const _StatusCard({
    required this.scanStates,
    required this.triageState,
    required this.uploaded,
    required this.onRunTriage,
    required this.scenario,
    this.onViewInWorklist,
    this.onNewIntake,
  });

  @override
  Widget build(BuildContext context) {
    if (triageState == _TriageState.complete)
      return _TriageCompleteCard(
          scenario: scenario,
          onViewInWorklist: onViewInWorklist,
          onNewIntake: onNewIntake);

    final isReady = uploaded == 4;
    final isRunning = triageState == _TriageState.running;
    final remaining = 4 - uploaded;

    return TCard(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Status ring
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color:
                        isReady ? TulipColors.green400 : TulipColors.amber400,
                    width: 3)),
            child: Center(
                child: Text(
              isReady ? '✓' : '$uploaded/4',
              style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isReady ? TulipColors.green400 : TulipColors.amber400),
            )),
          ),
          const SizedBox(height: 12),
          Text(
            isReady
                ? 'Ready to analyse'
                : '$remaining view${remaining > 1 ? 's' : ''} remaining',
            style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: TulipColors.text),
          ),
          const SizedBox(height: 4),
          Text(
            isReady ? 'All 4 views loaded' : '$uploaded of 4 views uploaded',
            style: GoogleFonts.dmSans(fontSize: 12, color: TulipColors.textS),
          ),
          const SizedBox(height: 16),
          // Per-view status rows
          ...['L-CC', 'L-MLO', 'R-CC', 'R-MLO'].map((v) {
            final s = scanStates[v]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: s == _ScanState.done
                        ? TulipColors.green50
                        : s == _ScanState.loading
                            ? TulipColors.p50
                            : TulipColors.gray50,
                    border: Border.all(
                      color: s == _ScanState.done
                          ? TulipColors.green400
                          : s == _ScanState.loading
                              ? TulipColors.p400
                              : TulipColors.gray100,
                      width: 1.5,
                    ),
                  ),
                  child: s == _ScanState.done
                      ? const Icon(Icons.check,
                          size: 10, color: TulipColors.green800)
                      : s == _ScanState.loading
                          ? const Padding(
                              padding: EdgeInsets.all(3),
                              child: CircularProgressIndicator(
                                  strokeWidth: 1.5, color: TulipColors.p400),
                            )
                          : null,
                ),
                const SizedBox(width: 8),
                Text(v,
                    style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: s == _ScanState.done
                            ? FontWeight.w500
                            : FontWeight.w400,
                        color: s == _ScanState.done
                            ? TulipColors.text
                            : TulipColors.textT)),
                const Spacer(),
                Text(
                  s == _ScanState.done
                      ? 'Ready'
                      : s == _ScanState.loading
                          ? 'Uploading…'
                          : 'Pending',
                  style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: s == _ScanState.done
                          ? TulipColors.green400
                          : s == _ScanState.loading
                              ? TulipColors.p400
                              : TulipColors.textT),
                ),
              ]),
            );
          }),
          const SizedBox(height: 8),
          // Action button
          SizedBox(
            width: double.infinity,
            child: isRunning
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: TulipColors.p50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: TulipColors.p200, width: 0.5),
                    ),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: TulipColors.p600),
                          ),
                          const SizedBox(width: 8),
                          Text('Running AI triage…',
                              style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: TulipColors.p600,
                                  fontWeight: FontWeight.w500)),
                        ]),
                  )
                : TBtn('Run triage →',
                    primary: isReady, onTap: isReady ? onRunTriage : null),
          ),
        ]));
  }
}

// ── TRIAGE COMPLETE CARD ──────────────────────────────────────────────────────
class _TriageCompleteCard extends StatelessWidget {
  final _DemoScenario scenario;
  final VoidCallback? onViewInWorklist;
  final VoidCallback? onNewIntake;
  const _TriageCompleteCard(
      {required this.scenario, this.onViewInWorklist, this.onNewIntake});

  Color get _accent => switch (scenario.status) {
        CaseStatus.urgent => TulipColors.red400,
        CaseStatus.review => TulipColors.amber400,
        CaseStatus.cleared => TulipColors.green400,
        CaseStatus.pending => TulipColors.gray400,
      };
  Color get _bg => switch (scenario.status) {
        CaseStatus.urgent => TulipColors.red50,
        CaseStatus.review => TulipColors.amber50,
        CaseStatus.cleared => TulipColors.green50,
        CaseStatus.pending => TulipColors.gray50,
      };
  Color get _text => switch (scenario.status) {
        CaseStatus.urgent => TulipColors.red800,
        CaseStatus.review => TulipColors.amber800,
        CaseStatus.cleared => TulipColors.green800,
        CaseStatus.pending => TulipColors.text,
      };
  IconData get _icon => switch (scenario.status) {
        CaseStatus.urgent => Icons.priority_high_rounded,
        CaseStatus.review => Icons.remove_red_eye_outlined,
        CaseStatus.cleared => Icons.check_circle_outline_rounded,
        CaseStatus.pending => Icons.schedule_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final findings = scenario.views.entries
        .where((e) => e.value.label != 'No finding')
        .toList();
    final clearCount = scenario.views.entries
        .where((e) => e.value.label == 'No finding')
        .length;

    return TCard(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _bg,
                border: Border.all(color: _accent, width: 3)),
            child: Icon(_icon, size: 22, color: _accent),
          ),
          const SizedBox(height: 12),
          Text(scenario.resultTitle,
              style: GoogleFonts.dmSans(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _text)),
          const SizedBox(height: 4),
          Text(scenario.resultSub,
              style:
                  GoogleFonts.dmSans(fontSize: 12, color: TulipColors.textS)),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: _accent.withValues(alpha: 0.35), width: 0.5)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ...findings.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(children: [
                      Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                              color: _accent, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text('${e.key} — ${e.value.label}',
                              style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _text))),
                      Text('${(e.value.conf * 100).toInt()}%',
                          style:
                              GoogleFonts.dmMono(fontSize: 11, color: _accent)),
                    ]),
                  )),
              if (clearCount > 0)
                Padding(
                  padding: EdgeInsets.only(
                      left: findings.isEmpty ? 0 : 15,
                      top: findings.isEmpty ? 0 : 2),
                  child: Text(
                      clearCount == 4
                          ? 'All 4 views — no significant finding'
                          : '$clearCount view${clearCount > 1 ? 's' : ''} — no significant finding',
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: _accent.withValues(alpha: 0.8))),
                ),
            ]),
          ),
          const SizedBox(height: 14),
          SizedBox(
              width: double.infinity,
              child: TBtn('View in worklist →',
                  primary: true, onTap: onViewInWorklist)),
          const SizedBox(height: 8),
          SizedBox(
              width: double.infinity,
              child: TBtn('+ New intake', onTap: onNewIntake)),
        ]));
  }
}

// ── TRIAGE RESULT BANNER ──────────────────────────────────────────────────────
class _TriageResultBanner extends StatelessWidget {
  final _DemoScenario scenario;
  const _TriageResultBanner({required this.scenario});

  Color get _bg => switch (scenario.status) {
        CaseStatus.urgent => TulipColors.red50,
        CaseStatus.review => TulipColors.amber50,
        CaseStatus.cleared => TulipColors.green50,
        CaseStatus.pending => TulipColors.gray50,
      };
  Color get _fg => switch (scenario.status) {
        CaseStatus.urgent => TulipColors.red400,
        CaseStatus.review => TulipColors.amber400,
        CaseStatus.cleared => TulipColors.green400,
        CaseStatus.pending => TulipColors.gray400,
      };
  Color get _text => switch (scenario.status) {
        CaseStatus.urgent => TulipColors.red800,
        CaseStatus.review => TulipColors.amber800,
        CaseStatus.cleared => TulipColors.green800,
        CaseStatus.pending => TulipColors.text,
      };
  IconData get _icon => switch (scenario.status) {
        CaseStatus.urgent => Icons.warning_amber_rounded,
        CaseStatus.review => Icons.info_outline_rounded,
        CaseStatus.cleared => Icons.check_circle_outline_rounded,
        CaseStatus.pending => Icons.schedule_rounded,
      };

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _fg.withValues(alpha: 0.35), width: 0.5)),
        child: Row(children: [
          Icon(_icon, size: 16, color: _fg),
          const SizedBox(width: 8),
          Expanded(
              child: Text(scenario.bannerText,
                  style: GoogleFonts.dmSans(fontSize: 12, color: _text))),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: _fg, borderRadius: BorderRadius.circular(12)),
            child: Text(scenario.bannerBadge,
                style: GoogleFonts.dmMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ),
        ]),
      );
}

// ── STEP WIDGETS ──────────────────────────────────────────────────────────────
class _StepNode extends StatelessWidget {
  final String n;
  final String label;
  final _StepState state;
  const _StepNode({required this.n, required this.label, required this.state});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color labelColor;
    switch (state) {
      case _StepState.done:
        bg = TulipColors.p400;
        fg = Colors.white;
        labelColor = TulipColors.p400;
        break;
      case _StepState.active:
        bg = Colors.white;
        fg = TulipColors.p600;
        labelColor = TulipColors.p600;
        break;
      case _StepState.future:
        bg = TulipColors.gray50;
        fg = TulipColors.textT;
        labelColor = TulipColors.textT;
        break;
    }
    final display = state == _StepState.done ? '✓' : n;
    return Column(children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: state == _StepState.active
                ? Border.all(color: TulipColors.p400, width: 2)
                : null),
        child: Center(
            child: Text(display,
                style: GoogleFonts.dmSans(
                    fontSize: 11, fontWeight: FontWeight.w600, color: fg))),
      ),
      const SizedBox(height: 5),
      Text(label,
          style: GoogleFonts.dmSans(
              fontSize: 11, fontWeight: FontWeight.w500, color: labelColor)),
    ]);
  }
}

class _StepLine extends StatelessWidget {
  final bool done;
  const _StepLine({required this.done});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          height: 1.5,
          margin: const EdgeInsets.only(bottom: 22),
          color: done ? TulipColors.p400 : TulipColors.gray100,
        ),
      );
}

// ── FORM FIELD ────────────────────────────────────────────────────────────────
class _FormField extends StatelessWidget {
  final String label;
  final String value;
  const _FormField({required this.label, required this.value});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(),
            style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: TulipColors.textS,
                letterSpacing: 0.6)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
              color: TulipColors.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: TulipColors.borderMid, width: 0.5)),
          child: Text(value,
              style: GoogleFonts.dmSans(fontSize: 13, color: TulipColors.text)),
        ),
      ]);
}

// ── EDITABLE FIELD ────────────────────────────────────────────────────────────
class _EditableField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _EditableField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: TulipColors.textS,
                  letterSpacing: 0.6)),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            style: GoogleFonts.dmSans(fontSize: 13, color: TulipColors.text),
            decoration: InputDecoration(
              filled: true,
              fillColor: TulipColors.bg,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                      color: TulipColors.borderMid, width: 0.5)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: TulipColors.p400, width: 1)),
            ),
          ),
        ],
      );
}

// ── DROPDOWN FIELD ────────────────────────────────────────────────────────────
class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: TulipColors.textS,
                  letterSpacing: 0.6)),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
                color: TulipColors.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: TulipColors.borderMid, width: 0.5)),
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down,
                  size: 16, color: TulipColors.textS),
              style: GoogleFonts.dmSans(fontSize: 13, color: TulipColors.text),
              dropdownColor: TulipColors.surface,
              items: items
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s,
                            style: GoogleFonts.dmSans(
                                fontSize: 13, color: TulipColors.text)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ],
      );
}

// ── ROUTING CARD ──────────────────────────────────────────────────────────────
class _RoutingCard extends StatelessWidget {
  final String title, body;
  final Color color, textColor;
  const _RoutingCard({
    required this.title,
    required this.body,
    required this.color,
    required this.textColor,
  });
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: GoogleFonts.dmSans(
                  fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 3),
          Text(body, style: GoogleFonts.dmSans(fontSize: 12, color: textColor)),
        ]),
      );
}
