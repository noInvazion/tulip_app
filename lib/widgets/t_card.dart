import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';

class TCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const TCard({required this.child, this.padding, super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: TulipColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: TulipColors.border, width: 0.5),
    ),
    child: child,
  );
}

class CardHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const CardHeader(this.title, {this.subtitle, this.trailing, super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: TulipColors.border, width: 0.5)),
    ),
    child: Row(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.dmSans(
            fontSize: 13, fontWeight: FontWeight.w600, color: TulipColors.text)),
        if (subtitle != null) Text(subtitle!, style: GoogleFonts.dmSans(
            fontSize: 11, color: TulipColors.textS)),
      ]),
      if (trailing != null) ...[const Spacer(), trailing!],
    ]),
  );
}

class TBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final bool small;
  const TBtn(this.label, {this.onTap, this.primary = false, this.small = false, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: small ? 12 : 16,
          vertical: small ? 5 : 7,
        ),
        decoration: BoxDecoration(
          color: primary ? TulipColors.p600 : TulipColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: primary ? TulipColors.p600 : TulipColors.borderMid,
            width: 0.5,
          ),
        ),
        child: Text(label, style: GoogleFonts.dmSans(
          fontSize: small ? 12 : 13, fontWeight: FontWeight.w500,
          color: primary ? Colors.white : TulipColors.text,
        )),
      ),
    );
  }
}
