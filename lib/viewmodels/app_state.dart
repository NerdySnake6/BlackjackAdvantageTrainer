/// Application-level learning progress and feature-access state.
library;

import 'package:flutter/foundation.dart';

import '../core/analytics/analytics_gateway.dart';
import '../core/analytics/crash_reporter_gateway.dart';
import '../core/persistence/progress_repository.dart';
import '../domain/learning/mastery.dart';
import '../domain/learning/models.dart';
import '../domain/purchase/purchase_gateway.dart';

class AppState extends ChangeNotifier {
  factory AppState({
    required CourseCatalog catalog,
    required ProgressSnapshot progress,
    required ProgressRepository progressRepository,
    AnalyticsGateway analytics = const NoOpAnalyticsGateway(),
    CrashReporterGateway crashReporter = const NoOpCrashReporterGateway(),
    PurchaseGateway purchaseGateway = const FakePurchaseGateway(),
    SessionScorer scorer = const SessionScorer(),
    ReviewScheduler reviewScheduler = const ReviewScheduler(),
    DateTime Function()? clock,
  }) {
    return AppState._(
      catalog,
      progress,
      progressRepository,
      ConsentAwareAnalyticsGateway(analytics),
      ConsentAwareCrashReporterGateway(crashReporter),
      purchaseGateway,
      scorer,
      reviewScheduler,
      clock ?? DateTime.now,
    );
  }

  AppState._(
    this.catalog,
    this._progress,
    this._progressRepository,
    this._analytics,
    this._crashReporter,
    this._purchaseGateway,
    this._scorer,
    this._reviewScheduler,
    this._clock,
  );

  final CourseCatalog catalog;
  final ProgressRepository _progressRepository;
  final AnalyticsGateway _analytics;
  final CrashReporterGateway _crashReporter;
  final PurchaseGateway _purchaseGateway;
  final SessionScorer _scorer;
  final ReviewScheduler _reviewScheduler;
  final DateTime Function() _clock;
  ProgressSnapshot _progress;

  ProgressSnapshot get progress => _progress;
  EntitlementState entitlement = EntitlementState.free;

  bool get hasExperienceLevel => _progress.experienceLevel != null;

  bool get hasSeenCountDrillIntro => _progress.hasSeenCountDrillIntro;
  bool get hasSeenTelemetryConsent => _progress.hasSeenTelemetryConsent;

  int get completedLessonCount =>
      catalog.lessons.where((lesson) => isLessonCompleted(lesson.id)).length;

  bool isLessonCompleted(String lessonId) {
    return _scorer.isLessonComplete(_progress.lessonScores[lessonId] ?? 0);
  }

  bool isLessonUnlocked(String lessonId) {
    final lessonIndex = catalog.lessons.indexWhere(
      (item) => item.id == lessonId,
    );
    if (lessonIndex <= 0) {
      return lessonIndex == 0;
    }
    final recommendedStartIndex = _recommendedStartIndex;
    if (lessonIndex <= recommendedStartIndex) {
      return true;
    }
    return isLessonCompleted(catalog.lessons[lessonIndex - 1].id);
  }

  bool isRecommendedStart(String lessonId) {
    return lessonId ==
        (_progress.experienceLevel?.startLessonId ?? catalog.lessons.first.id);
  }

  LessonSessionProgress? sessionFor(String lessonId) =>
      _progress.activeSessions[lessonId];

  List<LessonExercise> reviewExercises({int limit = 10, DateTime? now}) {
    final exerciseById = {
      for (final lesson in catalog.lessons)
        for (final exercise in lesson.exercises) exercise.id: exercise,
    };
    final currentTime = now ?? _clock();
    final candidates =
        _progress.exerciseReviewStates.entries
            .where((entry) => exerciseById.containsKey(entry.key))
            .where(
              (entry) =>
                  entry.value.isDue(currentTime) ||
                  entry.value.successfulReviewStreak < 2,
            )
            .toList()
          ..sort((left, right) {
            final leftDate =
                left.value.nextReviewAt ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final rightDate =
                right.value.nextReviewAt ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return leftDate.compareTo(rightDate);
          });
    return [
      for (final entry in candidates.take(limit)) exerciseById[entry.key]!,
    ];
  }

