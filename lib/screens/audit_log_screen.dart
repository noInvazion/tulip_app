import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../widgets/t_card.dart';
import '../widgets/tulip_badge.dart';
import '../models/tulip_case.dart';

class AuditLogScreen extends StatefulWidget {
  final List<AuditEntry> liveEntries;
  const AuditLogScreen({this.liveEntries = const [], super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  String _selectedFilter = 'All';
  final _filters = ['All', 'Sign-offs', 'Overrides', 'Flags'];

  static const _staticEntries = [
    AuditEntry(
      caseId: 'VDR-00522', demographics: 'F, 52', action: 'Signed off',
      detail: 'BI-RADS 1 confirmed · Auto-clear accepted',
      radiologist: 'Dr. Okafor', timestamp: 'Today, 11:42',
      status: CaseStatus.cleared, override: false,
    ),
    AuditEntry(
      caseId: 'VDR-00521', demographics: 'F, 48', action: 'Signed off',
      detail: 'BI-RADS 4 confirmed · Biopsy referral issued',
      radiologist: 'Dr. Okafor', timestamp: 'Today, 11:08',
      status: CaseStatus.urgent, override: false,
    ),
    AuditEntry(
      caseId: 'VDR-00488', demographics: 'F, 62', action: 'Signed off',
      detail: 'BI-RADS 1 confirmed · Routine follow-up',
      radiologist: 'Dr. Okafor', timestamp: 'Today, 08:52',
      status: CaseStatus.cleared, override: false,
    ),
    AuditEntry(
      caseId: 'VDR-00399', demographics: 'F, 47', action: 'Model override',
      detail: 'BI-RADS 0 → 3 · Radiologist downgraded urgency',
      radiologist: 'Dr. Chen', timestamp: 'Yesterday, 16:30',
      status: CaseStatus.review, override: true,
    ),
    AuditEntry(
      caseId: 'VDR-00341', demographics: 'F, 54', action: 'Flagged for 2nd opinion',
      detail: 'BI-RADS 4 · Peer review requested',
      radiologist: 'Dr. Chen', timestamp: 'Yesterday, 15:47',
      status: CaseStatus.urgent, override: false,
    ),
    AuditEntry(
      caseId: 'VDR-00318', demographics: 'F, 61', action: 'Signed off',
      detail: 'BI-RADS 4 confirmed · Urgent biopsy referral',
      radiologist: 'Dr. Chen', timestamp: 'Yesterday, 15:10',
      status: CaseStatus.urgent, override: false,
    ),
    AuditEntry(
      caseId: 'VDR-00307', demographics: 'F, 59', action: 'Model override',
      detail: 'BI-RADS 4 → 2 · Radiologist attributed to benign cyst',
      radiologist: 'Dr. Okafor', timestamp: 'Yesterday, 12:03',
      status: CaseStatus.cleared, override: true,
    ),
    AuditEntry(
      caseId: 'VDR-00291', demographics: 'F, 44', action: 'Signed off',
      detail: 'BI-RADS 3 confirmed · Short-interval follow-up',
      radiologist: 'Dr. Okafor', timestamp: 'Yesterday, 09:21',
      status: CaseStatus.review, override: false,
    ),
  ];

  List<AuditEntry> get _allEntries => [...widget.liveEntries, ..._staticEntries];

  List<AuditEntry> get _filtered {
    final all = _allEntries;
    if (_selectedFilter == 'All') return all;
    if (_selectedFilter == 'Overrides') return all.where((e) => e.override).toList();
    if (_selectedFilter == 'Sign-offs') return all.where((e) => e.action == 'Signed off').toList();
    if (_selectedFilter == 'Flags') return all.where((e) => e.action == 'Flagged for 2nd opinion').toList();
    return all;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Filter bar
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: const BoxDecoration(
          color: TulipColors.surface,
          border: Border(bottom: BorderSide(color: TulipColors.border, width: 0.5)),
        ),
        child: Row(children: [
          for (final f in _filters) ...[
            GestureDetector(
              onTap: () => setState(() => _selectedFilter = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _selectedFilter == f ? TulipColors.p50 : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _selectedFilter == f ? TulipColors.p400 : Colors.transparent,
                    width: 0.5),
                ),
                child: Text(f, style: GoogleFonts.dmSans(
                  fontSize: 12, fontWeight: FontWeight.w500,
                  color: _selectedFilter == f ? TulipColors.p600 : TulipColors.textS)),
              ),
            ),
            const SizedBox(width: 6),
          ],
          const Spacer(),
          Text('${_filtered.length} entries',
            style: GoogleFonts.dmMono(fontSize: 11, color: TulipColors.textT)),
          const SizedBox(width: 16),
          TBtn('Export CSV'),
        ]),
      ),
      // Table
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: TCard(child: Column(children: [
          const _AuditTableHeader(),
          ..._filtered.map((e) => _AuditRow(entry: e)),
        ])),
      )),
    ]);
  }
}

