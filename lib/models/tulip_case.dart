import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../models/case_score_response.dart';

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
  /// Patient age from the model backend's `age_years` (floating point —
  /// display should floor it). Null while running on mock/local data.
  final double? ageYears;
  /// Calibrated P(malignant) from the model backend's `probability_malignant`
  /// (== `diagnosis_probability`). Drives confidence displays that must
  /// reflect the model's actual score, distinct from `confidence` above
  /// which is also used for local sorting/UI heuristics.
    final double? probabilityMalignant;
  /// Per-view results (findings, diagnosis probability) keyed by view name
  /// ('L-CC', 'L-MLO', 'R-CC', 'R-MLO'). Null for mock/local cases.
      final Map<String, ViewResult>? viewResults;
  /// The backend's real case UUID (from `case.case_id`). Null for cases with
  /// no backend record (shouldn't happen once cases are always server-backed).
  final String? caseId;
  /// Model-assigned BI-RADS (1-5) from `suspicion.birads`. Null for mock cases.
  final int? birads;
  /// One of the 4 canonical strings from `case.recommendation`. Null for mock cases.
  final String? recommendation;

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
    this.ageYears,
    this.probabilityMalignant,
    this.viewResults,
    this.caseId,
    this.birads,
    this.recommendation,
  });
}

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