  Future<void> chooseExperienceLevel(ExperienceLevel level) async {
    _progress = _progress.copyWith(experienceLevel: level);
    notifyListeners();
    await _progressRepository.save(_progress);
    await _analytics.setUserProperty('experience_level', level.name);
    await _analytics.track('experience_level_selected', {
      'experience_level': level.name,
    });
  }

  Future<void> setTelemetryConsent({
    required bool analyticsEnabled,
    required bool crashReportsEnabled,
  }) async {
    const policyVersion = 1;
    final now = _clock();
    _progress = _progress.copyWith(
      hasSeenTelemetryConsent: true,
      analyticsConsent: ConsentState(
        isGranted: analyticsEnabled,
        policyVersion: policyVersion,
        updatedAt: now,
      ),
      crashReportsConsent: ConsentState(
        isGranted: crashReportsEnabled,
        policyVersion: policyVersion,
        updatedAt: now,
      ),
    );
    if (!analyticsEnabled) {
      await _analytics.setUserProperty('experience_level', null);
    }
    await _analytics.setCollectionEnabled(analyticsEnabled);
    if (analyticsEnabled && _progress.experienceLevel != null) {
      await _analytics.setUserProperty(
        'experience_level',
        _progress.experienceLevel!.name,
      );
    }
    await _crashReporter.setCollectionEnabled(crashReportsEnabled);
    notifyListeners();
    await _progressRepository.save(_progress);
  }

  Future<void> markCountDrillIntroSeen() async {
    if (_progress.hasSeenCountDrillIntro) {
      return;
    }
    _progress = _progress.copyWith(hasSeenCountDrillIntro: true);
    notifyListeners();
    await _progressRepository.save(_progress);
  }

  Future<void> initializeEntitlement() async {
    entitlement = await _purchaseGateway.currentEntitlement();
    notifyListeners();
  }

  Future<void> initializeTelemetry() async {
    await _analytics.setCollectionEnabled(_progress.analyticsConsent.isGranted);
    if (_progress.analyticsConsent.isGranted &&
        _progress.experienceLevel != null) {
      await _analytics.setUserProperty(
        'experience_level',
        _progress.experienceLevel!.name,
      );
    }
    await _crashReporter.setCollectionEnabled(
      _progress.crashReportsConsent.isGranted,
    );
  }

