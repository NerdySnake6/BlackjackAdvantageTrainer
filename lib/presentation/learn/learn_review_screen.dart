/// One repeatable independent task using the same localized Learn scenes.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/blackjack_engine/hand.dart';
import '../../l10n/app_localizations.dart';
import '../../viewmodels/app_state.dart';
import '../../viewmodels/learn_review_view_model.dart';
import '../drill/cancellation_scene.dart';
import 'decision_scene.dart';
import 'foundation_scene.dart';
import 'math_comparison_scene.dart';

class LearnReviewScreen extends StatelessWidget {
  const LearnReviewScreen({super.key, required this.lessonId});
  final String lessonId;
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) => LearnReviewViewModel(
      appState: context.read<AppState>(),
      lesson: context.read<AppState>().catalog.playableLessons.firstWhere(
        (l) => l.id == lessonId,
      ),
    ),
    child: const _ReviewBody(),
  );
}

class _ReviewBody extends StatelessWidget {
  const _ReviewBody();
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LearnReviewViewModel>();
    final session = vm.session;
    final task = session.task;
    final strings = AppLocalizations.of(context);
    final enabled = session.canAnswer && !vm.busy && !vm.incompatible;
    return PopScope(
      canPop: !vm.busy,
      child: Scaffold(
        appBar: AppBar(title: Text(strings.studyReviewTitle)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(vm.lesson.title),
              Text(strings.studyReviewNote),
              if (vm.busy) const LinearProgressIndicator(),
              if (vm.saveFailed)
                Semantics(
                  liveRegion: true,
                  child: Text(strings.pilotSaveFailed),
                ),
              if (vm.incompatible) ...[
                Text(strings.checkpointIncompatible),
                FilledButton(
                  onPressed: vm.busy ? null : vm.restart,
                  child: Text(strings.retryLesson),
                ),
              ] else ...[
                if (task.isMathComparison)
                  MathComparisonScene(
                    task: task,
                    revealed: session.revealed,
                    showExplanation: session.complete,
                    enabled: enabled,
                    canReveal: !vm.busy && !session.complete,
                    onReveal: vm.reveal,
                    onAnswer: vm.answer,
                  )
                else if (task.isHandMission)
                  FoundationScene(
                    task: task,
                    revealed: session.revealed,
                    input: session.input,
                    showExplanation: session.complete,
                    enabled: enabled,
                    onReveal: vm.busy || session.complete ? null : vm.reveal,
                    onAdjust: vm.adjust,
                    onAnswer: vm.answer,
                  )
                else if (task.isCounting) ...[
                  Text(strings.pilotStartingCount(task.initialCount)),
                  IgnorePointer(
                    ignoring: vm.busy || session.complete,
                    child: CancellationScene(
                      sequence: task.cards,
                      revealedCount: session.revealed,
                      chunked: task.chunked,
                      runningCount: task.countAfter(session.revealed),
                      showExplanation: session.complete,
                      onRevealNext: vm.reveal,
                    ),
                  ),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      IconButton(
                        key: const ValueKey('learn-review-minus'),
                        tooltip: strings.pilotDecrease,
                        onPressed: enabled && session.input > task.minimumInput
                            ? () => vm.adjust(-1)
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text('${strings.yourCount}: ${session.input}'),
                      IconButton(
                        key: const ValueKey('learn-review-plus'),
                        tooltip: strings.pilotIncrease,
                        onPressed: enabled && session.input < task.maximumInput
                            ? () => vm.adjust(1)
                            : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  FilledButton(
                    key: const ValueKey('learn-review-answer'),
                    onPressed: enabled
                        ? () => vm.answer('${session.input}')
                        : null,
                    child: Text(strings.submitCount),
                  ),
                ] else ...[
                  if (task.prompt.isNotEmpty) Text(task.prompt),
                  DecisionScene(
                    playerHand: BlackjackHand(task.cards),
                    dealerUpCard: task.dealer!,
                    availableActions: task.availableActions,
                    enabled: enabled,
                    onAction: (a) => vm.answer(a.name),
                  ),
                ],
                if (session.complete) ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      session.correct
                          ? strings.correctAnswer
                          : strings.incorrectAnswer,
                      key: const ValueKey('learn-review-result'),
                    ),
                  ),
                  Text(task.feedback(session.answer!)),
                  if (!session.correct) Text(task.contrast),
                ],
              ],
              TextButton(
                onPressed: vm.busy ? null : () => context.go('/learn'),
                child: Text(strings.backToPath),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
