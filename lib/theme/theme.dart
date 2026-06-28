import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

ThemeData get tulipTheme {
  final base = GoogleFonts.dmSansTextTheme();
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: TulipColors.p600,
      secondary: TulipColors.p400,
      surface: TulipColors.surface,
    ),
    scaffoldBackgroundColor: TulipColors.bg,
    textTheme: base.copyWith(
      bodyMedium: base.bodyMedium?.copyWith(color: TulipColors.text),
    ),
    fontFamily: GoogleFonts.dmSans().fontFamily,
    dividerColor: TulipColors.border,
  );
}
