import 'package:blackjack_advantage_trainer/core/analytics/analytics_gateway.dart';
import 'package:blackjack_advantage_trainer/core/analytics/crash_reporter_gateway.dart';
import 'package:blackjack_advantage_trainer/core/persistence/progress_repository.dart';
import 'package:blackjack_advantage_trainer/data/content_repository.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:blackjack_advantage_trainer/viewmodels/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'telemetry events are blocked until separate consent is granted',
    () async {
      final analytics = _RecordingAnalyticsGateway();
      final crashes = _RecordingCrashReporterGateway();
      final appState = await _appState(analytics: analytics, crashes: crashes);

      await appState.initializeTelemetry();
      await appState.chooseExperienceLevel(ExperienceLevel.beginner);
      expect(analytics.events, isEmpty);
      expect(analytics.enabled, isFalse);
      expect(crashes.enabled, isFalse);
      await appState.recordError(Exception('blocked'), StackTrace.current);
      expect(crashes.errors, isEmpty);

      await appState.setTelemetryConsent(
        analyticsEnabled: true,
        crashReportsEnabled: false,
      );
      await appState.chooseExperienceLevel(ExperienceLevel.basics);

      expect(analytics.enabled, isTrue);
      expect(crashes.enabled, isFalse);
      expect(analytics.events.single.$1, 'experience_level_selected');
      expect(
        analytics.events.single.$2['experience_level'],
        ExperienceLevel.basics.name,
      );

      await appState.trackTrainingEvent('exercise_answered', {
        'exercise_id': 'values-ten-ranks',
        'is_correct': true,
        'answer_text': 'must not leave the device',
        'card_sequence': 'must not leave the device',
      });
      expect(analytics.events.last.$2, {
        'exercise_id': 'values-ten-ranks',
        'is_correct': true,
      });

      await appState.trackTrainingEvent('unapproved_event', {
        'exercise_id': 'values-ten-ranks',
      });
      expect(analytics.events, hasLength(2));

      await appState.setTelemetryConsent(
        analyticsEnabled: true,
        crashReportsEnabled: true,
      );
      await appState.recordError(Exception('allowed'), StackTrace.current);
      expect(crashes.errors, hasLength(1));
      await appState.resetProgress();
      expect(analytics.enabled, isFalse);
      expect(crashes.enabled, isFalse);
      expect(appState.progress.hasSeenTelemetryConsent, isFalse);
    },
  );

  test(
    'review attempts use 1/3 day progression and reset after an error',
    () async {
      final now = DateTime.utc(2026, 8, 2, 12);
      final appState = await _appState(clock: () => now);

      await appState.recordReviewAttempt(
        exerciseId: 'values-ten-ranks',
        wasCorrect: true,
      );
      var state = appState.progress.exerciseReviewStates['values-ten-ranks']!;
      expect(state.attempts, 1);
      expect(state.successfulReviewStreak, 1);
      expect(state.nextReviewAt, now.add(const Duration(days: 1)));

      await appState.recordReviewAttempt(
        exerciseId: 'values-ten-ranks',
        wasCorrect: true,
      );
      state = appState.progress.exerciseReviewStates['values-ten-ranks']!;
      expect(state.successfulReviewStreak, 2);
      expect(state.nextReviewAt, now.add(const Duration(days: 3)));

      await appState.recordReviewAttempt(
        exerciseId: 'values-ten-ranks',
        wasCorrect: false,
      );
      state = appState.progress.exerciseReviewStates['values-ten-ranks']!;
      expect(state.attempts, 3);
      expect(state.successfulReviewStreak, 0);
      expect(state.nextReviewAt, now.add(const Duration(days: 1)));
    },
  );

  test('quick review selects no more than ten due or weak exercises', () async {
    final now = DateTime.utc(2026, 8, 2);
    final catalog = await ContentRepository().loadCatalog();
    final exerciseIds = [
      for (final lesson in catalog.lessons)
        for (final exercise in lesson.exercises) exercise.id,
    ];
    final appState = AppState(
      catalog: catalog,
      progress: ProgressSnapshot(
        exerciseReviewStates: {
          for (final id in exerciseIds.take(12))
            id: ExerciseReviewState(
              attempts: 1,
              successfulReviewStreak: 0,
              nextReviewAt: now,
            ),
        },
      ),
      progressRepository: _MemoryProgressRepository(),
      clock: () => now,
    );

    final review = appState.reviewExercises();

    expect(review, hasLength(10));
    expect(review.map((exercise) => exercise.id).toSet(), hasLength(10));
  });
}

Future<AppState> _appState({
  AnalyticsGateway? analytics,
  CrashReporterGateway? crashes,
  DateTime Function()? clock,
}) async {
  return AppState(
    catalog: await ContentRepository().loadCatalog(),
    progress: const ProgressSnapshot(),
    progressRepository: _MemoryProgressRepository(),
    analytics: analytics ?? const NoOpAnalyticsGateway(),
    crashReporter: crashes ?? const NoOpCrashReporterGateway(),
    clock: clock,
  );
}

class _MemoryProgressRepository implements ProgressRepository {
  ProgressSnapshot snapshot = const ProgressSnapshot();

  @override
  Future<void> clear() async {
    snapshot = const ProgressSnapshot();
  }

  @override
  Future<ProgressSnapshot> load() async => snapshot;

  @override
  Future<void> save(ProgressSnapshot snapshot) async {
    this.snapshot = snapshot;
  }
}

class _RecordingAnalyticsGateway implements AnalyticsGateway {
  bool enabled = false;
  final events = <(String, Map<String, Object?>)>[];

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    this.enabled = enabled;
  }

  @override
  Future<void> track(
    String eventName, [
    Map<String, Object?> parameters = const {},
  ]) async {
    events.add((eventName, parameters));
  }
}

class _RecordingCrashReporterGateway implements CrashReporterGateway {
  bool enabled = false;
  final errors = <Object>[];

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    this.enabled = enabled;
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
  }) async {
    errors.add(error);
  }
}
