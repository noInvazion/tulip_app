import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tulip_case.dart';
import '../theme/colors.dart';
import 'tulip_badge.dart';
import 't_card.dart';

class ConfBar extends StatelessWidget {
  final double value;
  final CaseStatus status;
  const ConfBar({required this.value, required this.status, super.key});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 4,
              backgroundColor: TulipColors.gray50,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor(status)),
            ),
          ),
          const SizedBox(height: 3),
          Text('${(value * 100).toStringAsFixed(0)}%',
              style:
                  GoogleFonts.dmMono(fontSize: 10, color: TulipColors.textT)),
        ],
      );
}

class CaseRow extends StatefulWidget {
  final TulipCase c;
  final VoidCallback onTap;
  const CaseRow({required this.c, required this.onTap, super.key});

  @override
  State<CaseRow> createState() => _CaseRowState();
}

class _CaseRowState extends State<CaseRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          color: _hover ? TulipColors.bg : Colors.transparent,
          child: Row(children: [
            // urgency stripe
            Container(
              width: 3,
              height: 52,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: statusColor(c.status),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 14),
            // ID + demographics
            SizedBox(
                width: 110,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.id,
                          style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: TulipColors.text)),
                      Text(c.demographics,
                          style: GoogleFonts.dmSans(
                              fontSize: 11, color: TulipColors.textS)),
                    ])),
            const SizedBox(width: 16),
            // Finding
            Expanded(
                child: Text(c.finding,
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: TulipColors.text),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 16),
            // Confidence
            SizedBox(
                width: 90,
                child: ConfBar(
                    value: c.probabilityMalignant ?? c.confidence,
                    status: c.status)),
            const SizedBox(width: 16),
            // Badge
            SizedBox(
                width: 110,
                child: TulipBadge(statusLabel(c.status), status: c.status)),
            const SizedBox(width: 16),
            // Wait
            SizedBox(
                width: 60,
                child: Text(c.waitTime,
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: TulipColors.textT))),
            const SizedBox(width: 16),
            // Action
            SizedBox(
              width: 90,
              child: TBtn(
                c.status == CaseStatus.cleared ? 'Spot-check' : 'Open',
                onTap: widget.onTap,
                primary: c.status == CaseStatus.urgent,
                small: true,
              ),
            ),
            const SizedBox(width: 16),
          ]),
        ),
      ),
    );
  }
}

class QTableHeader extends StatelessWidget {
  const QTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
      decoration: const BoxDecoration(
        border:
            Border(bottom: BorderSide(color: TulipColors.border, width: 0.5)),
      ),
      child: Row(children: [
        const SizedBox(width: 17),
        _TH('Patient', 110),
        const SizedBox(width: 16),
        const Expanded(child: _THText('Finding')),
        const SizedBox(width: 16),
        _TH('Malignancy', 90),
        const SizedBox(width: 16),
        _TH('Status', 110),
        const SizedBox(width: 16),
        _TH('Wait', 60),
        const SizedBox(width: 16),
        _TH('', 90),
        const SizedBox(width: 16),
      ]),
    );
  }
}

class _TH extends StatelessWidget {
  final String text;
  final double width;
  const _TH(this.text, this.width);

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: width, child: _THText(text));
}

class _THText extends StatelessWidget {
  final String text;
  const _THText(this.text);

  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: TulipColors.textT,
          letterSpacing: 0.7));
}
