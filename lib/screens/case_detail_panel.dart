import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tulip_case.dart';
import '../models/case_score_response.dart';
import '../services/case_mapper.dart';
import '../services/tulip_api_service.dart';
import '../theme/colors.dart';
import '../widgets/tulip_badge.dart';
import '../widgets/t_card.dart';

class CaseDetailPanel extends StatefulWidget {
  final TulipCase tulipCase;
  final VoidCallback onClose;
  final bool isFullScreen;
  /// Called when the radiologist confirms sign-off.
  /// Passes the selected BI-RADS, recommendation text, and impression notes.
  final void Function(int birads, String recommendation, String notes)? onSignOff;
  const CaseDetailPanel({
    required this.tulipCase,
    required this.onClose,
    this.isFullScreen = false,
    this.onSignOff,
    super.key,
  });

  @override
  State<CaseDetailPanel> createState() => _CaseDetailPanelState();
}

class _CaseDetailPanelState extends State<CaseDetailPanel> {
  bool _gradcamOn = true;
  final _api = const TulipApiService();

  ViewResult? _view(String view) => widget.tulipCase.viewResults?[view];
  
  late int _selectedBirads;
  late int _selectedRec;
  bool _signingOff = false;
  late final TextEditingController _impressionCtrl =
      TextEditingController(text: widget.tulipCase.impression ?? '');

  int get _sIdx => widget.tulipCase.scenarioIndex ?? 0;

  Color get _accentColor => switch (_sIdx) {
    1 => TulipColors.p400,
    2 => TulipColors.amber400,
    _ => TulipColors.red400,
  };
  Color get _accentBg => switch (_sIdx) {
    1 => TulipColors.p50,
    2 => TulipColors.amber50,
    _ => TulipColors.red50,
  };
  Color get _accentText => switch (_sIdx) {
    1 => TulipColors.p800,
    2 => TulipColors.amber800,
    _ => TulipColors.red800,
  };

  @override
  void initState() {
    super.initState();
    _selectedBirads = widget.tulipCase.birads
        ?? switch (_sIdx) { 1 => 1, 2 => 3, _ => 4 };
    final rec = widget.tulipCase.recommendation;
    _selectedRec = rec != null
        ? recommendationIndex(rec)
        : switch (_sIdx) { 1 => 0, 2 => 3, _ => 2 };
  }

  @override
  void dispose() { _impressionCtrl.dispose(); super.dispose(); }

    String _extractAge() {
    final ageYears = widget.tulipCase.ageYears;
    if (ageYears != null) return 'Age ${ageYears.floor()}';
    final m = RegExp(r'\d+').firstMatch(widget.tulipCase.demographics);
    return m != null ? 'Age ${m.group(0)}' : widget.tulipCase.demographics;
  }

