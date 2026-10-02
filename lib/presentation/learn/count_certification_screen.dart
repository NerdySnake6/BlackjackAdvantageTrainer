/// Full-deck count check with saved checkpoints and no answer hints.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../viewmodels/app_state.dart';
import '../../viewmodels/count_certification_view_model.dart';
import '../widgets/learn_card_view.dart';

class CountCertificationScreen extends StatelessWidget {
  const CountCertificationScreen({super.key});
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) => CountCertificationViewModel(context.read<AppState>()),
    child: const _CountBody(),
  );
}

class _CountBody extends StatelessWidget {
  const _CountBody();
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CountCertificationViewModel>();
    final session = vm.session;
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
      canPop: !session.active && !vm.busy,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && !vm.busy) await leave();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(strings.countCertificationTitle)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(strings.countCertificationIntro),
              if (vm.busy) const LinearProgressIndicator(),
              if (vm.saveFailed)
                Semantics(
                  liveRegion: true,
                  child: Text(strings.pilotSaveFailed),
                ),
              if (vm.incompatible) Text(strings.checkpointIncompatible),
              if (session.passed)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    strings.countCertificationPassed,
                    key: const ValueKey('count-cert-passed'),
                  ),
                )
              else if (session.failed || vm.incompatible) ...[
                Semantics(
                  liveRegion: true,
                  child: Text(
                    strings.countCertificationFailed,
                    key: const ValueKey('count-cert-failed'),
                  ),
                ),
                FilledButton(
                  key: const ValueKey('count-cert-restart'),
                  onPressed: vm.busy ? null : vm.restart,
                  child: Text(strings.retryLesson),
                ),
              ] else ...[
                Text(
                  strings.countCertificationStage(
                    session.level + 1,
                    session.limitSeconds,
                  ),
                ),
                Text(
                  strings.countCertificationTime(
                    (session.elapsedMs / 1000).floor(),
                  ),
                ),
                Text(strings.cardsSeen(session.revealed)),
                if (!session.started)
                  FilledButton(
                    key: const ValueKey('count-cert-begin'),
                    onPressed: vm.busy ? null : vm.begin,
                    child: Text(strings.checkpointBegin),
                  )
                else ...[
                  if (session.revealed > 0)
                    Center(
                      child: LearnCardView(
                        card: session.cards[session.revealed - 1],
                        width: 72,
                      ),
                    ),
                  if (session.needsAnswer) ...[
                    Text(strings.yourCount),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        IconButton(
                          key: const ValueKey('count-cert-minus'),
                          tooltip: strings.pilotDecrease,
                          onPressed: vm.busy || session.input <= -20
                              ? null
                              : () => vm.adjust(-1),
                          icon: const Icon(Icons.remove),
                        ),
                        Text('${session.input}'),
                        IconButton(
                          key: const ValueKey('count-cert-plus'),
                          tooltip: strings.pilotIncrease,
                          onPressed: vm.busy || session.input >= 20
                              ? null
                              : () => vm.adjust(1),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    FilledButton(
                      key: const ValueKey('count-cert-answer'),
                      onPressed: vm.busy ? null : vm.answer,
                      child: Text(strings.submitCount),
                    ),
                  ] else
                    FilledButton(
                      key: const ValueKey('count-cert-reveal'),
                      onPressed: vm.busy ? null : vm.reveal,
                      child: Text(strings.nextCard),
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
