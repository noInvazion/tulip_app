import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tulip_case.dart';
import '../theme/colors.dart';
import '../widgets/t_card.dart';
import '../widgets/case_row.dart';

class WorklistScreen extends StatefulWidget {
  final ValueChanged<TulipCase> onOpenCase;
  final List<TulipCase> cases;
  final VoidCallback? onNewIntake;
  const WorklistScreen({required this.onOpenCase, required this.cases, this.onNewIntake, super.key});

  @override
  State<WorklistScreen> createState() => _WorklistScreenState();
}

class _WorklistScreenState extends State<WorklistScreen> {
  int _filter = 0;

  List<TulipCase> get filtered {
    final all = widget.cases;
    switch (_filter) {
      case 1: return all.where((c) => c.status == CaseStatus.urgent).toList();
      case 2: return all.where((c) => c.status == CaseStatus.review).toList();
      case 3: return all.where((c) => c.status == CaseStatus.cleared).toList();
      default: return all;
    }
  }

  List<String> get filters => [
    'All cases (${widget.cases.length})',
    'Urgent (${widget.cases.where((c) => c.status == CaseStatus.urgent).length})',
    'Needs review (${widget.cases.where((c) => c.status == CaseStatus.review).length})',
    'Auto-cleared (${widget.cases.where((c) => c.status == CaseStatus.cleared).length})',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: TCard(child: Column(children: [
        // Filter bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: TulipColors.border, width: 0.5))),
          child: Row(children: [
            ...filters.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _filter = e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 130),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: _filter == e.key ? TulipColors.p800 : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _filter == e.key ? TulipColors.p800 : TulipColors.borderMid,
                      width: 0.5),
                  ),
                  child: Text(e.value, style: GoogleFonts.dmSans(
                    fontSize: 12, fontWeight: FontWeight.w500,
                    color: _filter == e.key ? Colors.white : TulipColors.textS)),
                ),
              ),
            )),
            const Spacer(),
            TBtn('+ New intake', primary: true, onTap: widget.onNewIntake),
          ]),
        ),
        const QTableHeader(),
        const SizedBox(height: 4),
        ...filtered.map((c) => Column(children: [
          CaseRow(c: c, onTap: () => widget.onOpenCase(c)),
          const Divider(height: 0.5, thickness: 0.5, color: TulipColors.border),
        ])),
        const SizedBox(height: 4),
      ])),
    );
  }
}
