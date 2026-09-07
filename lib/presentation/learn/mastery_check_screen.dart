/// A held-out check, deliberately separate from repeatable lesson practice.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/blackjack_engine/game_rules.dart';
import '../../domain/blackjack_engine/hand.dart';
import '../../l10n/app_localizations.dart';
import '../../viewmodels/app_state.dart';
import '../../viewmodels/mastery_check_view_model.dart';
import '../drill/cancellation_scene.dart';
import '../table/table_formatters.dart';
import 'decision_scene.dart';

class MasteryCheckScreen extends StatelessWidget {
  const MasteryCheckScreen({super.key, required this.lessonId});
  final String lessonId;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) => MasteryCheckViewModel(
      appState: context.read<AppState>(),
      lessonId: lessonId,
    ),
    child: const _CheckBody(),
  );
}

class _CheckBody extends StatelessWidget {
  const _CheckBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MasteryCheckViewModel>();
    final session = vm.session;
    final task = session.current;
    final strings = AppLocalizations.of(context);
    final lesson = vm.appState.catalog.pilotLessons.firstWhere(
      (l) => l.id == vm.lessonId,
    );
    final enabled = session.canAnswer && !vm.busy;
    String answerLabel(String value) => task.isCounting
        ? value
        : actionLabel(strings, PlayerAction.values.byName(value));

    return PopScope(
      canPop: !vm.busy,
      child: Scaffold(
        appBar: AppBar(title: Text(strings.checkpointTitle)),
        body: SafeArea(
          child: ListView(
            key: ValueKey(
              'check-${vm.started}-${session.form}-${session.index}',
            ),
            padding: const EdgeInsets.all(16),
            children: [
              if (vm.busy) const LinearProgressIndicator(),
              if (vm.saveFailed)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    strings.pilotSaveFailed,
                    key: const ValueKey('check-save-error'),
                  ),
                ),
              if (vm.incompatibleSave)
                Text(strings.checkpointIncompatible)
              else if (!vm.started) ...[
                Text(
                  lesson.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(strings.checkpointIntro),
                if (vm.lessonId == 'soft-18') Text(strings.checkpointSoftScope),
                FilledButton(
                  key: const ValueKey('check-begin'),
                  onPressed: vm.busy ? null : vm.begin,
                  child: Text(strings.checkpointBegin),
                ),
              ] else if (session.complete) ...[
                Semantics(
                  liveRegion: true,
                  child: Text(
                    strings.pilotMasteryStatus((session.score * 100).round()),
                    key: const ValueKey('check-result'),
                  ),
                ),
                Text(
                  session.passed
                      ? strings.pilotMastered
                      : strings.pilotMasteryPending,
                ),
                Text(lesson.theory),
                for (var i = 0; i < session.tasks.length; i++)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${i + 1}. ${session.tasks[i].cards.map((c) => c.rank.label).join(' + ')}',
                          ),
                          if (!task.isCounting)
                            Text(
                              '${strings.dealer}: ${session.tasks[i].dealer!.rank.label}',
                            ),
                          Text(
                            strings.checkpointReview(
                              answerLabel(session.answers[i]),
                              answerLabel(session.tasks[i].expected),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (vm.hasNextForm)
                  FilledButton(
                    key: const ValueKey('check-next-form'),
                    onPressed: vm.busy ? null : vm.nextForm,
                    child: Text(strings.checkpointNextForm),
                  )
                else if (!session.passed)
                  Text(strings.checkpointExhausted),
              ] else ...[
                Text('${session.index + 1}/${session.tasks.length}'),
                if (task.isCounting) ...[
                  Text(strings.pilotStartingCount(0)),
                  IgnorePointer(
                    ignoring: vm.busy,
                    child: CancellationScene(
                      sequence: task.cards,
                      revealedCount: session.revealed,
                      runningCount: 0,
                      showExplanation: false,
                      onRevealNext: vm.reveal,
                    ),
                  ),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      IconButton(
                        tooltip: strings.pilotDecrease,
                        onPressed: enabled && session.count > -task.cards.length
                            ? () => vm.adjustCount(-1)
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text('${strings.yourCount}: ${session.count}'),
                      IconButton(
                        tooltip: strings.pilotIncrease,
                        onPressed: enabled && session.count < task.cards.length
                            ? () => vm.adjustCount(1)
                            : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  FilledButton(
                    key: const ValueKey('check-answer'),
                    onPressed: enabled
                        ? () => vm.answer('${session.count}')
                        : null,
                    child: Text(strings.submitCount),
                  ),
                ] else
                  DecisionScene(
                    playerHand: BlackjackHand(task.cards),
                    dealerUpCard: task.dealer!,
                    availableActions: task.actions,
                    enabled: enabled,
                    onAction: (action) => vm.answer(action.name),
                  ),
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
