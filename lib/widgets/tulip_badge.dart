import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tulip_case.dart';
import '../theme/colors.dart';

class TulipBadge extends StatelessWidget {
  final String label;
  final CaseStatus? status;
  final Color? bg;
  final Color? fg;
  const TulipBadge(this.label, {this.status, this.bg, this.fg, super.key});

  @override
  Widget build(BuildContext context) {
    Color bgColor = bg ?? TulipColors.gray50;
    Color fgColor = fg ?? TulipColors.gray800;
    if (status != null) {
      switch (status!) {
        case CaseStatus.urgent:  bgColor = TulipColors.red50;   fgColor = TulipColors.red800;   break;
        case CaseStatus.review:  bgColor = TulipColors.amber50; fgColor = TulipColors.amber800; break;
        case CaseStatus.cleared: bgColor = TulipColors.green50; fgColor = TulipColors.green800; break;
        case CaseStatus.pending: bgColor = TulipColors.gray50;  fgColor = TulipColors.gray800;  break;
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.dmSans(
          fontSize: 11, fontWeight: FontWeight.w500, color: fgColor)),
    );
  }
}
