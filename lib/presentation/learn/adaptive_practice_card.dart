/// Optional coaching selected from observed first-answer errors, never scored.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/blackjack_engine/game_rules.dart';
import '../../domain/blackjack_engine/hand.dart';
import '../../domain/learning/lesson_adaptation.dart';
import '../../l10n/app_localizations.dart';
import '../../viewmodels/pilot_lesson_view_model.dart';
import '../drill/cancellation_scene.dart';
import '../table/table_formatters.dart';
import 'decision_scene.dart';

class AdaptivePracticeCard extends StatelessWidget {
  const AdaptivePracticeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PilotLessonViewModel>();
    final session = vm.session;
    final plan = session.adaptation;
    if (!session.isAdaptiveBoundary || plan == null) {
      return const SizedBox.shrink();
    }
    final strings = AppLocalizations.of(context);
    final task = plan.example;
    final answer = session.adaptiveAnswer;
    final explanation = switch (plan.focus) {
      AdaptiveFocus.hardStand => strings.adaptiveHardStand,
      AdaptiveFocus.hardHit => strings.adaptiveHardHit,
      AdaptiveFocus.softDouble => strings.adaptiveSoftDouble,
      AdaptiveFocus.softStand => strings.adaptiveSoftStand,
      AdaptiveFocus.softHit => strings.adaptiveSoftHit,
      AdaptiveFocus.softFallback => strings.adaptiveSoftFallback,
      AdaptiveFocus.countResult => strings.adaptiveCountResult,
      AdaptiveFocus.extraCard => switch (vm.lesson.id) {
        'hard-12' => strings.adaptiveExtraHard,
        'soft-18' => strings.adaptiveExtraSoft,
        _ => strings.adaptiveExtraCount,
      },
    };
    final enabled = !vm.busy && answer == null;
    String label(String value) => task.isCounting
        ? value
        : actionLabel(strings, PlayerAction.values.byName(value));
    return Card(
      key: const ValueKey('adaptive-practice'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plan.isChallenge
                  ? strings.adaptiveChallengeTitle
                  : strings.adaptiveHelpTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(strings.adaptiveOptional),
            Text(strings.adaptiveVariant(session.adaptiveSeed + 1)),
            if (!plan.isChallenge || answer != null) Text(explanation),
            if (task.isCounting) ...[
              Text(strings.pilotStartingCount(0)),
              CancellationScene(
                sequence: task.cards,
                revealedCount: task.cards.length,
                runningCount: int.parse(task.expected),
                onRevealNext: () {},
                showExplanation: !plan.isChallenge || answer != null,
              ),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  IconButton(
                    tooltip: strings.pilotDecrease,
                    onPressed:
                        enabled && session.adaptiveCount > -task.cards.length
                        ? () => vm.adjustAdaptiveCount(-1)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text('${strings.yourCount}: ${session.adaptiveCount}'),
                  IconButton(
                    tooltip: strings.pilotIncrease,
                    onPressed:
                        enabled && session.adaptiveCount < task.cards.length
                        ? () => vm.adjustAdaptiveCount(1)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              FilledButton(
                key: const ValueKey('adaptive-answer'),
                onPressed: enabled
                    ? () => vm.answerAdaptive('${session.adaptiveCount}')
                    : null,
                child: Text(strings.submitCount),
              ),
            ] else
              DecisionScene(
                playerHand: BlackjackHand(task.cards),
                dealerUpCard: task.dealer!,
                availableActions: task.actions,
                enabled: enabled,
                onAction: (action) => vm.answerAdaptive(action.name),
              ),
            if (answer != null)
              Text(
                strings.checkpointReview(label(answer), label(task.expected)),
              ),
          ],
        ),
      ),
    );
  }
}
