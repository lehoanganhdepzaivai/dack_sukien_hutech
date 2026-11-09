class Recommendation {
  const Recommendation({
    required this.score,
    required this.reasons,
    required this.warnings,
    required this.breakdown,
  });
  final int score;
  final List<String> reasons, warnings;

  /// Each criterion is normalized to 0..1; weights live in RecommendationConfig.
  final Map<String, double> breakdown;
}
