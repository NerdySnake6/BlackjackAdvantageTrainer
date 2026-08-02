import 'dart:convert';

import 'package:blackjack_advantage_trainer/domain/learning/mastery.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('learning policies', () {
    test('lesson completion requires 80 percent', () {
      const scorer = SessionScorer();

      expect(
        scorer.isLessonComplete(
          scorer.score(correctAnswers: 8, totalAnswers: 10),
        ),
        isTrue,
      );
      expect(
        scorer.isLessonComplete(
          scorer.score(correctAnswers: 7, totalAnswers: 10),
        ),
        isFalse,
      );
    });

    test('review intervals follow 1, 3, 7, 14, and 30 days', () {
      const scheduler = ReviewScheduler();
      final completedAt = DateTime.utc(2026, 8, 2);

      expect(
        scheduler.nextReview(
          completedAt: completedAt,
          successfulReviews: 0,
          wasCorrect: true,
        ),
        DateTime.utc(2026, 8, 3),
      );
      expect(
        scheduler.nextReview(
          completedAt: completedAt,
          successfulReviews: 4,
          wasCorrect: true,
        ),
        DateTime.utc(2026, 9, 1),
      );
      expect(
        scheduler.nextReview(
          completedAt: completedAt,
          successfulReviews: 4,
          wasCorrect: false,
        ),
        DateTime.utc(2026, 8, 3),
      );
    });

    test('progress JSON preserves locale-independent lesson IDs', () {
      final snapshot = ProgressSnapshot(
        lessonScores: const {'quick-start': 0.875},
        activeSessions: const {
          'card-values': LessonSessionProgress(
            nextExerciseIndex: 3,
            correctAnswers: 2,
          ),
        },
        experienceLevel: ExperienceLevel.experienced,
        hasSeenCountDrillIntro: true,
        xp: 140,
        streakDays: 2,
        lastActivityDate: DateTime.utc(2026, 8, 2),
      );

      final decoded = ProgressSnapshot.fromJson(
        jsonDecode(jsonEncode(snapshot.toJson()))! as Map<String, Object?>,
      );

      expect(decoded.lessonScores['quick-start'], 0.875);
      expect(decoded.activeSessions['card-values']!.nextExerciseIndex, 3);
      expect(decoded.experienceLevel, ExperienceLevel.experienced);
      expect(decoded.hasSeenCountDrillIntro, isTrue);
      expect(decoded.xp, 140);
      expect(decoded.streakDays, 2);
    });
  });
}
