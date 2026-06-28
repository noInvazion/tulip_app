import 'package:flutter/material.dart';
import '../theme/colors.dart';

enum CaseStatus { urgent, review, cleared, pending }

class TulipCase {
  final String id;
  final String demographics;
  final String finding;
  final double confidence;
  final CaseStatus status;
  final String waitTime;
  final String studyType;
  final String? impression;
  final int? scenarioIndex;

  const TulipCase({
    required this.id,
    required this.demographics,
    required this.finding,
    required this.confidence,
    required this.status,
    required this.waitTime,
    required this.studyType,
    this.impression,
    this.scenarioIndex,
  });
}

final List<TulipCase> mockCases = const [
  TulipCase(id: 'VDR-00341', demographics: 'F, 54 yrs',
    finding: 'Spiculated mass, L-CC upper outer',
    confidence: 0.88, status: CaseStatus.urgent, waitTime: '2h 14m',
    studyType: 'Bilateral screening', scenarioIndex: 0,
    impression: 'Spiculated irregular mass identified in L-CC upper-outer quadrant (~14mm). Corroborating asymmetric density in L-MLO. Right breast unremarkable. BI-RADS 4B — biopsy consult advised.'),
  TulipCase(id: 'VDR-00318', demographics: 'F, 61 yrs',
    finding: 'Irregular spiculated mass, L-CC upper outer',
    confidence: 0.91, status: CaseStatus.urgent, waitTime: '3h 02m',
    studyType: 'Diagnostic', scenarioIndex: 0,
    impression: 'Spiculated mass identified L-CC upper-outer quadrant. High activation corroborated in L-MLO. No right breast findings. BI-RADS 4C — urgent biopsy referral recommended.'),
  TulipCase(id: 'VDR-00399', demographics: 'F, 47 yrs',
    finding: 'Focal asymmetry, R-CC · spot compression advised',
    confidence: 0.63, status: CaseStatus.review, waitTime: '47m',
    studyType: 'Screening', scenarioIndex: 2,
    impression: 'Focal asymmetry in R-CC. R-MLO asymmetric density cannot exclude architectural distortion. Left breast unremarkable. BI-RADS 0 — additional imaging required. Recommend diagnostic spot compression views.'),
  TulipCase(id: 'VDR-00488', demographics: 'F, 62 yrs',
    finding: 'No significant finding — bilateral',
    confidence: 0.95, status: CaseStatus.cleared, waitTime: '1h 44m',
    studyType: 'Bilateral screening', scenarioIndex: 1,
    impression: 'Bilateral screening mammogram reviewed. No suspicious masses, calcifications, or architectural distortions identified. Both breasts appear symmetric. BI-RADS 1 — routine annual screening recommended.'),
];

class AuditEntry {
  final String caseId;
  final String demographics;
  final String action;
  final String detail;
  final String radiologist;
  final String timestamp;
  final CaseStatus status;
  final bool override;
  const AuditEntry({
    required this.caseId,
    required this.demographics,
    required this.action,
    required this.detail,
    required this.radiologist,
    required this.timestamp,
    required this.status,
    required this.override,
  });
}

String statusLabel(CaseStatus s) {
  switch (s) {
    case CaseStatus.urgent:  return 'Urgent';
    case CaseStatus.review:  return 'Needs review';
    case CaseStatus.cleared: return 'Auto-cleared ✓';
    case CaseStatus.pending: return 'Pending';
  }
}

Color statusColor(CaseStatus s) {
  switch (s) {
    case CaseStatus.urgent:  return TulipColors.red400;
    case CaseStatus.review:  return TulipColors.amber400;
    case CaseStatus.cleared: return TulipColors.p400;
    case CaseStatus.pending: return TulipColors.gray400;
  }
}