  Future<void> trackTrainingEvent(
    String eventName, [
    Map<String, Object?> parameters = const {},
  ]) async {
    await _analytics.track(eventName, parameters);
    final sessionType = switch (eventName) {
      'drill_completed' => 'drill',
      'table_session_completed' => 'table',
      'quick_review_completed' => 'quick_review',
      _ => null,
    };
    if (sessionType != null) {
      await _analytics.track('training_session_completed', {
        ...parameters,
        'session_type': sessionType,
      });
    }
  }

  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
  }) {
    return _crashReporter.recordError(error, stackTrace, fatal: fatal);
  }

  Future<void> saveSession({
    required String lessonId,
    required int nextExerciseIndex,
    required int correctAnswers,
    required int selectedIndex,
    required bool answerWasCorrect,
    required String exerciseId,
  }) async {
    final sessions =
        Map<String, LessonSessionProgress>.of(_progress.activeSessions)
          ..[lessonId] = LessonSessionProgress(
            nextExerciseIndex: nextExerciseIndex,
            correctAnswers: correctAnswers,
            lastSelectedIndex: selectedIndex,
            lastAnswerWasCorrect: answerWasCorrect,
          );
    final reviewStates = _reviewStatesAfterAttempt(
      exerciseId: exerciseId,
      wasCorrect: answerWasCorrect,
    );
    _progress = _progress.copyWith(
      activeSessions: sessions,
      exerciseReviewStates: reviewStates,
    );
    notifyListeners();
    await _progressRepository.save(_progress);
    await _analytics.track('exercise_answered', {
      'lesson_id': lessonId,
      'exercise_id': exerciseId,
      'is_correct': answerWasCorrect,
    });
  }

  Future<void> recordReviewAttempt({
    required String exerciseId,
    required bool wasCorrect,
  }) async {
    _progress = _progress.copyWith(
      exerciseReviewStates: _reviewStatesAfterAttempt(
        exerciseId: exerciseId,
        wasCorrect: wasCorrect,
      ),
    );
    notifyListeners();
    await _progressRepository.save(_progress);
    await _analytics.track('quick_review_answered', {
      'exercise_id': exerciseId,
      'is_correct': wasCorrect,
    });
  }

  Future<double> completeLesson({
    required LessonDefinition lesson,
    required int correctAnswers,
  }) async {
    final score = _scorer.score(
      correctAnswers: correctAnswers,
      totalAnswers: lesson.exercises.length,
    );
    final scores = Map<String, double>.of(_progress.lessonScores);
    final previousScore = scores[lesson.id] ?? 0;
    scores[lesson.id] = score > previousScore ? score : previousScore;

    final sessions = Map<String, LessonSessionProgress>.of(
      _progress.activeSessions,
    )..remove(lesson.id);
    final now = _clock();
    final activityDate = DateTime(now.year, now.month, now.day);
    final streak = _updatedStreak(activityDate);
    final completionBonus =
        previousScore < 0.8 && _scorer.isLessonComplete(score) ? 50 : 0;

    _progress = _progress.copyWith(
      lessonScores: scores,
      activeSessions: sessions,
      xp: _progress.xp + correctAnswers * 10 + completionBonus,
      streakDays: streak,
      lastActivityDate: activityDate,
    );
    notifyListeners();
    await _progressRepository.save(_progress);
    await _analytics.track('lesson_completed', {
      'lesson_id': lesson.id,
      'score_percent': (score * 100).round(),
    });
    await _analytics.track('training_session_completed', {
      'session_type': 'lesson',
      'lesson_id': lesson.id,
      'score_percent': (score * 100).round(),
    });
    return score;
  }

  Future<void> resetProgress() async {
    await _analytics.setUserProperty('experience_level', null);
    await _analytics.setCollectionEnabled(false);
    await _crashReporter.setCollectionEnabled(false);
    await _progressRepository.clear();
    _progress = const ProgressSnapshot();
    notifyListeners();
  }

  int get _recommendedStartIndex {
    final startLessonId =
        _progress.experienceLevel?.startLessonId ?? catalog.lessons.first.id;
    final index = catalog.lessons.indexWhere(
      (lesson) => lesson.id == startLessonId,
    );
    return index < 0 ? 0 : index;
  }

  int _updatedStreak(DateTime activityDate) {
    final previous = _progress.lastActivityDate;
    if (previous == null) {
      return 1;
    }
    final previousDate = DateTime(previous.year, previous.month, previous.day);
    final difference = activityDate.difference(previousDate).inDays;
    if (difference <= 0) {
      return _progress.streakDays;
    }
    if (difference == 1) {
      return _progress.streakDays + 1;
    }
    return 1;
  }

  Map<String, ExerciseReviewState> _reviewStatesAfterAttempt({
    required String exerciseId,
    required bool wasCorrect,
  }) {
    final reviewStates = Map<String, ExerciseReviewState>.of(
      _progress.exerciseReviewStates,
    );
    final previous = reviewStates[exerciseId] ?? const ExerciseReviewState();
    final nextStreak = wasCorrect ? previous.successfulReviewStreak + 1 : 0;
    reviewStates[exerciseId] = ExerciseReviewState(
      attempts: previous.attempts + 1,
      successfulReviewStreak: nextStreak,
      nextReviewAt: _reviewScheduler.nextReview(
        completedAt: _clock(),
        successfulReviews: wasCorrect ? previous.successfulReviewStreak : 0,
        wasCorrect: wasCorrect,
      ),
    );
    return reviewStates;
  }
}
