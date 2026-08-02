/// One-deck Hi-Lo countdown drill.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../viewmodels/count_drill_view_model.dart';
import '../widgets/playing_card_view.dart';

class CountDrillScreen extends StatelessWidget {
  const CountDrillScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CountDrillViewModel(),
      child: const _CountDrillView(),
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
