/// Compare fictional finite point distributions rather than wager outcomes.
library;

import 'package:flutter/material.dart';

import '../../domain/learning/math_comparison.dart';
import '../../domain/learning/pilot_lesson.dart';
import '../../l10n/app_localizations.dart';

String mathAnswerLabel(AppLocalizations strings, String answer) =>
    switch (answer) {
      'left' => strings.mathLeft,
      'right' => strings.mathRight,
      _ => strings.mathEqual,
    };

class MathComparisonScene extends StatelessWidget {
  const MathComparisonScene({
    super.key,
    required this.task,
    required this.revealed,
    required this.showExplanation,
    required this.enabled,
    required this.canReveal,
    required this.onReveal,
    required this.onAnswer,
  });

  final PilotScenario task;
  final int revealed;
  final bool showExplanation;
  final bool enabled;
  final bool canReveal;
  final VoidCallback onReveal;
  final ValueChanged<String> onAnswer;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final comparison = task.comparison!;
    final question = switch (comparison.metric) {
      ComparisonMetric.expectedValue => strings.mathChooseMean,
      ComparisonMetric.variance => strings.mathChooseVariance,
      ComparisonMetric.lossChance => strings.mathChooseLoss,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(task.prompt),
        Text(strings.mathModelNote),
        for (final entry in [comparison.left, comparison.right].indexed)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    mathAnswerLabel(strings, entry.$1 == 0 ? 'left' : 'right'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(strings.mathOutcomes(entry.$2.outcomes.length)),
                  for (final value
                      in entry.$2.outcomes.toSet().toList()..sort())
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.mathProbability(
                              value,
                              entry.$2.outcomes.where((v) => v == value).length,
                              entry.$2.outcomes.length,
                            ),
                          ),
                          ExcludeSemantics(
                            child: LinearProgressIndicator(
                              value:
                                  entry.$2.outcomes
                                      .where((v) => v == value)
                                      .length /
                                  entry.$2.outcomes.length,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (showExplanation) ...[
                    Text(
                      strings.mathMean(
                        _fraction(
                          entry.$2.value(ComparisonMetric.expectedValue),
                        ),
                      ),
                    ),
                    Text(
                      strings.mathVariance(
                        _fraction(entry.$2.value(ComparisonMetric.variance)),
                      ),
                    ),
                  ],
                  if (revealed > entry.$1)
                    Text(strings.mathSample(comparison.samples[entry.$1]))
                  else if (revealed == entry.$1)
                    FilledButton.tonal(
                      key: ValueKey('math-reveal-${entry.$1}'),
                      onPressed: canReveal ? onReveal : null,
                      child: Text(strings.mathReveal),
                    ),
                ],
              ),
            ),
          ),
        Text(question),
        for (final answer in ['left', 'right', 'equal'])
          FilledButton(
            key: ValueKey('math-answer-$answer'),
            onPressed: enabled ? () => onAnswer(answer) : null,
            child: Text(mathAnswerLabel(strings, answer)),
          ),
      ],
    );
  }

  String _fraction((int, int) value) {
    final divisor = value.$1.gcd(value.$2);
    final numerator = value.$1 ~/ divisor;
    final denominator = value.$2 ~/ divisor;
    return denominator == 1 ? '$numerator' : '$numerator/$denominator';
  }
}
