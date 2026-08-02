/// Application-level learning progress and feature-access state.
library;

import 'package:flutter/foundation.dart';

import '../core/analytics/analytics_gateway.dart';
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
    PurchaseGateway purchaseGateway = const FakePurchaseGateway(),
    SessionScorer scorer = const SessionScorer(),
  }) {
    return AppState._(
      catalog,
      progress,
      progressRepository,
      analytics,
      purchaseGateway,
      scorer,
    );
  }

  AppState._(
    this.catalog,
    this._progress,
    this._progressRepository,
    this._analytics,
    this._purchaseGateway,
    this._scorer,
  );

  final CourseCatalog catalog;
  final ProgressRepository _progressRepository;
  final AnalyticsGateway _analytics;
  final PurchaseGateway _purchaseGateway;
  final SessionScorer _scorer;
  ProgressSnapshot _progress;

  ProgressSnapshot get progress => _progress;
  EntitlementState entitlement = EntitlementState.free;

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
    return isLessonCompleted(catalog.lessons[lessonIndex - 1].id);
  }

  LessonSessionProgress? sessionFor(String lessonId) =>
      _progress.activeSessions[lessonId];

  Future<void> initializeEntitlement() async {
    entitlement = await _purchaseGateway.currentEntitlement();
    notifyListeners();
  }

  Future<void> saveSession({
    required String lessonId,
    required int nextExerciseIndex,
    required int correctAnswers,
    required int selectedIndex,
    required bool answerWasCorrect,
  }) async {
    final sessions =
        Map<String, LessonSessionProgress>.of(_progress.activeSessions)
          ..[lessonId] = LessonSessionProgress(
            nextExerciseIndex: nextExerciseIndex,
            correctAnswers: correctAnswers,
            lastSelectedIndex: selectedIndex,
            lastAnswerWasCorrect: answerWasCorrect,
          );
    _progress = _progress.copyWith(activeSessions: sessions);
    notifyListeners();
    await _progressRepository.save(_progress);
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
    final now = DateTime.now();
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
    return score;
  }

  Future<void> resetProgress() async {
    await _progressRepository.clear();
    _progress = const ProgressSnapshot();
    notifyListeners();
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
}
