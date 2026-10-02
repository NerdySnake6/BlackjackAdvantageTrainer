/// Optional weekly practice on a shared sequence of authored cards.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../viewmodels/app_state.dart';
import '../../viewmodels/combined_practice_view_model.dart';
import '../table/table_formatters.dart';
import '../widgets/learn_card_view.dart';

class CombinedPracticeScreen extends StatelessWidget {
  const CombinedPracticeScreen({super.key});
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) => CombinedPracticeViewModel(context.read<AppState>()),
    child: const _PracticeBody(),
  );
}

class _PracticeBody extends StatelessWidget {
  const _PracticeBody();
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CombinedPracticeViewModel>();
    final s = vm.session;
    final strings = AppLocalizations.of(context);
    Future<void> leave() async {
      await vm.pause();
      if (vm.saveFailed) {
        vm.resume();
      } else if (context.mounted) {
        context.go('/learn');
      }
    }

    return PopScope(
      canPop: !s.active && !vm.busy,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && !vm.busy) await leave();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(strings.combinedTitle)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(strings.combinedIntro),
              Text(strings.combinedWeek(s.week)),
              if (vm.busy) const LinearProgressIndicator(),
              if (vm.saveFailed)
                Semantics(
                  liveRegion: true,
                  child: Text(strings.pilotSaveFailed),
                ),
              if (vm.incompatible) ...[
                Text(strings.checkpointIncompatible),
                FilledButton(
                  key: const ValueKey('combined-restart'),
                  onPressed: vm.busy ? null : () => vm.restart(),
                  child: Text(strings.retryLesson),
                ),
              ] else if (!s.started) ...[
                SwitchListTile(
                  key: const ValueKey('combined-timer'),
                  title: Text(strings.combinedTimer),
                  value: s.timed,
                  onChanged: vm.busy
                      ? null
                      : (value) => vm.restart(timed: value),
                ),
                FilledButton(
                  key: const ValueKey('combined-begin'),
                  onPressed: vm.busy ? null : vm.begin,
                  child: Text(strings.checkpointBegin),
                ),
              ] else if (s.complete) ...[
                Semantics(
                  liveRegion: true,
                  child: Text(
                    strings.combinedResult(
                      s.strategyCorrect,
                      s.countCorrect,
                      s.bothCorrect,
                      s.tasks.length,
                    ),
                    key: const ValueKey('combined-result'),
                  ),
                ),
                Text(
                  strings.combinedFeedback(
                    actionLabel(
                      strings,
                      s.task.availableActions.firstWhere(
                        (a) => a.name == s.task.expected,
                      ),
                    ),
                    s.expectedCount(s.index - 1),
                  ),
                ),
                Text(s.task.mistakes[s.decisions.last] ?? s.task.explanation),
                Text(s.task.contrast),
                if (s.timed)
                  Text(strings.combinedTime((s.elapsedMs / 1000).ceil())),
                FilledButton(
                  key: const ValueKey('combined-repeat'),
                  onPressed: vm.busy ? null : () => vm.restart(),
                  child: Text(strings.retryLesson),
                ),
              ] else if (s.feedback) ...[
                Semantics(
                  liveRegion: true,
                  child: Text(
                    strings.combinedFeedback(
                      actionLabel(
                        strings,
                        s.task.availableActions.firstWhere(
                          (a) => a.name == s.task.expected,
                        ),
                      ),
                      s.expectedCount(s.index - 1),
                    ),
                  ),
                ),
                Text(s.task.mistakes[s.decision] ?? s.task.explanation),
                Text(s.task.contrast),
                Text(strings.combinedCarry),
                FilledButton(
                  key: const ValueKey('combined-next'),
                  onPressed: vm.busy ? null : vm.next,
                  child: Text(strings.next),
                ),
              ] else ...[
                Text(strings.combinedStep(s.index + 1, s.tasks.length)),
                Text(strings.cardsSeen(s.revealed)),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final card in s.cards.take(s.revealed))
                      LearnCardView(card: card, width: 60),
                  ],
                ),
                if (s.revealed < s.cards.length)
                  FilledButton(
                    key: const ValueKey('combined-reveal'),
                    onPressed: vm.busy ? null : vm.reveal,
                    child: Text(strings.nextCard),
                  )
                else if (s.decision == null) ...[
                  Text(strings.combinedDecision),
                  if (s.task.prompt.isNotEmpty) Text(s.task.prompt),
                  Text(strings.combinedDealer(s.task.dealer!.rank.label)),
                  for (final action in s.task.availableActions)
                    FilledButton(
                      key: ValueKey('combined-action-${action.name}'),
                      onPressed: vm.busy ? null : () => vm.choose(action.name),
                      child: Text(actionLabel(strings, action)),
                    ),
                ] else ...[
                  Text(strings.yourCount),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      IconButton(
                        key: const ValueKey('combined-minus'),
                        tooltip: strings.pilotDecrease,
                        onPressed: vm.busy || s.input <= -s.bound
                            ? null
                            : () => vm.adjust(-1),
                        icon: const Icon(Icons.remove),
                      ),
                      Text('${s.input}'),
                      IconButton(
                        key: const ValueKey('combined-plus'),
                        tooltip: strings.pilotIncrease,
                        onPressed: vm.busy || s.input >= s.bound
                            ? null
                            : () => vm.adjust(1),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  FilledButton(
                    key: const ValueKey('combined-answer'),
                    onPressed: vm.busy ? null : vm.answer,
                    child: Text(strings.submitCount),
                  ),
                ],
              ],
              TextButton(
                onPressed: vm.busy ? null : leave,
                child: Text(strings.backToPath),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
