/// Short spaced-review flow for due and weak exercises.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../viewmodels/app_state.dart';
import '../../viewmodels/quick_review_view_model.dart';

class QuickReviewScreen extends StatelessWidget {
  const QuickReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          QuickReviewViewModel(appState: context.read<AppState>()),
      child: const _QuickReviewView(),
    );
  }
}

class _QuickReviewView extends StatelessWidget {
  const _QuickReviewView();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final viewModel = context.watch<QuickReviewViewModel>();
    if (viewModel.isEmpty) {
      return _ReviewMessage(
        icon: Icons.event_available_outlined,
        title: strings.quickReviewEmptyTitle,
        body: strings.quickReviewEmptyBody,
      );
    }
    if (viewModel.isComplete) {
      return _ReviewMessage(
        icon: Icons.task_alt_rounded,
        title: strings.quickReviewComplete,
        body: strings.quickReviewResult(
          viewModel.correctAnswers,
          viewModel.exercises.length,
        ),
      );
    }

    final exercise = viewModel.currentExercise;
    return Scaffold(
      appBar: AppBar(title: Text(strings.quickReviewTitle)),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (viewModel.index + 1) / viewModel.exercises.length,
              minHeight: 6,
              color: AppColors.mint,
              backgroundColor: Colors.white10,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                children: [
                  Text(
                    strings.quickReviewProgress(
                      viewModel.index + 1,
                      viewModel.exercises.length,
                    ),
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    exercise.prompt,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),
                  for (
                    var optionIndex = 0;
                    optionIndex < viewModel.currentOptions.length;
                    optionIndex++
                  ) ...[
                    OutlinedButton(
                      onPressed: viewModel.hasAnswered
                          ? null
                          : () => viewModel.answer(optionIndex),
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 17,
                        ),
                        side: BorderSide(
                          color: _optionColor(viewModel, optionIndex),
                        ),
                      ),
                      child: Text(viewModel.currentOptions[optionIndex]),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (viewModel.hasAnswered) ...[
                    const SizedBox(height: 12),
                    Text(
                      viewModel.answerIsCorrect
                          ? strings.correctAnswer
                          : strings.incorrectAnswer,
                      style: TextStyle(
                        color: viewModel.answerIsCorrect
                            ? AppColors.mint
                            : AppColors.danger,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      exercise.explanation,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: viewModel.next,
                      child: Text(strings.next),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _optionColor(QuickReviewViewModel viewModel, int optionIndex) {
    if (!viewModel.hasAnswered) {
      return Colors.white24;
    }
    if (optionIndex == viewModel.currentCorrectIndex) {
      return AppColors.mint;
    }
    if (optionIndex == viewModel.selectedIndex) {
      return AppColors.danger;
    }
    return Colors.white24;
  }
}

class _ReviewMessage extends StatelessWidget {
  const _ReviewMessage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.quickReviewTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(icon, color: AppColors.mint, size: 88),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                body,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () => context.go('/learn'),
                child: Text(strings.backToPath),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
