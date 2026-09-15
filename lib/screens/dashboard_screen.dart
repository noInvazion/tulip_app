import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tulip_case.dart';
import '../theme/colors.dart';
import '../widgets/tulip_badge.dart';
import '../widgets/t_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/case_row.dart';

class DashboardScreen extends StatelessWidget {
  final ValueChanged<TulipCase> onOpenCase;
  final List<TulipCase> cases;
  final List<AuditEntry> auditEntries;
  const DashboardScreen({
    required this.onOpenCase,
    required this.cases,
    required this.auditEntries,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Stat cards
        Row(children: [
          Expanded(child: StatCard(
            label: 'Urgent cases',
            value: '${cases.where((c) => c.status == CaseStatus.urgent).length}',
            valueColor: TulipColors.red400)),
          const SizedBox(width: 12),
          Expanded(child: StatCard(label: 'In queue', value: '${cases.length}')),
          const SizedBox(width: 12),
          Expanded(child: StatCard(
            label: 'Needs review',
            value: '${cases.where((c) => c.status == CaseStatus.review).length}',
            valueColor: TulipColors.amber400)),
          const SizedBox(width: 12),
          Expanded(child: StatCard(
            label: 'Cleared',
            value: '${cases.where((c) => c.status == CaseStatus.cleared).length}',
            valueColor: TulipColors.p400)),
        ]),
        const SizedBox(height: 20),
        // Main grid
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Recent worklist
          Expanded(flex: 8, child: TCard(child: Column(children: [
            CardHeader('Recent worklist',
              subtitle: 'Sorted by urgency · showing ${cases.take(5).length}',
              trailing: TBtn('View all →')),
            const QTableHeader(),
            ...cases.take(5).toList().asMap().entries.map((e) => Column(children: [
              CaseRow(c: e.value, onTap: () => onOpenCase(e.value)),
              if (e.key < cases.take(5).length - 1)
                const Divider(height: 0.5, thickness: 0.5, color: TulipColors.border),
            ])),
          ]))),
          const SizedBox(width: 16),
          // Right column
          Expanded(flex: 5, child: Column(children: [
            _TriageDistCard(cases: cases),
            const SizedBox(height: 16),
            _AgreementCard(entries: auditEntries),
          ])),
        ]),
      ]),
    );
  }
}

class _TriageDistCard extends StatelessWidget {
  final List<TulipCase> cases;
  const _TriageDistCard({required this.cases});

  double _fraction(CaseStatus s) {
    if (cases.isEmpty) return 0;
    return cases.where((c) => c.status == s).length / cases.length;
  }

  @override
  Widget build(BuildContext context) => TCard(child: Column(children: [
    const CardHeader('Today\'s triage'),
    Padding(
      padding: const EdgeInsets.all(18),
      child: Column(children: [
        _DistBar('Auto-cleared', _fraction(CaseStatus.cleared), TulipColors.p400),
        const SizedBox(height: 10),
        _DistBar('Needs review', _fraction(CaseStatus.review), TulipColors.amber400),
        const SizedBox(height: 10),
        _DistBar('Urgent', _fraction(CaseStatus.urgent), TulipColors.red400),
        const SizedBox(height: 10),
        _DistBar('Additional imaging', _fraction(CaseStatus.pending), TulipColors.gray400),
      ]),
    ),
  ]));
}


class _DistBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _DistBar(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Row(children: [
    SizedBox(width: 90, child: Text(label,
      style: GoogleFonts.dmSans(fontSize: 12, color: TulipColors.textS))),
    const SizedBox(width: 10),
    Expanded(child: ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(value: value, minHeight: 8,
        backgroundColor: TulipColors.bg,
        valueColor: AlwaysStoppedAnimation<Color>(color)),
    )),
    const SizedBox(width: 10),
    SizedBox(width: 30, child: Text('${(value * 100).toInt()}%',
      textAlign: TextAlign.right,
      style: GoogleFonts.dmMono(fontSize: 11, color: TulipColors.textS))),
  ]);
}

class _AgreementCard extends StatelessWidget {
  final List<AuditEntry> entries;
  const _AgreementCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    final rows = entries.take(4).toList();
    return TCard(child: Column(children: [
      const CardHeader('Recent AI agreement'),
      if (rows.isEmpty)
        Padding(
          padding: const EdgeInsets.all(18),
          child: Text('No sign-offs yet', style: GoogleFonts.dmSans(
              fontSize: 12, color: TulipColors.textS)),
        )
      else
        ...rows.map((r) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: TulipColors.border, width: 0.5))),
          child: Row(children: [
            Expanded(child: Text(r.caseId, style: GoogleFonts.dmSans(
                fontSize: 12, fontWeight: FontWeight.w500, color: TulipColors.text))),
            Text(r.detail.split(' · ').first, style: GoogleFonts.dmSans(
                fontSize: 11, color: TulipColors.textS)),
            const SizedBox(width: 10),
            !r.override
              ? TulipBadge('Match', bg: TulipColors.green50, fg: TulipColors.green800)
              : TulipBadge('Override', bg: TulipColors.amber50, fg: TulipColors.amber800),
          ]),
        )),
    ]));
  }
}