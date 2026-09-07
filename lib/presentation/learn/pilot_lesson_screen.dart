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
import 'adaptive_practice_card.dart';
import 'pilot_performance_summary.dart';
import 'foundation_scene.dart';

class PilotLessonScreen extends StatelessWidget {
  const PilotLessonScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      key: ValueKey(lessonId),
      create: (context) {
        final appState = context.read<AppState>();
        return PilotLessonViewModel(
          appState: appState,
          lesson: appState.catalog.playableLessons.firstWhere(
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
        bottomNavigationBar: vm.saveFailed
            ? SafeArea(
                top: false,
                child: Semantics(
                  liveRegion: true,
                  child: ConstrainedBox(
                    key: const ValueKey('pilot-save-error'),
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.25,
                    ),
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: Text(
                          strings.pilotSaveFailed,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : null,
        body: SafeArea(
          child: ListView(
            key: ValueKey('${session.phase.name}-${session.index}'),
            primary: false,
            padding: const EdgeInsets.all(16),
            children: [
              if (vm.busy) const LinearProgressIndicator(),
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
                if (context.read<AppState>().sessionFor(vm.lesson.id) != null)
                  TextButton(
                    key: const ValueKey('foundation-legacy-resume'),
                    onPressed: vm.busy
                        ? null
                        : () => context.push('/legacy-lesson/${vm.lesson.id}'),
                    child: Text(strings.foundationLegacyResume),
                  ),
              ] else if (session.phase == DecisionLessonPhase.result) ...[
                Text(
                  session.passed
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
                PilotPerformanceSummary(lessonId: vm.lesson.id),
                const SizedBox(height: 16),
                Text(strings.pilotResultNote),
                if (context.read<AppState>().catalog.pilotLessons.any(
                      (l) => l.id == vm.lesson.id,
                    ) &&
                    context.read<AppState>().isLessonCompleted(vm.lesson.id))
                  FilledButton.tonal(
                    key: const ValueKey('pilot-checkpoint'),
                    onPressed: vm.busy
                        ? null
                        : () => context.push('/checkpoint/${vm.lesson.id}'),
                    child: Text(strings.checkpointTitle),
                  ),
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
                Text('${session.taskNumber}/${session.taskCount}'),
                const SizedBox(height: 12),
                if (task.isHandMission) ...[
                  FoundationScene(
                    task: task,
                    revealed: session.revealed,
                    input: session.countInput,
                    showExplanation: showExplanation,
                    enabled: canAnswer,
                    onReveal:
                        !vm.busy &&
                            session.phase == DecisionLessonPhase.decision
                        ? vm.reveal
                        : null,
                    onAdjust: vm.adjustCount,
                    onAnswer: vm.answer,
                  ),
                ] else if (task.isCounting) ...[
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
                  if (!feedback || !session.corrected)
                    Text(
                      session.revealed < task.cards.length
                          ? strings.pilotRevealBeforeCount
                          : strings.adjustCountInstruction,
                    ),
                  Wrap(
                    spacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      IconButton(
                        tooltip: strings.pilotDecrease,
                        onPressed:
                            canAnswer &&
                                session.countInput >
                                    task.initialCount - task.cards.length
                            ? () => vm.adjustCount(-1)
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text('${strings.yourCount}: ${session.countInput}'),
                      IconButton(
                        tooltip: strings.pilotIncrease,
                        onPressed:
                            canAnswer &&
                                session.countInput <
                                    task.initialCount + task.cards.length
                            ? () => vm.adjustCount(1)
                            : null,
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
                ] else ...[
                  if (task.prompt.isNotEmpty) Text(task.prompt),
                  DecisionScene(
                    playerHand: BlackjackHand(task.cards),
                    dealerUpCard: task.dealer!,
                    availableActions: task.availableActions,
                    enabled: canAnswer,
                    onAction: (action) => vm.answer(action.name),
                  ),
                  if (task.prompt.isNotEmpty && session.corrected)
                    FoundationActionResult(task: task),
                ],
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
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      session.firstAnswer == task.expected
                          ? strings.correctAnswer
                          : session.corrected
                          ? strings.pilotCorrected
                          : strings.incorrectAnswer,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Text(
                    strings.pilotSelected(
                      task.usesActions
                          ? actionLabel(
                              strings,
                              PlayerAction.values.byName(session.firstAnswer!),
                            )
                          : foundationAnswerLabel(
                              strings,
                              session.firstAnswer!,
                            ),
                    ),
                  ),
                  Text(task.feedback(session.firstAnswer!)),
                  if (session.firstAnswer != task.expected) ...[
                    const SizedBox(height: 12),
                    Text(task.contrast),
                  ],
                  if (!session.corrected) Text(strings.pilotCorrectTask),
                  const AdaptivePracticeCard(),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const ValueKey('pilot-next'),
                    onPressed: !vm.busy && session.corrected ? vm.next : null,
                    child: Text(
                      session.isLastTask
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