class _AuditTableHeader extends StatelessWidget {
  const _AuditTableHeader();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: TulipColors.border, width: 0.5)),
    ),
    child: Row(children: [
      _TH('Case', 110),
      const SizedBox(width: 16),
      _TH('Action', 160),
      const SizedBox(width: 16),
      const Expanded(child: _THText('Detail')),
      const SizedBox(width: 16),
      _TH('Radiologist', 130),
      const SizedBox(width: 16),
      _TH('Timestamp', 130),
      const SizedBox(width: 16),
      _TH('', 80),
    ]),
  );
}

class _AuditRow extends StatefulWidget {
  final AuditEntry entry;
  const _AuditRow({required this.entry});

  @override
  State<_AuditRow> createState() => _AuditRowState();
}

class _AuditRowState extends State<_AuditRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: _hover ? TulipColors.bg : Colors.transparent,
          border: const Border(bottom: BorderSide(color: TulipColors.border, width: 0.5)),
        ),
        child: Row(children: [
          // Case + demographics
          SizedBox(width: 110, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.caseId, style: GoogleFonts.dmSans(
                fontSize: 13, fontWeight: FontWeight.w600, color: TulipColors.text)),
            Text(e.demographics, style: GoogleFonts.dmSans(
                fontSize: 11, color: TulipColors.textS)),
          ])),
          const SizedBox(width: 16),
          // Action
          SizedBox(width: 160, child: Row(children: [
            Container(width: 3, height: 32,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: statusColor(e.status),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Flexible(child: Text(e.action, style: GoogleFonts.dmSans(
                fontSize: 12, fontWeight: FontWeight.w500, color: TulipColors.text),
              overflow: TextOverflow.ellipsis)),
          ])),
          const SizedBox(width: 16),
          // Detail
          Expanded(child: Text(e.detail,
            style: GoogleFonts.dmSans(fontSize: 12, color: TulipColors.textS),
            overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 16),
          // Radiologist
          SizedBox(width: 130, child: Text(e.radiologist,
            style: GoogleFonts.dmSans(fontSize: 12, color: TulipColors.text))),
          const SizedBox(width: 16),
          // Timestamp
          SizedBox(width: 130, child: Text(e.timestamp,
            style: GoogleFonts.dmMono(fontSize: 11, color: TulipColors.textT))),
          const SizedBox(width: 16),
          // Override badge
          SizedBox(width: 80, child: e.override
            ? TulipBadge('Override', status: CaseStatus.review)
            : const SizedBox.shrink()),
        ]),
      ),
    );
  }
}

class _TH extends StatelessWidget {
  final String text;
  final double width;
  const _TH(this.text, this.width);

  @override
  Widget build(BuildContext context) => SizedBox(width: width, child: _THText(text));
}

class _THText extends StatelessWidget {
  final String text;
  const _THText(this.text);

  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
    style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600,
        color: TulipColors.textT, letterSpacing: 0.7));
}
