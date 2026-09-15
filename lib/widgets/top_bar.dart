import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tulip_case.dart';
import '../theme/colors.dart';

class TopBar extends StatelessWidget {
  final List<String> screenTitles;
  final int index;
  final List<TulipCase> cases;
  const TopBar({
    required this.screenTitles,
    required this.index,
    required this.cases,
    super.key,
  });

  static const _weekdayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];
  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December',
  ];

  String get _formattedDate {
    final d = DateTime.now();
    return '${_weekdayNames[d.weekday - 1]}, ${d.day} ${_monthNames[d.month - 1]} ${d.year}';
  }

  List<String> get _subtitles {
    final urgent = cases.where((c) => c.status == CaseStatus.urgent).length;
    return [
      _formattedDate,
      '${cases.length} cases · $urgent urgent',
      'Upload patient scans',
      'Performance overview',
      '',
      '',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final subtitles = _subtitles;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: TulipColors.surface,
        border: Border(bottom: BorderSide(color: TulipColors.border, width: 0.5)),
      ),
      child: Row(children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(screenTitles[index], style: GoogleFonts.dmSans(
                fontSize: 16, fontWeight: FontWeight.w600,
                color: TulipColors.text, letterSpacing: -0.3)),
            if (subtitles[index].isNotEmpty)
              Text(subtitles[index], style: GoogleFonts.dmSans(
                  fontSize: 12, color: TulipColors.textS)),
          ],
        ),
        const Spacer(),
        Container(
          width: 220, height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: TulipColors.bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: TulipColors.borderMid, width: 0.5),
          ),
          child: Row(children: [
            const Icon(Icons.search, size: 14, color: TulipColors.textT),
            const SizedBox(width: 8),
            Expanded(child: TextField(
              decoration: InputDecoration(
                hintText: 'Search patient ID…',
                hintStyle: GoogleFonts.dmSans(fontSize: 13, color: TulipColors.textT),
                border: InputBorder.none,
                isDense: true,
              ),
              style: GoogleFonts.dmSans(fontSize: 13, color: TulipColors.text),
            )),
          ]),
        ),
        const SizedBox(width: 10),
        _IconBtn(icon: Icons.notifications_outlined),
      ]),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  const _IconBtn({required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    width: 34, height: 34,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: TulipColors.borderMid, width: 0.5),
    ),
    child: Icon(icon, size: 16, color: TulipColors.textS),
  );
}