  Widget _buildFindingHeader() {
    final probability = widget.tulipCase.probabilityMalignant ?? widget.tulipCase.confidence;
    final confPct = '${(probability * 100).round()}%';
    final (title, sub) = switch (_sIdx) {
      1 => ('No significant finding', 'Bilateral · all 4 views'),
      2 => ('Focal asymmetry', 'R breast · right CC view'),
      _ => ('Suspicious mass', 'L breast · upper outer quadrant'),
    };
    return Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _accentColor, width: 3)),
        child: Center(child: Text(confPct, style: GoogleFonts.dmMono(
            fontSize: 10, fontWeight: FontWeight.w600, color: _accentColor))),
      ),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.dmSans(
            fontSize: 12, fontWeight: FontWeight.w600, color: _accentText)),
        Text(sub, style: GoogleFonts.dmSans(fontSize: 10, color: _accentColor)),
      ]),
    ]);
  }

    List<Widget> _buildFindingRows() {
    final vr = widget.tulipCase.viewResults;
    if (vr == null) return _buildMockFindingRows(); // demo cases w/o real data
    return _buildRealFindingRows(vr);
  }

  // ── Original hardcoded demo rows, kept for mock cases only ──────────────
  List<Widget> _buildMockFindingRows() => switch (_sIdx) {
    1 => [
      _FindingRow(color: TulipColors.p400,
        name: 'L-CC, L-MLO — no finding',
        desc: 'Normal breast tissue · bilateral', score: '0.95'),
      _FindingRow(color: TulipColors.p400,
        name: 'R-CC, R-MLO — no finding',
        desc: 'Normal breast tissue · bilateral', score: '0.97'),
    ],
    2 => [
      _FindingRow(color: TulipColors.amber400,
        name: 'R-CC — focal asymmetry',
        desc: 'Requires spot compression views', score: '0.63'),
      _FindingRow(color: TulipColors.amber400,
        name: 'R-MLO — asymmetric density',
        desc: 'Cannot exclude architectural distortion', score: '0.58'),
      _FindingRow(color: TulipColors.gray400,
        name: 'L-CC, L-MLO — no finding',
        desc: 'Normal breast tissue', score: '0.90'),
    ],
    _ => [
      _FindingRow(color: TulipColors.red400,
        name: 'L-CC — irregular spiculated mass',
        desc: 'Estimated 14mm · upper outer quadrant', score: '0.88'),
      _FindingRow(color: TulipColors.amber400,
        name: 'L-MLO — corroborating density',
        desc: 'Overlapping tissue · moderate confidence', score: '0.61'),
      _FindingRow(color: TulipColors.gray400,
        name: 'R-CC, R-MLO — no finding',
        desc: 'No significant findings', score: '0.04'),
    ],
  };

  // ── Real rows, built from the backend's per-view findings ───────────────
  FindingResult? _topValidated(List<FindingResult> findings) {
    final validated = findings.where((f) => f.validated).toList()
      ..sort((a, b) => b.probability.compareTo(a.probability));
    return validated.isEmpty ? null : validated.first;
  }

    Widget _noFindingRow(String views, double clearConfidence, String density) => _FindingRow(
    color: TulipColors.gray400,
    name: '$views — no finding',
    desc: 'No significant findings',
    score: clearConfidence.toStringAsFixed(2),
    density: density,
  );

  Widget _findingRow(String view, FindingResult f, String density) => _FindingRow(
    color: f.probability >= 0.75 ? TulipColors.red400 : TulipColors.amber400,
    name: '$view — ${f.name}',
    desc: f.validated ? 'Validated finding' : 'Exploratory — low sample size',
    score: f.probability.toStringAsFixed(2),
    density: density,
  );

  List<Widget> _buildRealFindingRows(Map<String, ViewResult> vr) {
    final rows = <Widget>[];
    for (final side in ['L', 'R']) {
      final ccView  = '$side-CC';
      final mloView = '$side-MLO';
      final cc  = vr[ccView];
      final mlo = vr[mloView];
      final ccFinding  = cc  != null ? _topValidated(cc.findings)  : null;
      final mloFinding = mlo != null ? _topValidated(mlo.findings) : null;
      final density = cc?.densityLetter ?? mlo?.densityLetter ?? '—';

      if (ccFinding == null && mloFinding == null) {
        final clears = [
          if (cc  != null) 1 - cc.diagnosisProbability,
          if (mlo != null) 1 - mlo.diagnosisProbability,
        ];
        final avg = clears.isEmpty ? 0.0 : clears.reduce((a, b) => a + b) / clears.length;
        rows.add(_noFindingRow('$ccView, $mloView', avg, density));
      } else {
        rows.add(ccFinding != null
            ? _findingRow(ccView, ccFinding, density)
            : _noFindingRow(ccView, cc != null ? 1 - cc.diagnosisProbability : 0, density));
        rows.add(mloFinding != null
            ? _findingRow(mloView, mloFinding, density)
            : _noFindingRow(mloView, mlo != null ? 1 - mlo.diagnosisProbability : 0, density));
      }
    }
    return rows;
  }

  Widget _buildUrgencyDrivers() {
    final age = _extractAge();
    final drivers = switch (_sIdx) {
      1 => <(String, CaseStatus)>[],
      2 => [
        (age, CaseStatus.pending),
        ('Family hx (1st degree)', CaseStatus.review),
        ('Asymmetric density R-CC', CaseStatus.review),
      ],
      _ => [
        (age, CaseStatus.urgent),
        ('Family hx (1st degree)', CaseStatus.urgent),
        ('Spiculated morphology', CaseStatus.review),
        ('No prior comparison', CaseStatus.pending),
      ],
    };
    if (drivers.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('URGENCY DRIVERS', style: GoogleFonts.dmSans(
            fontSize: 10, fontWeight: FontWeight.w600,
            color: TulipColors.textT, letterSpacing: 0.6)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final (label, status) in drivers)
            TulipBadge(label, status: status),
        ]),
      ]),
    );
  }

  final _recs = [
    'Routine follow-up (1 yr)',
    'Short-interval follow-up (6 mo)',
    'Tissue biopsy recommended',
    'Additional imaging needed',
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TulipColors.bg,
      child: Column(children: [
        // Panel top bar
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
            color: TulipColors.surface,
            border: Border(bottom: BorderSide(color: TulipColors.border, width: 0.5))),
          child: Row(children: [
            GestureDetector(
              onTap: widget.isFullScreen ? () => Navigator.pop(context) : widget.onClose,
              child: Container(
                width: 32, height: 32,
                decoration: const BoxDecoration(color: TulipColors.gray50, shape: BoxShape.circle),
                child: Icon(
                  widget.isFullScreen ? Icons.close_fullscreen : Icons.close,
                  size: 16, color: TulipColors.text),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Case ${widget.tulipCase.id}', style: GoogleFonts.dmSans(
                    fontSize: 15, fontWeight: FontWeight.w600, color: TulipColors.text)),
                Text('${widget.tulipCase.demographics} · ${widget.tulipCase.studyType}',
                  style: GoogleFonts.dmSans(fontSize: 11, color: TulipColors.textS)),
              ],
            ),
            const Spacer(),
            if (!widget.isFullScreen)
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => Scaffold(
                      body: CaseDetailPanel(
                        tulipCase: widget.tulipCase,
                        onClose: widget.onClose,
                        isFullScreen: true,
                      ),
                    ),
                    transitionsBuilder: (_, anim, __, child) => FadeTransition(
                      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
                      child: child,
                    ),
                    transitionDuration: const Duration(milliseconds: 220),
                  ),
                ),
                child: Container(
                  width: 32, height: 32,
                  decoration: const BoxDecoration(color: TulipColors.gray50, shape: BoxShape.circle),
                  child: const Icon(Icons.open_in_full, size: 15, color: TulipColors.text),
                ),
              ),
            if (!widget.isFullScreen) const SizedBox(width: 12),
            TulipBadge(statusLabel(widget.tulipCase.status), status: widget.tulipCase.status),
            const SizedBox(width: 12),
            TBtn('Flag for 2nd opinion', onTap: () {}),
          ]),
        ),
        // Panel body
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            // Scan viewer
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                Row(children: [
                  Text('Scan viewer · 4 views', style: GoogleFonts.dmSans(
                      fontSize: 12, color: Colors.white54, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  _GradcamToggle(
                    on: _gradcamOn,
                    onToggle: (v) => setState(() => _gradcamOn = v),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  // L breast
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('L BREAST', style: GoogleFonts.dmSans(
                        fontSize: 9, fontWeight: FontWeight.w600,
                        color: Colors.white30, letterSpacing: 0.8)),
                    const SizedBox(height: 6),
                                        Row(children: [
                      Expanded(child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: _ScanTile(label: 'L-CC', assetPath: 'assets/scans/L-CC.jpeg',
                          imageUrl: _view('L-CC') != null ? _api.imageUrl(_view('L-CC')!.imageUrl) : null,
                          overlayUrl: _view('L-CC') != null ? _api.imageUrl(_view('L-CC')!.overlayUrl) : null,
                          showOverlay: _gradcamOn,
                          showHotspot: _gradcamOn && _sIdx == 0, hotspotHigh: true),
                      )),
                      Expanded(child: _ScanTile(label: 'L-MLO', assetPath: 'assets/scans/L-MLO.jpeg',
                        imageUrl: _view('L-MLO') != null ? _api.imageUrl(_view('L-MLO')!.imageUrl) : null,
                        overlayUrl: _view('L-MLO') != null ? _api.imageUrl(_view('L-MLO')!.overlayUrl) : null,
                        showOverlay: _gradcamOn,
                        showHotspot: _gradcamOn && _sIdx == 0, hotspotHigh: false)),
                    ]),
                  ])),
                  Container(width: 1, margin: const EdgeInsets.symmetric(horizontal: 10),
                    color: Colors.white12),
                  // R breast
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('R BREAST', style: GoogleFonts.dmSans(
                        fontSize: 9, fontWeight: FontWeight.w600,
                        color: Colors.white30, letterSpacing: 0.8)),
                    const SizedBox(height: 6),
                                        Row(children: [
                      Expanded(child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: _ScanTile(label: 'R-CC', assetPath: 'assets/scans/R-CC.jpeg',
                          imageUrl: _view('R-CC') != null ? _api.imageUrl(_view('R-CC')!.imageUrl) : null,
                          overlayUrl: _view('R-CC') != null ? _api.imageUrl(_view('R-CC')!.overlayUrl) : null,
                          showOverlay: _gradcamOn,
                          showHotspot: _gradcamOn && _sIdx == 2, hotspotHigh: false),
                      )),
                      Expanded(child: _ScanTile(label: 'R-MLO', assetPath: 'assets/scans/R-MLO.jpeg',
                        imageUrl: _view('R-MLO') != null ? _api.imageUrl(_view('R-MLO')!.imageUrl) : null,
                        overlayUrl: _view('R-MLO') != null ? _api.imageUrl(_view('R-MLO')!.overlayUrl) : null,
                        showOverlay: _gradcamOn,
                        showHotspot: _gradcamOn && _sIdx == 2, hotspotHigh: false)),
                    ]),
                  ])),
                ]),
                const SizedBox(height: 8),
                                Text(
                  widget.tulipCase.viewResults != null
                      ? 'GradCAM heatmap — shows where the model attended, not a confirmed lesion location'
                      : 'Red rings = high activation · Amber rings = corroborating signal',
                  style: GoogleFonts.dmSans(fontSize: 10, color: Colors.white30)),
              ]),
            ),
            const SizedBox(height: 14),
            // Two column: findings + assessment
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Findings
              Expanded(child: TCard(child: Column(children: [
                CardHeader('Model findings', trailing: _buildFindingHeader()),
                ..._buildFindingRows(),
                _buildUrgencyDrivers(),
              ]))),
              const SizedBox(width: 14),
              // Assessment
              Expanded(child: Column(children: [
                // BI-RADS
                TCard(child: Column(children: [
                  const CardHeader('BI-RADS category'),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: List.generate(5, (i) {
                      final n = i + 1;
                      final sel = _selectedBirads == n;
                      return Expanded(child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedBirads = n),
                          child: AspectRatio(aspectRatio: 1, child: AnimatedContainer(
                            duration: const Duration(milliseconds: 130),
                            decoration: BoxDecoration(
                              color: sel ? _accentBg : TulipColors.bg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: sel ? _accentColor : TulipColors.borderMid,
                                width: 0.5)),
                            child: Center(child: Text('$n',
                              style: GoogleFonts.dmSans(fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: sel ? _accentText : TulipColors.textS))),
                          )),
                        ),
                      ));
                    })),
                  ),
                ])),
                const SizedBox(height: 12),
                // Recommendation
                TCard(child: Column(children: [
                  const CardHeader('Recommendation'),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(children: _recs.asMap().entries.map((e) {
                      final sel = _selectedRec == e.key;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedRec = e.key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 130),
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: sel ? TulipColors.p50 : TulipColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: sel ? TulipColors.p400 : TulipColors.border,
                              width: 0.5)),
                          child: Row(children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 130),
                              width: 16, height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: sel ? TulipColors.p400 : Colors.transparent,
                                border: Border.all(
                                  color: sel ? TulipColors.p400 : TulipColors.gray100,
                                  width: 2)),
                              child: sel
                                ? const Icon(Icons.check, size: 10, color: Colors.white)
                                : null,
                            ),
                            const SizedBox(width: 10),
                            Text(e.value, style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: sel ? TulipColors.p800 : TulipColors.text,
                              fontWeight: sel ? FontWeight.w500 : FontWeight.w400)),
                          ]),
                        ),
                      );
                    }).toList()),
                  ),
                ])),
                const SizedBox(height: 12),
                // Impression notes
                TCard(child: Column(children: [
                  const CardHeader('Impression / notes'),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _impressionCtrl,
                      maxLines: 3,
                      style: GoogleFonts.dmSans(fontSize: 13, color: TulipColors.text),
                      decoration: InputDecoration(
                        hintText: 'Add clinical notes, override findings, or flag discrepancies…',
                        hintStyle: GoogleFonts.dmSans(fontSize: 12, color: TulipColors.textT),
                        filled: true, fillColor: TulipColors.bg,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: TulipColors.borderMid, width: 0.5)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: TulipColors.p400, width: 1)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: TulipColors.borderMid, width: 0.5)),
                      ),
                    ),
                  ),
                ])),
              ])),
            ]),
          ]),
        )),
        // Panel footer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(
            color: TulipColors.surface,
            border: Border(top: BorderSide(color: TulipColors.border, width: 0.5))),
          child: Row(children: [
            TBtn('Request peer review'),
            const Spacer(),
            TBtn('Cancel', onTap: widget.isFullScreen ? () => Navigator.pop(context) : widget.onClose),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() => _signingOff = true);
                widget.onSignOff?.call(
                  _selectedBirads,
                  _recs[_selectedRec],
                  _impressionCtrl.text,
                );
                Future.delayed(const Duration(milliseconds: 800), () {
                  if (widget.isFullScreen && context.mounted) Navigator.pop(context);
                  widget.onClose();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                decoration: BoxDecoration(
                  color: _signingOff ? TulipColors.p800 : TulipColors.p600,
                  borderRadius: BorderRadius.circular(8)),
                child: Text(_signingOff ? 'Signed off ✓' : 'Confirm & sign off',
                  style: GoogleFonts.dmSans(fontSize: 14,
                      fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _GradcamToggle extends StatelessWidget {
  final bool on;
  final ValueChanged<bool> onToggle;
  const _GradcamToggle({required this.on, required this.onToggle});

  @override
  Widget build(BuildContext context) => Row(children: [
    GestureDetector(
      onTap: () => onToggle(true),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: on ? TulipColors.p400 : const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(20)),
        child: Text('GradCAM on', style: GoogleFonts.dmSans(
            fontSize: 11, fontWeight: FontWeight.w500,
            color: on ? Colors.white : Colors.white54)),
      ),
    ),
    const SizedBox(width: 4),
    GestureDetector(
      onTap: () => onToggle(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: !on ? TulipColors.p400 : const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(20)),
        child: Text('Raw', style: GoogleFonts.dmSans(
            fontSize: 11, fontWeight: FontWeight.w500,
            color: !on ? Colors.white : Colors.white54)),
      ),
    ),
  ]);
}

class _ScanTile extends StatelessWidget {
  final String label;
  final String assetPath;   // mock fallback, used when imageUrl is null
  final String? imageUrl;   // real base image from the backend
  final String? overlayUrl; // real GradCAM overlay from the backend
  final bool showOverlay;   // GradCAM toggle state — only applies to real data
  final bool showHotspot;   // mock fallback ring
  final bool hotspotHigh;   // mock fallback ring color
  const _ScanTile({
    required this.label,
    required this.assetPath,
    this.imageUrl,
    this.overlayUrl,
    this.showOverlay = false,
    required this.showHotspot,
    required this.hotspotHigh,
  });

  static const _ngrokHeader = {'ngrok-skip-browser-warning': 'true'};

  @override
  Widget build(BuildContext context) {
    final hasReal = imageUrl != null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Stack(fit: StackFit.expand, children: [
          if (hasReal)
            Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              headers: _ngrokHeader,
              loadingBuilder: (ctx, child, progress) => progress == null
                  ? child
                  : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              errorBuilder: (_, __, ___) => Container(
                color: Colors.black26,
                child: const Icon(Icons.broken_image, color: Colors.white24),
              ),
            )
          else
            Image.asset(assetPath, fit: BoxFit.cover),
          Container(color: Colors.black12),
          if (hasReal && overlayUrl != null && showOverlay)
            Positioned.fill(
              child: Opacity(
                opacity: 0.7,
                child: Image.network(overlayUrl!, fit: BoxFit.cover, headers: _ngrokHeader),
              ),
            ),
          if (!hasReal && showHotspot) Positioned.fill(
            child: _HotspotOverlay(high: hotspotHigh),
          ),
          Positioned(
            bottom: 7, left: 7,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4)),
              child: Text(label, style: GoogleFonts.dmSans(
                  fontSize: 10, color: Colors.white60)),
            ),
          ),
        ]),
      ),
    );
  }
}
class _HotspotOverlay extends StatefulWidget {
  final bool high;
  const _HotspotOverlay({required this.high});

