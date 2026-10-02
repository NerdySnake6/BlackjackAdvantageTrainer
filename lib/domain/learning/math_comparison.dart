/// Exact finite distributions for Math & Reality's fictional point models.
library;

enum ComparisonMetric { expectedValue, variance, lossChance }

class PointDistribution {
  PointDistribution(List<int> outcomes)
    : outcomes = List.unmodifiable(outcomes) {
    if (outcomes.length < 2 ||
        outcomes.length > 12 ||
        outcomes.any((v) => v.abs() > 100)) {
      throw const FormatException('Invalid finite distribution');
    }
  }

  final List<int> outcomes;
  int get sum => outcomes.fold(0, (a, b) => a + b);
  int get squaredSum => outcomes.fold(0, (a, b) => a + b * b);
  (int, int) value(ComparisonMetric metric) => switch (metric) {
    ComparisonMetric.expectedValue => (sum, outcomes.length),
    ComparisonMetric.variance => (
      squaredSum * outcomes.length - sum * sum,
      outcomes.length * outcomes.length,
    ),
    ComparisonMetric.lossChance => (
      outcomes.where((v) => v < 0).length,
      outcomes.length,
    ),
  };
}

class MathComparison {
  MathComparison.fromJson(Map<String, Object?> json)
    : left = PointDistribution((json['left']! as List).cast<int>()),
      right = PointDistribution((json['right']! as List).cast<int>()),
      metric = ComparisonMetric.values.byName(json['metric']! as String),
      samples = List<int>.unmodifiable((json['samples']! as List).cast<int>()) {
    if (samples.length != 2 ||
        !left.outcomes.contains(samples[0]) ||
        !right.outcomes.contains(samples[1])) {
      throw const FormatException('Invalid comparison samples');
    }
  }

  final PointDistribution left;
  final PointDistribution right;
  final ComparisonMetric metric;
  final List<int> samples;
  String get expected {
    final (a, b) = left.value(metric);
    final (c, d) = right.value(metric);
    final difference = a * d - c * b;
    return difference == 0
        ? 'equal'
        : difference > 0
        ? 'left'
        : 'right';
  }

  Map<String, Object?> toJson() => {
    'left': left.outcomes,
    'right': right.outcomes,
    'metric': metric.name,
    'samples': samples,
  };
}
