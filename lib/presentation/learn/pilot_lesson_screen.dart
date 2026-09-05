/// Playable pilot lessons, with the same two scenes across both locales.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/blackjack_engine/game_rules.dart';
import '../../domain/blackjack_engine/hand.dart';
import '../../domain/learning/decision_lesson.dart';
import '../../l10n/app_localizations.dart';
import '../../viewmodels/app_state.dart';
import '../../viewmodels/pilot_lesson_view_model.dart';
import '../drill/cancellation_scene.dart';
import '../table/table_formatters.dart';
import 'decision_scene.dart';

class PilotLessonScreen extends StatelessWidget {
  const PilotLessonScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final appState = context.read<AppState>();
        return PilotLessonViewModel(
          appState: appState,
          lesson: appState.catalog.pilotLessons.firstWhere(
            (lesson) => lesson.id == lessonId,
          ),
        );
      },
      child: const _PilotBody(),
    );
  }
}

class _PilotBody extends StatelessWidget {
  const _PilotBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PilotLessonViewModel>();
    final session = vm.session;
    final task = session.current;
    final strings = AppLocalizations.of(context);
    final feedback = session.phase == DecisionLessonPhase.coaching;
    final showExplanation = session.isWarmup || session.hintUsed || feedback;
    final canAnswer = session.canAnswer && !vm.busy;

    return PopScope(
      canPop: !vm.busy,
      child: Scaffold(
        appBar: AppBar(title: Text(vm.lesson.title)),
        body: SafeArea(
          child: ListView(
            key: ValueKey('${session.phase.name}-${session.index}'),
            primary: false,
            padding: const EdgeInsets.all(16),
            children: [
              if (vm.busy) const LinearProgressIndicator(),
              if (vm.saveFailed)
                Text(
                  strings.pilotSaveFailed,
                  key: const ValueKey('pilot-save-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (vm.incompatibleSave) ...[
                Text(strings.pilotIncompatible),
                FilledButton(
                  onPressed: vm.busy ? null : vm.restart,
                  child: Text(strings.retryLesson),
                ),
              ] else if (session.phase == DecisionLessonPhase.theory) ...[
                Text(
                  vm.lesson.theory,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  key: const ValueKey('pilot-begin'),
                  onPressed: vm.busy ? null : vm.begin,
                  child: Text(strings.startLesson),
                ),
              ] else if (session.phase == DecisionLessonPhase.result) ...[
                Text(
                  session.score >= 0.8
                      ? strings.lessonComplete
                      : strings.lessonNeedsReview,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  strings.lessonResult(
                    session.correctAnswers,
                    session.evaluatedAnswers,
                  ),
                ),
                Text(strings.pilotUnassisted(session.unassistedAnswers)),
                Text(strings.pilotStars(session.stars)),
                Text(strings.pilotReward(session.awardedXp ?? 0)),
                const SizedBox(height: 16),
                Text(strings.pilotResultNote),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: vm.busy ? null : () => context.go('/learn'),
                  child: Text(strings.backToPath),
                ),
                OutlinedButton(
                  key: const ValueKey('pilot-restart'),
                  onPressed: vm.busy ? null : vm.restart,
                  child: Text(strings.retryLesson),
                ),
              ] else ...[
                Text(
                  session.isWarmup
                      ? strings.pilotWarmup
                      : session.isIndependent
                      ? strings.pilotIndependent
                      : strings.pilotPractice,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  session.isWarmup
                      ? '${session.index + 1}/2'
                      : '${session.index - 1}/10',
                ),
                const SizedBox(height: 12),
                if (task.isCounting) ...[
                  Text(strings.pilotStartingCount(task.initialCount)),
                  IgnorePointer(
                    ignoring: vm.busy,
                    child: CancellationScene(
                      sequence: task.cards,
                      revealedCount: session.revealed,
                      runningCount: task.countAfter(session.revealed),
                      showExplanation: showExplanation,
                      onRevealNext: vm.reveal,
                    ),
                  ),
                  Text(strings.adjustCountInstruction),
                  Wrap(
                    spacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      IconButton(
                        tooltip: strings.pilotDecrease,
                        onPressed: canAnswer ? () => vm.adjustCount(-1) : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text('${strings.yourCount}: ${session.countInput}'),
                      IconButton(
                        tooltip: strings.pilotIncrease,
                        onPressed: canAnswer ? () => vm.adjustCount(1) : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  FilledButton(
                    key: const ValueKey('pilot-count-answer'),
                    onPressed: canAnswer
                        ? () => vm.answer(session.countInput.toString())
                        : null,
                    child: Text(strings.submitCount),
                  ),
                ] else
                  DecisionScene(
                    playerHand: BlackjackHand(task.cards),
                    dealerUpCard: task.dealer!,
                    availableActions: task.availableActions,
                    enabled: canAnswer,
                    onAction: (action) => vm.answer(action.name),
                  ),
                if (!feedback) ...[
                  if (session.isWarmup || session.hintUsed)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(task.explanation),
                    ),
                  if (!session.isWarmup &&
                      !session.isIndependent &&
                      !session.hintUsed)
                    TextButton(
                      key: const ValueKey('pilot-hint'),
                      onPressed: vm.busy ? null : vm.hint,
                      child: Text(strings.pilotHint),
                    ),
                ],
                if (feedback) ...[
                  const SizedBox(height: 16),
                  Text(
                    session.firstAnswer == task.expected
                        ? strings.correctAnswer
                        : strings.incorrectAnswer,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    strings.pilotSelected(
                      task.isCounting
                          ? session.firstAnswer!
                          : actionLabel(
                              strings,
                              PlayerAction.values.byName(session.firstAnswer!),
                            ),
                    ),
                  ),
                  Text(task.feedback(session.firstAnswer!)),
                  if (session.firstAnswer != task.expected) ...[
                    const SizedBox(height: 12),
                    Text(task.contrast),
                  ],
                  if (!session.corrected) Text(strings.pilotCorrectTask),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const ValueKey('pilot-next'),
                    onPressed: !vm.busy && session.corrected ? vm.next : null,
                    child: Text(
                      session.index == 11
                          ? strings.finish
                          : strings.continueAction,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
