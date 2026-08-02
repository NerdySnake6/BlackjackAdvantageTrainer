/// Interactive, resumable lesson experience.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../viewmodels/app_state.dart';
import '../../viewmodels/lesson_view_model.dart';

class LessonScreen extends StatelessWidget {
  const LessonScreen({required this.lessonId, super.key});

  final String lessonId;

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final lesson = appState.catalog.lessonById(lessonId);
    return ChangeNotifierProvider(
      create: (context) => LessonViewModel(appState: appState, lesson: lesson),
      child: const _LessonView(),
    );
  }
}

class _LessonView extends StatelessWidget {
  const _LessonView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LessonViewModel>();
    final strings = AppLocalizations.of(context);
    if (viewModel.isComplete) {
      return _LessonCompleteView(viewModel: viewModel);
    }

    final exercise = viewModel.currentExercise;
    final progress =
        (viewModel.exerciseIndex + 1) / viewModel.lesson.exercises.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(viewModel.lesson.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: progress,
            backgroundColor: Colors.white10,
            color: AppColors.mint,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${viewModel.exerciseIndex + 1} / ${viewModel.lesson.exercises.length}',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      exercise.prompt,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 28),
                    for (
                      var index = 0;
                      index < exercise.options.length;
                      index++
                    ) ...[
                      _AnswerOption(
                        index: index,
                        label: exercise.options[index],
                        selectedIndex: viewModel.selectedIndex,
                        correctIndex: exercise.correctIndex,
                        onPressed: () => viewModel.answer(index),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
            if (viewModel.hasAnswered)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                decoration: BoxDecoration(
                  color: (viewModel.answerIsCorrect
                      ? AppColors.felt
                      : const Color(0xFF4B2529)),
                  border: Border(
                    top: BorderSide(
                      color: viewModel.answerIsCorrect
                          ? AppColors.mint
                          : AppColors.danger,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      viewModel.answerIsCorrect
                          ? strings.correctAnswer
                          : strings.incorrectAnswer,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      exercise.explanation,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: viewModel.next,
                      child: Text(
                        viewModel.isLastExercise
                            ? strings.finish
                            : strings.next,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.index,
    required this.label,
    required this.selectedIndex,
    required this.correctIndex,
    required this.onPressed,
  });

  final int index;
  final String label;
  final int? selectedIndex;
  final int correctIndex;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final hasAnswered = selectedIndex != null;
    final isCorrect = hasAnswered && index == correctIndex;
    final isWrongSelection =
        hasAnswered && index == selectedIndex && !isCorrect;
    final borderColor = isCorrect
        ? AppColors.mint
        : isWrongSelection
        ? AppColors.danger
        : Colors.white24;

    return OutlinedButton(
      onPressed: hasAnswered ? null : onPressed,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        side: BorderSide(
          color: borderColor,
          width: isCorrect || isWrongSelection ? 2 : 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white,
        backgroundColor: isCorrect
            ? AppColors.mint.withValues(alpha: 0.12)
            : isWrongSelection
            ? AppColors.danger.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.035),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _LessonCompleteView extends StatelessWidget {
  const _LessonCompleteView({required this.viewModel});

  final LessonViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.verified_rounded,
                color: AppColors.mint,
                size: 96,
              ),
              const SizedBox(height: 24),
              Text(
                strings.lessonComplete,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 10),
              Text(
                strings.lessonResult(
                  viewModel.correctAnswers,
                  viewModel.lesson.exercises.length,
                ),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppColors.gold),
              ),
              const SizedBox(height: 10),
              Text(
                strings.lessonCompleteSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 32),
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
