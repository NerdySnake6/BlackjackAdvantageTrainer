import 'dart:math';

import 'package:blackjack_advantage_trainer/core/persistence/progress_repository.dart';
import 'package:blackjack_advantage_trainer/data/content_repository.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/counting_engine.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:blackjack_advantage_trainer/viewmodels/app_state.dart';
import 'package:blackjack_advantage_trainer/viewmodels/count_drill_view_model.dart';
import 'package:blackjack_advantage_trainer/viewmodels/lesson_view_model.dart';
import 'package:blackjack_advantage_trainer/viewmodels/quick_review_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Quick Review', () {
    test('supports empty sessions', () async {
      final appState = await _appState();

      final viewModel = QuickReviewViewModel(appState: appState);

      expect(viewModel.isEmpty, isTrue);
      expect(viewModel.isComplete, isFalse);
      await viewModel.answer(0);
      viewModel.next();
      expect(viewModel.isComplete, isFalse);
    });

    test(
      'limits a session to ten and records correct and wrong answers',
      () async {
        final catalog = await ContentRepository().loadCatalog();
        final ids = [
          for (final lesson in catalog.lessons)
            for (final exercise in lesson.exercises) exercise.id,
        ];
        final repository = _MemoryProgressRepository();
        final now = DateTime.utc(2026, 9, 2);
        final appState = AppState(
          catalog: catalog,
          progress: ProgressSnapshot(
            exerciseReviewStates: {
              for (final id in ids.take(12))
                id: ExerciseReviewState(nextReviewAt: now),
            },
          ),
          progressRepository: repository,
          clock: () => now,
        );
        final viewModel = QuickReviewViewModel(appState: appState);

        expect(viewModel.exercises, hasLength(10));
        await viewModel.answer(viewModel.currentCorrectIndex);
        expect(viewModel.answerIsCorrect, isTrue);
        expect(viewModel.correctAnswers, 1);
        viewModel.next();

        final wrongIndex =
            (viewModel.currentCorrectIndex + 1) %
            viewModel.currentOptions.length;
        await viewModel.answer(wrongIndex);
        expect(viewModel.answerIsCorrect, isFalse);
        viewModel.next();

        while (!viewModel.isComplete) {
          await viewModel.answer(viewModel.currentCorrectIndex);
          viewModel.next();
        }
        await Future<void>.delayed(Duration.zero);

        expect(viewModel.correctAnswers, 9);
        expect(
          repository
              .snapshot
              .exerciseReviewStates[viewModel.exercises[1].id]!
              .successfulReviewStreak,
          0,
        );
      },
    );
  });

  group('Count drill', () {
    test('deals 52 cards through seven checkpoints and can restart', () {
      final events = <String>[];
      final viewModel = CountDrillViewModel(
        random: Random(17),
        onEvent: (name, _) => events.add(name),
      );
      final mirror = CountingEngine();

      viewModel.start();
      mirror.reveal(viewModel.currentCard!);
      while (viewModel.phase != CountDrillPhase.complete) {
        if (viewModel.phase == CountDrillPhase.running) {
          viewModel.revealNext();
          mirror.reveal(viewModel.currentCard!);
          continue;
        }
        viewModel.changeSubmittedCount(mirror.runningCount);
        viewModel.submitCount();
        expect(viewModel.lastAnswerCorrect, isTrue);
        final cardsSeen = viewModel.cardsSeen;
        viewModel.continueAfterCheckpoint();
        if (viewModel.cardsSeen > cardsSeen) {
          mirror.reveal(viewModel.currentCard!);
        }
      }

      expect(viewModel.cardsSeen, 52);
      expect(viewModel.checkpointNumber, 7);
      expect(mirror.runningCount, 0);
      expect(events.where((event) => event == 'count_check'), hasLength(7));
      expect(events.last, 'drill_completed');

      viewModel.start();
      expect(viewModel.phase, CountDrillPhase.running);
      expect(viewModel.cardsSeen, 1);
      expect(viewModel.checkpointNumber, 0);
    });

    test('reveals the correct count after a wrong checkpoint answer', () {
      final viewModel = CountDrillViewModel(random: Random(2))..start();
      while (viewModel.phase == CountDrillPhase.running) {
        viewModel.revealNext();
      }

      viewModel.changeSubmittedCount(999);
      viewModel.submitCount();

      expect(viewModel.lastAnswerCorrect, isFalse);
      expect(viewModel.revealedCorrectCount, isNot(999));
      final submitted = viewModel.submittedCount;
      viewModel.changeSubmittedCount(-1);
      expect(viewModel.submittedCount, submitted);
    });
  });

  group('Lesson', () {
    test(
      'answer order is deterministic and a saved position resumes',
      () async {
        final catalog = await ContentRepository().loadCatalog();
        final lesson = catalog.lessons.first;
        final progress = ProgressSnapshot(
          activeSessions: {
            lesson.id: const LessonSessionProgress(
              nextExerciseIndex: 2,
              correctAnswers: 1,
            ),
          },
        );
        final first = LessonViewModel(
          appState: await _appState(progress: progress),
          lesson: lesson,
        );
        final second = LessonViewModel(
          appState: await _appState(progress: progress),
          lesson: lesson,
        );

        expect(first.exerciseIndex, 2);
        expect(first.correctAnswers, 1);
        expect(first.currentOptionOrder, second.currentOptionOrder);
      },
    );

    test('failed lesson requires review and can be retried', () async {
      final appState = await _appState();
      final viewModel = LessonViewModel(
        appState: appState,
        lesson: appState.catalog.lessons.first,
      );

      while (!viewModel.isComplete) {
        final wrong =
            (viewModel.currentCorrectIndex + 1) %
            viewModel.currentOptions.length;
        await viewModel.answer(wrong);
        await viewModel.next();
      }

      expect(viewModel.passed, isFalse);
      expect(viewModel.finalScore, 0);
      expect(appState.isLessonCompleted(viewModel.lesson.id), isFalse);
      viewModel.retry();
      expect(viewModel.exerciseIndex, 0);
      expect(viewModel.isComplete, isFalse);
    });

    test('successful repeat completes and unlocks the next lesson', () async {
      final appState = await _appState();
      final viewModel = LessonViewModel(
        appState: appState,
        lesson: appState.catalog.lessons.first,
      );

      while (!viewModel.isComplete) {
        await viewModel.answer(viewModel.currentCorrectIndex);
        await viewModel.next();
      }

      expect(viewModel.passed, isTrue);
      expect(viewModel.finalScore, 1);
      expect(appState.isLessonCompleted(viewModel.lesson.id), isTrue);
      expect(appState.isLessonUnlocked(appState.catalog.lessons[1].id), isTrue);
    });
  });
}

Future<AppState> _appState({
  ProgressSnapshot progress = const ProgressSnapshot(),
}) async {
  return AppState(
    catalog: await ContentRepository().loadCatalog(),
    progress: progress,
    progressRepository: _MemoryProgressRepository(),
  );
}

class _MemoryProgressRepository implements ProgressRepository {
  ProgressSnapshot snapshot = const ProgressSnapshot();

  @override
  Future<void> clear() async => snapshot = const ProgressSnapshot();

  @override
  Future<ProgressSnapshot> load() async => snapshot;

  @override
  Future<void> save(ProgressSnapshot snapshot) async {
    this.snapshot = snapshot;
  }
}
