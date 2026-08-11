/// One-deck Hi-Lo countdown drill.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../viewmodels/app_state.dart';
import '../../viewmodels/count_drill_view_model.dart';
import '../widgets/playing_card_view.dart';

class CountDrillScreen extends StatefulWidget {
  const CountDrillScreen({super.key});

  @override
  State<CountDrillScreen> createState() => _CountDrillScreenState();
}

class _CountDrillScreenState extends State<CountDrillScreen> {
  var _introAttempted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showIntroIfNeeded();
    });
  }

  void _showIntroIfNeeded() {
    if (!mounted || _introAttempted) {
      return;
    }
    final appState = context.read<AppState>();
    if (appState.hasSeenCountDrillIntro) {
      return;
    }
    _introAttempted = true;
    showDialog<void>(
      context: context,
      builder: (context) => _CountDrillIntroDialog(appState: appState),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final appState = context.read<AppState>();
        return CountDrillViewModel(
          onEvent: (eventName, parameters) {
            unawaited(appState.trackTrainingEvent(eventName, parameters));
          },
        );
      },
      child: const _CountDrillView(),
    );
  }
}

class _CountDrillIntroDialog extends StatefulWidget {
  const _CountDrillIntroDialog({required this.appState});

  final AppState appState;

  @override
  State<_CountDrillIntroDialog> createState() => _CountDrillIntroDialogState();
}

class _CountDrillIntroDialogState extends State<_CountDrillIntroDialog> {
  var _knowsRules = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(strings.countDrillIntroTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(strings.countDrillIntroBody),
            const SizedBox(height: 16),
            _HiLoRuleRow(
              label: strings.countDrillIntroLowCards,
              color: AppColors.gold,
            ),
            const SizedBox(height: 8),
            _HiLoRuleRow(
              label: strings.countDrillIntroNeutralCards,
              color: Colors.white70,
            ),
            const SizedBox(height: 8),
            _HiLoRuleRow(
              label: strings.countDrillIntroHighCards,
              color: AppColors.mint,
            ),
            const SizedBox(height: 16),
            Text(
              strings.countDrillIntroDeckNote,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _knowsRules,
              onChanged: (value) {
                setState(() => _knowsRules = value ?? false);
              },
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(strings.countDrillIntroKnown),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () async {
            if (_knowsRules) {
              await widget.appState.markCountDrillIntroSeen();
            }
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Text(strings.countDrillIntroContinue),
        ),
      ],
    );
  }
}

class _HiLoRuleRow extends StatelessWidget {
  const _HiLoRuleRow({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _CountDrillView extends StatelessWidget {
  const _CountDrillView();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final viewModel = context.watch<CountDrillViewModel>();

    return Scaffold(
      appBar: AppBar(title: Text(strings.countdownTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: switch (viewModel.phase) {
            CountDrillPhase.idle => _DrillIntro(viewModel: viewModel),
            CountDrillPhase.complete => _DrillComplete(viewModel: viewModel),
            CountDrillPhase.running ||
            CountDrillPhase.checkpoint => _ActiveDrill(viewModel: viewModel),
          },
        ),
      ),
    );
  }
}

class _DrillIntro extends StatelessWidget {
  const _DrillIntro({required this.viewModel});

  final CountDrillViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.speed_rounded, color: AppColors.mint, size: 84),
        const SizedBox(height: 24),
        Text(
          strings.countdownTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 10),
        Text(
          strings.countdownSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white60),
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: viewModel.start,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(strings.startDrill),
        ),
      ],
    );
  }
}

class _ActiveDrill extends StatelessWidget {
  const _ActiveDrill({required this.viewModel});

  final CountDrillViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final isCheckpoint = viewModel.phase == CountDrillPhase.checkpoint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: viewModel.progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
                backgroundColor: Colors.white10,
                color: AppColors.mint,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              strings.cardsSeen(viewModel.cardsSeen),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const Spacer(),
        if (viewModel.currentCard != null)
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: PlayingCardView(
                key: ValueKey(viewModel.currentCard!.id),
                card: viewModel.currentCard!,
                width: 138,
              ),
            ),
          ),
        const Spacer(),
        if (!isCheckpoint) ...[
          Text(
            strings.revealInstruction,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: viewModel.revealNext,
            child: Text(strings.nextCard),
          ),
        ] else
          _CheckpointControls(viewModel: viewModel),
      ],
    );
  }
}

class _CheckpointControls extends StatelessWidget {
  const _CheckpointControls({required this.viewModel});

  final CountDrillViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final answered = viewModel.lastAnswerCorrect != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.checkpoint,
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              strings.adjustCountInstruction,
              style: const TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  onPressed: answered
                      ? null
                      : () => viewModel.changeSubmittedCount(-1),
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 92,
                  child: Column(
                    children: [
                      Text(
                        strings.yourCount,
                        style: const TextStyle(color: Colors.white54),
                      ),
                      Text(
                        '${viewModel.submittedCount >= 0 ? '+' : ''}${viewModel.submittedCount}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: answered
                      ? null
                      : () => viewModel.changeSubmittedCount(1),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            if (answered) ...[
              const SizedBox(height: 10),
              Text(
                viewModel.lastAnswerCorrect!
                    ? strings.countCorrect
                    : strings.countIncorrect(viewModel.revealedCorrectCount!),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: viewModel.lastAnswerCorrect!
                      ? AppColors.mint
                      : AppColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton(
              onPressed: answered
                  ? viewModel.continueAfterCheckpoint
                  : viewModel.submitCount,
              child: Text(answered ? strings.next : strings.submitCount),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrillComplete extends StatelessWidget {
  const _DrillComplete({required this.viewModel});

  final CountDrillViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle, color: AppColors.mint, size: 92),
        const SizedBox(height: 24),
        Text(
          strings.drillComplete,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 10),
        Text(
          strings.drillCompleteSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white60),
        ),
        const SizedBox(height: 30),
        FilledButton(
          onPressed: viewModel.start,
          child: Text(strings.restartDrill),
        ),
      ],
    );
  }
}
