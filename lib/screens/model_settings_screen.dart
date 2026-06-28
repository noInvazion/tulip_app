import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../widgets/t_card.dart';

class ModelSettingsScreen extends StatefulWidget {
  const ModelSettingsScreen({super.key});

  @override
  State<ModelSettingsScreen> createState() => _ModelSettingsScreenState();
}

class _ModelSettingsScreenState extends State<ModelSettingsScreen> {
  double _autoClearThreshold = 0.90;
  double _urgentThreshold    = 0.70;
  double _reviewThreshold    = 0.55;

  bool _gradcamEnabled       = true;
  bool _familyHistoryWeight  = true;
  bool _priorComparison      = true;
  bool _autoImpression       = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Model version card
        TCard(child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: TulipColors.p50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.memory_rounded, color: TulipColors.p400, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('TULIP-v2.1', style: GoogleFonts.dmSans(
                  fontSize: 16, fontWeight: FontWeight.w700, color: TulipColors.text)),
              Text('Trained Jan 2026 · deployed Mar 2026',
                style: GoogleFonts.dmSans(fontSize: 11, color: TulipColors.textS)),
            ])),
            const SizedBox(width: 24),
            _MetricChip('94.2%', 'Sensitivity', TulipColors.green400),
            const SizedBox(width: 12),
            _MetricChip('91.7%', 'Specificity', TulipColors.p400),
            const SizedBox(width: 12),
            _MetricChip('0.97', 'AUC-ROC', TulipColors.p400),
            const SizedBox(width: 24),
            TBtn('View release notes'),
          ]),
        )),
        const SizedBox(height: 20),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Confidence thresholds
          Expanded(child: TCard(child: Column(children: [
            const CardHeader('Confidence thresholds',
              subtitle: 'Determines automatic triage routing'),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                _ThresholdRow(
                  label: 'Auto-clear threshold',
                  description: 'Cases above this are cleared without radiologist review',
                  value: _autoClearThreshold,
                  color: TulipColors.p400,
                  onChanged: (v) => setState(() => _autoClearThreshold = v),
                ),
                const SizedBox(height: 20),
                _ThresholdRow(
                  label: 'Urgent flag threshold',
                  description: 'Cases above this are escalated to urgent queue',
                  value: _urgentThreshold,
                  color: TulipColors.red400,
                  onChanged: (v) => setState(() => _urgentThreshold = v),
                ),
                const SizedBox(height: 20),
                _ThresholdRow(
                  label: 'Needs review threshold',
                  description: 'Cases above this are sent to radiologist review queue',
                  value: _reviewThreshold,
                  color: TulipColors.amber400,
                  onChanged: (v) => setState(() => _reviewThreshold = v),
                ),
              ]),
            ),
          ]))),
          const SizedBox(width: 16),
          // Feature toggles
          SizedBox(width: 320, child: TCard(child: Column(children: [
            const CardHeader('Feature flags'),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(children: [
                _ToggleRow(
                  label: 'GradCAM overlay',
                  description: 'Show activation heatmap in scan viewer',
                  value: _gradcamEnabled,
                  onChanged: (v) => setState(() => _gradcamEnabled = v),
                ),
                _ToggleRow(
                  label: 'Family history weighting',
                  description: 'Increase urgency score for positive family hx',
                  value: _familyHistoryWeight,
                  onChanged: (v) => setState(() => _familyHistoryWeight = v),
                ),
                _ToggleRow(
                  label: 'Prior comparison check',
                  description: 'Flag cases with no prior study on record',
                  value: _priorComparison,
                  onChanged: (v) => setState(() => _priorComparison = v),
                ),
                _ToggleRow(
                  label: 'Auto-generate impression',
                  description: 'Pre-fill impression notes from model output',
                  value: _autoImpression,
                  onChanged: (v) => setState(() => _autoImpression = v),
                ),
              ]),
            ),
          ]))),
        ]),
        const SizedBox(height: 16),
        // Calibration card
        TCard(child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            const Icon(Icons.tune_rounded, size: 18, color: TulipColors.textT),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Model calibration', style: GoogleFonts.dmSans(
                  fontSize: 13, fontWeight: FontWeight.w600, color: TulipColors.text)),
              Text('Last calibrated: 12 Mar 2026 · Next scheduled: 12 Apr 2026',
                style: GoogleFonts.dmSans(fontSize: 11, color: TulipColors.textS)),
            ])),
            TBtn('Run calibration check'),
            const SizedBox(width: 8),
            TBtn('Export model report'),
          ]),
        )),
      ]),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _MetricChip(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: GoogleFonts.dmMono(
        fontSize: 18, fontWeight: FontWeight.w600, color: color)),
    Text(label, style: GoogleFonts.dmSans(fontSize: 10, color: TulipColors.textT)),
  ]);
}

class _ThresholdRow extends StatelessWidget {
  final String label;
  final String description;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;
  const _ThresholdRow({
    required this.label,
    required this.description,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.dmSans(
              fontSize: 13, fontWeight: FontWeight.w500, color: TulipColors.text)),
          Text(description, style: GoogleFonts.dmSans(
              fontSize: 11, color: TulipColors.textS)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('${(value * 100).round()}%', style: GoogleFonts.dmMono(
              fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ),
      ]),
      const SizedBox(height: 8),
      SliderTheme(
        data: SliderThemeData(
          activeTrackColor: color,
          inactiveTrackColor: TulipColors.gray100,
          thumbColor: color,
          overlayColor: color.withValues(alpha: 0.12),
          trackHeight: 3,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        ),
        child: Slider(value: value, min: 0.5, max: 1.0, onChanged: onChanged),
      ),
    ],
  );
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: TulipColors.border, width: 0.5)),
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.dmSans(
            fontSize: 13, fontWeight: FontWeight.w500, color: TulipColors.text)),
        Text(description, style: GoogleFonts.dmSans(
            fontSize: 11, color: TulipColors.textS)),
      ])),
      Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: TulipColors.p400,
        activeTrackColor: TulipColors.p100,
        inactiveThumbColor: TulipColors.gray200,
        inactiveTrackColor: TulipColors.gray50,
      ),
    ]),
  );
}
