import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import 't_card.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? delta;
  final bool deltaUp;
  final Color? valueColor;
  final VoidCallback? onTap;
  const StatCard({
    required this.label,
    required this.value,
    this.delta,
    this.deltaUp = false,
    this.valueColor,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: TCard(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label.toUpperCase(),
                style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: TulipColors.textS,
                    letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.dmSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? TulipColors.text,
                    letterSpacing: -1)),
            if (delta != null) ...[
              const SizedBox(height: 6),
              Row(children: [
                if (deltaUp)
                  const Icon(Icons.arrow_upward,
                      size: 11, color: TulipColors.green400),
                Flexible(
                    child: Text(delta!,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmMono(
                            fontSize: 11,
                            color: deltaUp
                                ? TulipColors.green400
                                : TulipColors.textT))),
              ]),
            ],
          ]),
        ),
      );
}
