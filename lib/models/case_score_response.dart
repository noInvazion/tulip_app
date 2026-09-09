/// Parsed response from POST /api/case.
/// Mirrors the shape documented in FRONTEND.md §4.

class CaseScoreResponse {
  final CaseSummary caseSummary;
  final Map<String, BreastResult> breasts; // keys: "L", "R" (either may be absent)
  final List<ViewResult> views;
  final ReportResult report;

  CaseScoreResponse({
    required this.caseSummary,
    required this.breasts,
    required this.views,
    required this.report,
  });

  factory CaseScoreResponse.fromJson(Map<String, dynamic> json) {
    final breastsJson = json['breasts'] as Map<String, dynamic>;
    return CaseScoreResponse(
      caseSummary: CaseSummary.fromJson(json['case'] as Map<String, dynamic>),
      breasts: breastsJson.map(
        (k, v) => MapEntry(k, BreastResult.fromJson(v as Map<String, dynamic>)),
      ),
      views: (json['views'] as List)
          .map((v) => ViewResult.fromJson(v as Map<String, dynamic>))
          .toList(),
      report: ReportResult.fromJson(json['report'] as Map<String, dynamic>),
    );
  }
}

class CaseSummary {
  final String caseId;
  final double diagnosisProbability;
  final String diagnosisLaterality;
  final int birads;
  final double probabilityMalignant;
  final double ageYears; // floating point — floor for display
  final String recommendation;
  final bool incomplete;
  final List<String> missingViews;

  CaseSummary({
    required this.caseId,
    required this.diagnosisProbability,
    required this.diagnosisLaterality,
    required this.birads,
    required this.probabilityMalignant,
    required this.ageYears,
    required this.recommendation,
    required this.incomplete,
    required this.missingViews,
  });

  factory CaseSummary.fromJson(Map<String, dynamic> json) {
    final suspicion = json['suspicion'] as Map<String, dynamic>;
    return CaseSummary(
      caseId: json['case_id'] as String,
      diagnosisProbability: (json['diagnosis_probability'] as num).toDouble(),
      diagnosisLaterality: json['diagnosis_laterality'] as String,
      birads: suspicion['birads'] as int,
      probabilityMalignant: (suspicion['probability_malignant'] as num).toDouble(),
      ageYears: (json['age_years'] as num).toDouble(),
      recommendation: json['recommendation'] as String,
      incomplete: json['incomplete'] as bool,
      missingViews: (json['missing_views'] as List).cast<String>(),
    );
  }
}

class BreastResult {
  final String laterality;
  final double diagnosisProbability;
  final int birads;
  final double probabilityMalignant;
  final String densityLetter;
  final double densityProbability;
  final List<FindingResult> findings;
  final List<String> viewNames;

  BreastResult({
    required this.laterality,
    required this.diagnosisProbability,
    required this.birads,
    required this.probabilityMalignant,
    required this.densityLetter,
    required this.densityProbability,
    required this.findings,
    required this.viewNames,
  });

  factory BreastResult.fromJson(Map<String, dynamic> json) {
    final suspicion = json['suspicion'] as Map<String, dynamic>;
    final density = json['density'] as Map<String, dynamic>;
    return BreastResult(
      laterality: json['laterality'] as String,
      diagnosisProbability: (json['diagnosis_probability'] as num).toDouble(),
      birads: suspicion['birads'] as int,
      probabilityMalignant: (suspicion['probability_malignant'] as num).toDouble(),
      densityLetter: density['letter'] as String,
      densityProbability: (density['probability'] as num).toDouble(),
      findings: (json['findings'] as List)
          .map((f) => FindingResult.fromJson(f as Map<String, dynamic>))
          .toList(),
      viewNames: (json['views'] as List).cast<String>(),
    );
  }
}

class FindingResult {
  final String name;
  final double probability;
  final bool validated; // only trust findings where this is true (see FRONTEND.md §6)

  FindingResult({required this.name, required this.probability, required this.validated});

  factory FindingResult.fromJson(Map<String, dynamic> json) => FindingResult(
        name: json['name'] as String,
        probability: (json['probability'] as num).toDouble(),
        validated: json['validated'] as bool,
      );
}

class ViewResult {
  final String view; // "L-CC", "L-MLO", "R-CC", "R-MLO"
  final double diagnosisProbability;
  final String densityLetter;
  final List<FindingResult> findings;
  final String imageUrl;   // relative path — prepend baseUrl
  final String overlayUrl; // relative path — prepend baseUrl
  final List<double> peak; // normalised [x, y] in 0..1

  ViewResult({
    required this.view,
    required this.diagnosisProbability,
    required this.densityLetter,
    required this.findings,
    required this.imageUrl,
    required this.overlayUrl,
    required this.peak,
  });

  factory ViewResult.fromJson(Map<String, dynamic> json) {
    final density = json['density'] as Map<String, dynamic>;
    return ViewResult(
      view: json['view'] as String,
      diagnosisProbability: (json['diagnosis_probability'] as num).toDouble(),
      densityLetter: density['letter'] as String,
      findings: (json['findings'] as List)
          .map((f) => FindingResult.fromJson(f as Map<String, dynamic>))
          .toList(),
      imageUrl: json['image_url'] as String,
      overlayUrl: json['overlay_url'] as String,
      peak: (json['peak'] as List).map((e) => (e as num).toDouble()).toList(),
    );
  }
}

class ReportResult {
  final String text;   // show verbatim — never paraphrase (see FRONTEND.md §6)
  final String source; // "llm" or "fallback"
  final String disclaimer;

  ReportResult({required this.text, required this.source, required this.disclaimer});

  factory ReportResult.fromJson(Map<String, dynamic> json) => ReportResult(
        text: json['text'] as String,
        source: json['source'] as String,
        disclaimer: json['disclaimer'] as String,
      );
}