import 'package:blackjack_advantage_trainer/core/persistence/progress_repository.dart';
import 'package:blackjack_advantage_trainer/data/content_repository.dart';
import 'package:blackjack_advantage_trainer/domain/learning/decision_lesson.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:blackjack_advantage_trainer/viewmodels/app_state.dart';
import 'package:blackjack_advantage_trainer/viewmodels/pilot_lesson_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final catalogs = <String, CourseCatalog>{};
  setUpAll(() async {
    for (final locale in ['en', 'ru']) {
      catalogs[locale] = await ContentRepository().loadCatalog(
        localeCode: locale,
      );
    }
  });
  for (final id in [
    'quick-start',
    'card-values',
    'hard-and-soft',
    'player-actions',
  ]) {
    test(
      '$id: legacy completion, reviews and rewards survive new lesson and locale change',
      () async {
        const old = LessonSessionProgress(
          nextExerciseIndex: 2,
          correctAnswers: 1,
        );
        final repository = _MemoryRepository();
        final app = AppState(
          catalog: catalogs['en']!,
          progress: ProgressSnapshot(
            xp: 700,
            streakDays: 9,
            lastActivityDate: DateTime(2026, 9, 8),
            languageCode: 'en',
            experienceLevel: ExperienceLevel.experienced,
            hasSeenTelemetryConsent: true,
            analyticsConsent: const ConsentState(isGranted: true),
            lessonScores: {id: 1},
            activeSessions: {id: old},
            exerciseReviewStates: {
              'quick-goal': ExerciseReviewState(successfulReviewStreak: 2),
            },
          ),
          progressRepository: repository,
          clock: () => DateTime(2026, 9, 8),
        );
        addTearDown(app.dispose);
        final lesson = catalogs['en']!.foundationLessons.firstWhere(
          (l) => l.id == id,
        );
        final translated = catalogs['ru']!.foundationLessons.firstWhere(
          (l) => l.id == id,
        );
        final vm = PilotLessonViewModel(appState: app, lesson: lesson);
        addTearDown(vm.dispose);
        await vm.begin();
        for (final task in lesson.scenarios) {
          if (task.requiresReveal) {
            for (final _ in task.cards) {
              await vm.reveal();
            }
          }
          final resumed = DecisionLessonSession.restore(
            translated,
            app.progress.pilotSessions[id]!,
          );
          expect(resumed.index, vm.session.index);
          expect(resumed.revealed, vm.session.revealed);
          await vm.answer(task.expected);
          await vm.next();
        }
        expect(app.progress.xp, 800); // No second first-completion bonus.
        expect(app.progress.streakDays, 9);
        expect(app.progress.lessonScores[id], 1);
        expect(app.sessionFor(id)?.toJson(), old.toJson());
        expect(
          app
              .progress
              .exerciseReviewStates['quick-goal']!
              .successfulReviewStreak,
          2,
        );
        expect(app.progress.analyticsConsent.isGranted, isTrue);
        await app.savePilotSession(vm.session);
        expect(app.progress.xp, 800);
        await vm.restart();
        expect(app.previousPilotPerformance(id)?.correct, 10);
        expect(app.progress.xp, 800);
        expect(app.latestPilotPerformance(id), isNotNull);
      },
    );
  }
}

class _MemoryRepository implements ProgressRepository {
  ProgressSnapshot snapshot = const ProgressSnapshot();
  @override
  Future<void> clear() async {
    snapshot = const ProgressSnapshot();
  }

  @override
  Future<ProgressSnapshot> load() async => snapshot;
  @override
  Future<void> save(ProgressSnapshot value) async {
    snapshot = value;
  }
}
