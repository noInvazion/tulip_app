import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../widgets/t_card.dart';
import '../widgets/stat_card.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Row(children: [
          Expanded(child: StatCard(label: 'Cases this week', value: '214',
            delta: '↑ 18% vs last week', deltaUp: true)),
          const SizedBox(width: 12),
          Expanded(child: StatCard(label: 'Auto-clear rate', value: '67%',
            delta: 'target: 70%', valueColor: TulipColors.p400)),
          const SizedBox(width: 12),
          Expanded(child: StatCard(label: 'Time saved', value: '11.2h',
            delta: 'this week', deltaUp: true)),
          const SizedBox(width: 12),
          Expanded(child: StatCard(label: 'Model overrides', value: '4',
            delta: '1.9% of confirmed')),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: TCard(child: Column(children: [
            const CardHeader('Daily triage volume', subtitle: 'Cases this week'),
            Padding(
              padding: const EdgeInsets.all(18),
              child: SizedBox(height: 110,
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  _Bar(46, 80, TulipColors.p200, 'Mon'),
                  const SizedBox(width: 6),
                  _Bar(62, 80, TulipColors.p200, 'Tue'),
                  const SizedBox(width: 6),
                  _Bar(52, 80, TulipColors.p200, 'Wed'),
                  const SizedBox(width: 6),
                  _Bar(68, 80, TulipColors.p400, 'Thu'),
                  const SizedBox(width: 6),
                  _Bar(38, 80, TulipColors.p200, 'Fri'),
                  const SizedBox(width: 6),
                  _Bar(18, 80, TulipColors.gray100, 'Sat'),
                  const SizedBox(width: 6),
                  _Bar(10, 80, TulipColors.gray100, 'Sun'),
                ])),
            ),
          ]))),
          const SizedBox(width: 16),
          Expanded(child: TCard(child: Column(children: [
            const CardHeader('Confidence distribution', subtitle: 'Model output scores'),
            Padding(
              padding: const EdgeInsets.all(18),
              child: SizedBox(height: 110,
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  _Bar(14, 80, TulipColors.red100, '<60'),
                  const SizedBox(width: 6),
                  _Bar(30, 80, TulipColors.amber100, '60–70'),
                  const SizedBox(width: 6),
                  _Bar(40, 80, TulipColors.amber50, '70–80'),
                  const SizedBox(width: 6),
                  _Bar(52, 80, TulipColors.p200, '80–90'),
                  const SizedBox(width: 6),
                  _Bar(68, 80, TulipColors.p400, '>90'),
                ])),
            ),
          ]))),
        ]),
      ]),
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;
  final double maxH;
  final Color color;
  final String label;
  const _Bar(this.height, this.maxH, this.color, this.label);

  @override
  Widget build(BuildContext context) => Expanded(child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: height / maxH,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 4),
      Text(label,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.dmSans(fontSize: 9, color: TulipColors.textT)),
    ],
  ));
}
