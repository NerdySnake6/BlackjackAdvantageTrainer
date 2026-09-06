import 'dart:convert';
import 'dart:io';

import 'package:blackjack_advantage_trainer/domain/learning/decision_lesson.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:blackjack_advantage_trainer/domain/learning/pilot_lesson.dart';
import 'package:blackjack_advantage_trainer/domain/learning/pilot_progress_migration.dart';
import 'package:flutter_test/flutter_test.dart';

CourseCatalog _catalog(String locale) => CourseCatalog.fromJson({
  ...jsonDecode(File('assets/content/$locale/lessons.json').readAsStringSync())
      as Map<String, Object?>,
  'pilotLessons': jsonDecode(
    File('assets/content/$locale/pilot_lessons.json').readAsStringSync(),
  ),
});

Map<String, Object?> _legacy(DecisionLessonSession session) => session.toJson()
  ..remove('contentSignature')
  ..['schema'] = 1;

void main() {
  final catalog = _catalog('en');
  const migration = PilotProgressMigration();

  test(
    'compatible sessions migrate once without changing any other progress',
    () {
      final lesson = catalog.pilotLessons.first;
      final session = DecisionLessonSession(lesson)
        ..begin()
        ..answer('hit');
      final original = ProgressSnapshot(
        xp: 999,
        streakDays: 5,
        lastActivityDate: DateTime(2026, 9, 5),
        languageCode: 'ru',
        experienceLevel: ExperienceLevel.experienced,
        hasSeenCountDrillIntro: true,
        hasSeenTelemetryConsent: true,
        analyticsConsent: const ConsentState(isGranted: true, policyVersion: 1),
        crashReportsConsent: const ConsentState(
          isGranted: false,
          policyVersion: 1,
        ),
        lessonScores: const {'quick-start': 0.9},
        activeSessions: const {
          'card-values': LessonSessionProgress(
            nextExerciseIndex: 2,
            correctAnswers: 1,
          ),
        },
        exerciseReviewStates: const {
          'card-values-1': ExerciseReviewState(
            attempts: 3,
            successfulReviewStreak: 2,
          ),
        },
        pilotSessions: {
          lesson.id: _legacy(session),
          'future-lesson': {'schema': 99},
        },
      );
      final migrated = migration.migrate(original, catalog);
      final before = original.toJson()..remove('pilotSessions');
      final after = migrated.toJson()..remove('pilotSessions');
      expect(after, before);
      expect(original.pilotSessions[lesson.id]!['schema'], 1);
      expect(migrated.pilotSessions[lesson.id], session.toJson());
      expect(migrated.pilotSessions['future-lesson'], {'schema': 99});
      expect(identical(migration.migrate(migrated, catalog), migrated), isTrue);
      final restored = DecisionLessonSession.restore(
        lesson,
        migrated.pilotSessions[lesson.id]!,
      );
      expect(restored.firstAnswer, 'hit');
      expect(restored.corrected, isFalse);
      expect(restored.next, throwsStateError);
    },
  );

  test(
    'completed legacy result migrates without changing the recorded reward',
    () {
      final lesson = catalog.pilotLessons.first;
      final session = DecisionLessonSession(lesson)..begin();
      for (final task in lesson.scenarios) {
        session.answer(task.expected);
        session.next();
      }
      session.recordReward(150);
      final progress = ProgressSnapshot(
        xp: 150,
        pilotSessions: {lesson.id: _legacy(session)},
      );
      final migrated = migration.migrate(progress, catalog);
      expect(migrated.xp, 150);
      final restored = DecisionLessonSession.restore(
        lesson,
        migrated.pilotSessions[lesson.id]!,
      );
      expect(restored.awardedXp, 150);
      expect(() => restored.recordReward(150), throwsStateError);
    },
  );

  test('legacy count draft, revealed cards and hint migrate unchanged', () {
    final lesson = catalog.pilotLessons.last;
    final session = DecisionLessonSession(lesson)
      ..begin()
      ..useHint();
    for (
      var revealed = 0;
      revealed <= session.current.cards.length;
      revealed++
    ) {
      final original = ProgressSnapshot(
        pilotSessions: {lesson.id: _legacy(session)},
      );
      final migrated = migration.migrate(original, catalog);
      expect(migrated.pilotSessions[lesson.id], session.toJson());
      if (revealed < session.current.cards.length) session.reveal();
    }
    session.adjustCount(1);
    final migrated = migration.migrate(
      ProgressSnapshot(pilotSessions: {lesson.id: _legacy(session)}),
      catalog,
    );
    final restored = DecisionLessonSession.restore(
      lesson,
      migrated.pilotSessions[lesson.id]!,
    );
    expect(restored.countInput, 1);
    expect(restored.hintUsed, isTrue);
    expect(restored.revealed, session.current.cards.length);
  });

  test('unknown, malformed and incompatible legacy sessions are preserved', () {
    final lesson = catalog.pilotLessons.first;
    final saved = _legacy(DecisionLessonSession(lesson));
    for (final update in <Map<String, Object?>>[
      {'version': 99},
      {'phase': 'not-a-phase'},
      {'order': null},
      {'schema': 99},
      {'attempt': -1},
      {
        'answers': [1],
      },
    ]) {
      final original = ProgressSnapshot(
        pilotSessions: {
          lesson.id: {...saved, ...update},
        },
      );
      expect(identical(migration.migrate(original, catalog), original), isTrue);
    }
  });

  test(
    'resume signature is locale-independent and detects unversioned task edits',
    () {
      final lesson = catalog.pilotLessons.first;
      final russian = _catalog('ru').pilotLessons.first;
      final saved = DecisionLessonSession(lesson).toJson();
      expect(DecisionLessonSession.restore(russian, saved).toJson(), saved);
      final raw =
          (jsonDecode(
                        File(
                          'assets/content/en/pilot_lessons.json',
                        ).readAsStringSync(),
                      )
                      as List)
                  .first
              as Map<String, Object?>;
      (raw['scenarios'] as List).first['dealer'] = '3';
      final changed = PilotLesson.fromJson(raw);
      expect(
        () => DecisionLessonSession.restore(changed, saved),
        throwsFormatException,
      );
      expect(
        () => DecisionLessonSession.restore(lesson, {
          ...saved,
          'contentSignature': null,
        }),
        throwsFormatException,
      );
    },
  );

  test('impossible feedback and hint states fail closed', () {
    final lesson = catalog.pilotLessons.first;
    final session = DecisionLessonSession(lesson)
      ..begin()
      ..answer('stand');
    for (final update in <Map<String, Object?>>[
      {'corrected': false},
      {'hint': true},
      {'phase': 'unknown'},
      {'schema': 1.0},
      {'index': '0'},
      {'attempt': 0},
    ]) {
      expect(
        () => DecisionLessonSession.restore(lesson, {
          ...session.toJson(),
          ...update,
        }),
        throwsFormatException,
      );
    }
    expect(
      () => DecisionLessonSession(lesson, attempt: 0),
      throwsArgumentError,
    );
  });
}
