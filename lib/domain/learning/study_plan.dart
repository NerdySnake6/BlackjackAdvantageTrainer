/// A small daily suggestion that never locks the rest of Learn or Table.
library;

import 'learn_review.dart';
import 'models.dart';
import 'pilot_lesson.dart';

class StudyPlan {
  const StudyPlan({this.reviewLesson, this.nextLesson, this.challengeLesson});
  final PilotLesson? reviewLesson;
  final PilotLesson? nextLesson;
  final PilotLesson? challengeLesson;
  static const lessonOrder = [
    'quick-start',
    'card-values',
    'hard-and-soft',
    'player-actions',
    'first-strategy',
    'dealer-upcard',
    'hard-doubles',
    'hard-12',
    'hard-13-16',
    'soft-13-17',
    'soft-18',
    'pairs-core',
    'pairs-das',
    'unavailable-actions-surrender',
    'mixed-basic-strategy',
    'house-edge-reality',
    'expected-value',
    'variance',
    'advantage-play-conditions',
    'hi-lo-intro',
    'hi-lo-cancellation',
    'hi-lo-chunks',
    'running-count-continuity',
    'running-count-checkpoints',
    'running-count-speed',
  ];
  factory StudyPlan.select(
    CourseCatalog catalog,
    ProgressSnapshot progress,
    DateTime now,
  ) {
    final byId = {for (final l in catalog.playableLessons) l.id: l};
    PilotLesson? next;
    PilotLesson? review;
    PilotLesson? overdue;
    PilotLesson? challenge;
    DateTime? oldest;
    final start = lessonOrder.indexOf(
      progress.experienceLevel?.startLessonId ?? 'quick-start',
    );
    for (final id in lessonOrder) {
      final lesson = byId[id];
      if (lesson == null) continue;
      final active = progress.learnReviewSessions[id];
      if (active != null && (progress.lessonScores[id] ?? 0) >= 0.8) {
        try {
          if (!LearnReviewSession.restore(lesson, active).complete) {
            review ??= lesson;
          }
        } on FormatException {
          // Preserve invalid records; the review screen offers explicit restart.
        }
      }
      if ((progress.lessonScores[id] ?? 0) >= 0.8) {
        challenge = lesson;
        final raw = progress.learnReviews[id];
        if (raw != null) {
          try {
            final due = LearnReviewSchedule.fromJson(raw).dueAt;
            if (!due.isAfter(now) && (oldest == null || due.isBefore(oldest))) {
              oldest = due;
              // An unfinished review takes precedence over the due queue.
              overdue = lesson;
            }
          } on FormatException {
            // A broken date does not create a false overdue task.
          }
        }
      } else if (next == null && lessonOrder.indexOf(id) >= start) {
        next = lesson;
      }
    }
    return StudyPlan(
      reviewLesson: review ?? overdue,
      nextLesson: next,
      challengeLesson: challenge,
    );
  }
}