  @override
  State<_HotspotOverlay> createState() => _HotspotOverlayState();
}

class _HotspotOverlayState extends State<_HotspotOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 1.0, end: 0.45).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final color    = widget.high ? TulipColors.red400 : TulipColors.amber400;
    // Fractional offsets relative to tile width/height — stays locked to the
    // same anatomical spot whether the tile is small (panel) or large (full screen).
    final topFrac  = widget.high ? 0.375 : 0.53;
    final leftFrac = widget.high ? 0.30  : 0.15;
    const sizeFrac = 0.43;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => LayoutBuilder(
        builder: (_, constraints) {
          final w    = constraints.maxWidth;
          final h    = constraints.maxHeight;
          final size = w * sizeFrac;
          return Stack(children: [
            Positioned(
              top: h * topFrac, left: w * leftFrac,
              child: Opacity(
                opacity: _anim.value,
                child: Container(
                  width: size, height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.9), width: 1.5),
                    color: color.withValues(alpha: 0.15),
                  ),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

class _FindingRow extends StatelessWidget {
  final Color color;
  final String name;
  final String desc;
  final String score;
  final String? density;
  const _FindingRow({
    required this.color,
    required this.name,
    required this.desc,
    required this.score,
    this.density,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: TulipColors.border, width: 0.5))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Container(width: 7, height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: GoogleFonts.dmSans(
            fontSize: 13, fontWeight: FontWeight.w500, color: TulipColors.text)),
        Text(desc, style: GoogleFonts.dmSans(
            fontSize: 11, color: TulipColors.textS)),
        Text(
          density != null ? 'activation: $score · density: $density' : 'activation: $score',
          style: GoogleFonts.dmMono(fontSize: 10, color: TulipColors.textT)),
      ])),
    ]),
  );
}