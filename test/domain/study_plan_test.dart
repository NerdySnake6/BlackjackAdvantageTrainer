import 'dart:convert';
import 'dart:io';

import 'package:blackjack_advantage_trainer/domain/learning/learn_review.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:blackjack_advantage_trainer/domain/learning/study_plan.dart';
import 'package:flutter_test/flutter_test.dart';

CourseCatalog course(String locale) => CourseCatalog.fromJson({
  ...jsonDecode(File('assets/content/$locale/lessons.json').readAsStringSync())
      as Map<String, Object?>,
  for (final pair in [
    ('pilotLessons', 'pilot_lessons'),
    ('foundationLessons', 'foundation_lessons'),
    ('strategyLessons', 'strategy_lessons'),
    ('mathLessons', 'math_lessons'),
    ('countLessons', 'count_lessons'),
  ])
    pair.$1: jsonDecode(
      File('assets/content/$locale/${pair.$2}.json').readAsStringSync(),
    ),
});

void main() {
  final now = DateTime.utc(2026, 10, 2);
  final catalog = course('en');
  test(
    'ordered next lesson respects experience without locking the catalog',
    () {
      expect(
        StudyPlan.select(catalog, const ProgressSnapshot(), now).nextLesson!.id,
        'quick-start',
      );
      expect(
        StudyPlan.select(
          catalog,
          const ProgressSnapshot(experienceLevel: ExperienceLevel.experienced),
          now,
        ).nextLesson!.id,
        'first-strategy',
      );
      final all = ProgressSnapshot(
        lessonScores: {for (final id in StudyPlan.lessonOrder) id: 0.8},
      );
      expect(StudyPlan.select(catalog, all, now).nextLesson, isNull);
      expect(
        StudyPlan.select(catalog, all, now).challengeLesson!.id,
        'running-count-speed',
      );
      expect(
        StudyPlan.lessonOrder.toSet(),
        catalog.playableLessons.map((l) => l.id).toSet(),
      );
    },
  );
  test(
    'oldest due review wins; active saved review wins over the due queue',
    () {
      final lesson = catalog.strategyLessons.first;
      final progress = ProgressSnapshot(
        lessonScores: const {'first-strategy': 0.8, 'dealer-upcard': 0.8},
        learnReviews: {
          'first-strategy': LearnReviewSchedule(
            dueAt: now.subtract(const Duration(days: 1)),
          ).toJson(),
          'dealer-upcard': LearnReviewSchedule(
            dueAt: now.subtract(const Duration(days: 2)),
          ).toJson(),
        },
      );
      expect(
        StudyPlan.select(catalog, progress, now).reviewLesson!.id,
        'dealer-upcard',
      );
      expect(
        StudyPlan.select(
          catalog,
          progress.copyWith(
            learnReviewSessions: {
              lesson.id: LearnReviewSession(lesson).toJson(),
            },
          ),
          now,
        ).reviewLesson!.id,
        lesson.id,
      );
      expect(
        StudyPlan.select(
          catalog,
          progress.copyWith(
            learnReviews: {
              'first-strategy': {'dueAt': 'broken'},
            },
          ),
          now,
        ).reviewLesson,
        isNull,
      );
      expect(
        StudyPlan.select(
          catalog,
          progress.copyWith(
            learnReviewSessions: {
              'first-strategy': {'attempt': 'bad'},
            },
          ),
          now,
        ).reviewLesson!.id,
        'dealer-upcard',
      );
    },
  );
  test('review uses 1/3/7/14/30 days, an error resets to one day', () {
    var schedule = LearnReviewSchedule(dueAt: now);
    for (final days in [3, 7, 14, 30, 30]) {
      schedule = schedule.answered(correct: true, now: now);
      expect(schedule.dueAt, now.add(Duration(days: days)));
      schedule = LearnReviewSchedule.fromJson(schedule.toJson());
    }
    schedule = schedule.answered(correct: false, now: now);
    expect(schedule.step, 0);
    expect(schedule.runs, 6);
    expect(schedule.dueAt, now.add(const Duration(days: 1)));
    for (final raw in <Map<String, Object?>>[
      {},
      {'dueAt': 'bad', 'step': 0, 'runs': 0},
      {'dueAt': now.toIso8601String(), 'step': 5, 'runs': 0},
    ]) {
      expect(() => LearnReviewSchedule.fromJson(raw), throwsFormatException);
    }
  });
  for (final locale in ['en', 'ru']) {
    test(
      '$locale: every kind resumes unassisted independent practice and keeps first answer',
      () {
        for (final lesson in course(locale).playableLessons) {
          var session = LearnReviewSession(lesson);
          expect(session.task.allowsHint, isFalse);
          if (session.task.requiresReveal) {
            expect(
              () => session.submit(session.task.expected),
              throwsStateError,
            );
            while (session.revealed < session.task.revealLimit) {
              session.reveal();
              session = LearnReviewSession.restore(lesson, session.toJson());
            }
          } else {
            expect(() => session.reveal(), throwsStateError);
          }
          if (session.task.usesNumber) {
            session.adjust(1);
            session.adjust(-1);
          } else {
            expect(() => session.adjust(1), throwsStateError);
          }
          session.submit(session.task.expected);
          session = LearnReviewSession.restore(lesson, session.toJson());
          expect(session.correct, isTrue);
          expect(() => session.submit(session.task.expected), throwsStateError);
          expect(() => session.reveal(), throwsStateError);
          expect(() => session.adjust(1), throwsStateError);
          final raw = session.toJson();
          for (final patch in <Map<String, Object?>>[
            {'signature': 'changed'},
            {'revealed': 999},
            {'input': 999},
            {'answer': 'unknown'},
            {'attempt': -1},
            {'task': 'old'},
            {'attempt': 'bad'},
          ]) {
            expect(
              () => LearnReviewSession.restore(lesson, {...raw, ...patch}),
              throwsFormatException,
            );
          }
        }
      },
    );
  }
  test(
    'old progress defaults empty, malformed review stays isolated and survives serialization',
    () {
      final old = ProgressSnapshot.fromJson({});
      expect(old.learnReviews, isEmpty);
      expect(old.learnReviewSessions, isEmpty);
      final current = ProgressSnapshot.fromJson({
        'xp': 100,
        'learnReviews': {'broken': 1},
        'learnReviewSessions': {'broken': 1},
      });
      final saved = ProgressSnapshot.fromJson(
        jsonDecode(jsonEncode(current.toJson())) as Map<String, Object?>,
      );
      expect(saved.learnReviews, current.learnReviews);
      expect(saved.learnReviewSessions, current.learnReviewSessions);
      expect(saved.xp, 100);
    },
  );
}
