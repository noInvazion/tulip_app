import '../models/case_score_response.dart';
import '../models/tulip_case.dart';

/// The highest-probability finding that passed backend validation, or null
/// if none did (only Mass and Suspicious Calcification are validated —
/// see FRONTEND.md §6).
FindingResult? topValidatedFinding(List<FindingResult> findings) {
  final validated = findings.where((f) => f.validated).toList()
    ..sort((a, b) => b.probability.compareTo(a.probability));
  return validated.isEmpty ? null : validated.first;
}

CaseStatus caseStatusFromRecommendation(String recommendation) => switch (recommendation) {
  'Tissue Biopsy Recommended'           => CaseStatus.urgent,
  'Short Interval Follow Up (6 months)' => CaseStatus.review,
  'Routine Follow Up (1 year)'          => CaseStatus.cleared,
  'Additional Imaging Needed'           => CaseStatus.pending,
  _                                     => CaseStatus.pending,
};

String caseFindingSummary(CaseScoreResponse r) {
  final breast = r.breasts[r.caseSummary.diagnosisLaterality];
  final top = breast != null ? topValidatedFinding(breast.findings) : null;
  return top != null
      ? '${top.name}, ${r.caseSummary.diagnosisLaterality} breast'
      : 'No significant finding — bilateral';
}

int recommendationIndex(String recommendation) => switch (recommendation) {
  'Routine Follow Up (1 year)'          => 0,
  'Short Interval Follow Up (6 months)' => 1,
  'Tissue Biopsy Recommended'           => 2,
  'Additional Imaging Needed'           => 3,
  _                                     => 2,
};

/// Builds the domain TulipCase used across worklist/dashboard/detail panel
/// from a raw backend response — for a freshly-scored case or one restored
/// via GET /api/cases.
TulipCase tulipCaseFromResponse(
  CaseScoreResponse r, {
  required String id,
  String? demographics,
  String studyType = 'Bilateral screening',
  String waitTime = 'just now',
}) {
  return TulipCase(
    id: id,
    demographics: demographics ?? 'Age ${r.caseSummary.ageYears.floor()}',
    finding: caseFindingSummary(r),
    confidence: r.caseSummary.probabilityMalignant,
    status: caseStatusFromRecommendation(r.caseSummary.recommendation),
    waitTime: waitTime,
    studyType: studyType,
    impression: r.report.text,
    ageYears: r.caseSummary.ageYears,
    probabilityMalignant: r.caseSummary.probabilityMalignant,
    viewResults: { for (final v in r.views) v.view: v },
    caseId: r.caseSummary.caseId,
    birads: r.caseSummary.birads,
    recommendation: r.caseSummary.recommendation
  );
}