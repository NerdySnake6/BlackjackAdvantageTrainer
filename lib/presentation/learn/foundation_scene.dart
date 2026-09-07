/// Hands are assembled visibly; answers remain hidden until coaching.
library;

import 'package:flutter/material.dart';

import '../../domain/blackjack_engine/hand.dart';
import '../../domain/learning/lesson_format.dart';
import '../../domain/learning/pilot_lesson.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/learn_card_view.dart';

String foundationAnswerLabel(AppLocalizations strings, String answer) =>
    switch (answer) {
      'hard' => strings.foundationHard,
      'soft' => strings.foundationSoft,
      'natural' => strings.foundationNatural,
      'twentyOne' => strings.foundationTwentyOne,
      'bust' => strings.foundationBust,
      'inPlay' => strings.foundationInPlay,
      _ => answer,
    };

class FoundationScene extends StatelessWidget {
  const FoundationScene({
    super.key,
    required this.task,
    required this.revealed,
    required this.input,
    required this.showExplanation,
    required this.enabled,
    required this.onReveal,
    required this.onAdjust,
    required this.onAnswer,
  });

  final PilotScenario task;
  final int revealed;
  final int input;
  final bool showExplanation;
  final bool enabled;
  final VoidCallback? onReveal;
  final ValueChanged<int> onAdjust;
  final ValueChanged<String> onAnswer;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final hand = task.cards.take(revealed).toList();
    final evaluation = const HandEvaluator().evaluate(hand);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(task.prompt),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final card in hand) LearnCardView(card: card, width: 64),
          ],
        ),
        Text('$revealed/${task.cards.length}'),
        if (showExplanation && hand.isNotEmpty)
          Semantics(
            liveRegion: true,
            child: Text(
              '${strings.handTotal(evaluation.total)} · ${evaluation.isSoft ? strings.foundationSoft : strings.foundationHard}',
              key: const ValueKey('foundation-revealed-total'),
            ),
          ),
        if (revealed < task.cards.length)
          FilledButton(
            key: const ValueKey('foundation-deal'),
            onPressed: onReveal,
            child: Text(strings.foundationDeal),
          ),
        if (task.kind == LessonMissionKind.handTotal) ...[
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton(
                tooltip: strings.foundationDecrease,
                onPressed: enabled && input > task.minimumInput
                    ? () => onAdjust(-1)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Semantics(
                liveRegion: true,
                child: Text(strings.foundationInput(input)),
              ),
              IconButton(
                tooltip: strings.foundationIncrease,
                onPressed: enabled && input < task.maximumInput
                    ? () => onAdjust(1)
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          FilledButton(
            key: const ValueKey('foundation-submit'),
            onPressed: enabled ? () => onAnswer('$input') : null,
            child: Text(strings.foundationCheck),
          ),
        ] else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final answer in task.answerKeys)
                FilledButton.tonal(
                  key: ValueKey('foundation-answer-$answer'),
                  onPressed: enabled ? () => onAnswer(answer) : null,
                  child: Text(foundationAnswerLabel(strings, answer)),
                ),
            ],
          ),
      ],
    );
  }
}

class FoundationActionResult extends StatelessWidget {
  const FoundationActionResult({super.key, required this.task});
  final PilotScenario task;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      key: const ValueKey('foundation-action-result'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(strings.foundationActionResult),
        for (final hand in task.demonstrationHands)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final card in hand) LearnCardView(card: card, width: 64),
              ],
            ),
          ),
        Text(task.explanation),
      ],
    );
  }
}
