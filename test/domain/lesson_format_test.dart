import 'dart:convert';
import 'dart:io';

import 'package:blackjack_advantage_trainer/domain/learning/decision_lesson.dart';
import 'package:blackjack_advantage_trainer/domain/learning/lesson_format.dart';
import 'package:blackjack_advantage_trainer/domain/learning/pilot_lesson.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _rawLesson() => Map<String, Object?>.from(
  (jsonDecode(File('assets/content/en/pilot_lessons.json').readAsStringSync())
              as List)
          .first
      as Map,
);

void main() {
  test('format declares theory, mission kinds, stages and scoring', () {
    final lesson = PilotLesson.fromJson(_rawLesson());
    expect(lesson.schemaVersion, 1);
    expect(lesson.theoryBlock.id, 'hard-12-theory');
    expect(lesson.theoryBlock.text, lesson.theory);
    expect(lesson.profileId, 'standard_6d_s17_das_ls_peek_3to2');
    expect(lesson.scenarios.first.kind, LessonMissionKind.decision);
    expect(lesson.scenarios.first.stage, LessonMissionStage.introduction);
    expect(lesson.scenarios[2].stage, LessonMissionStage.practice);
    expect(lesson.scenarios.last.stage, LessonMissionStage.independent);
    expect(lesson.scenarios.first.coaching.explanation, isNotEmpty);
    expect(lesson.scoring.passes(7), isFalse);
    expect(lesson.scoring.passes(8), isTrue);
    for (final (correct, unassisted, stars) in [
      (7, 7, 0),
      (8, 8, 1),
      (9, 9, 2),
      (10, 9, 2),
      (10, 10, 3),
    ]) {
      expect(
        lesson.scoring.stars(correct: correct, unassisted: unassisted),
        stars,
      );
    }
    expect(() => lesson.scenarios.clear(), throwsUnsupportedError);
    expect(() => lesson.scoring.starCorrect.clear(), throwsUnsupportedError);
    expect(
      () => lesson.scenarios.first.mistakes.clear(),
      throwsUnsupportedError,
    );
  });

  test(
    'four introductions use the same runtime, progress and first-answer score',
    () {
      final raw = _rawLesson();
      final scenarios = List<Map<String, Object?>>.from(
        raw['scenarios']! as List,
      );
      final lesson = PilotLesson.fromJson({
        ...raw,
        'id': 'test-four-introductions',
        'scenarios': [
          {...scenarios.first, 'id': 'test-intro-a'},
          {...scenarios.first, 'id': 'test-intro-b'},
          ...scenarios,
        ],
      });
      var session = DecisionLessonSession(lesson)..begin();
      for (var i = 0; i < 14; i++) {
        expect(session.isWarmup, i < 4);
        expect(session.isIndependent, i >= 9);
        expect(session.taskNumber, i < 4 ? i + 1 : i - 3);
        expect(session.taskCount, i < 4 ? 4 : 10);
        expect(session.isLastTask, i == 13);
        session.answer(session.current.expected);
        session.next();
        session = DecisionLessonSession.restore(lesson, session.toJson());
      }
      expect(session.phase, DecisionLessonPhase.result);
      expect(session.evaluatedAnswers, 10);
      expect(session.correctAnswers, 10);
      expect(session.passed, isTrue);
      expect(session.independentAnswers, 5);
      expect(session.independentCorrectAnswers, 5);
      expect(session.stars, 3);
    },
  );

  test('completion keeps independent practice first answers separate', () {
    final lesson = PilotLesson.fromJson(_rawLesson());
    var session = DecisionLessonSession(lesson)..begin();
    for (var i = 0; i < lesson.scenarios.length; i++) {
      final task = session.current;
      final answer = i == 9 || i == 10
          ? task.availableActions
                .firstWhere((action) => action.name != task.expected)
                .name
          : task.expected;
      session.answer(answer);
      if (answer != task.expected) session.answer(task.expected);
      session.next();
    }

    expect(session.correctAnswers, 8);
    expect(session.passed, isTrue);
    expect(session.independentCorrectAnswers, 3);
  });

  test(
    'unknown schemas, policies, stage order and scene mismatches fail closed',
    () {
      final raw = _rawLesson();
      final scenarios = List<Map<String, Object?>>.from(
        raw['scenarios']! as List,
      );
      for (final update in [
        {'schemaVersion': 99},
        {
          'scenarios': [...scenarios.skip(1), scenarios.first],
        },
        {
          'scenarios': [scenarios.first, ...scenarios],
        },
      ]) {
        expect(
          () => PilotLesson.fromJson({...raw, ...update}),
          throwsFormatException,
        );
      }
      expect(
        () => PilotScenario.fromJson({
          ...scenarios.first,
          'kind': 'runningCount',
        }),
        throwsFormatException,
      );
      final scoring = raw['scoring']! as Map<String, Object?>;
      for (final update in [
        {'policyId': 'last_answer'},
        {'passCorrect': 5},
        {
          'starCorrect': [6, 8, 10],
        },
        {'topStarRequiresUnassisted': false},
      ]) {
        expect(
          () => LessonScoring.fromJson({...scoring, ...update}),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'pre-format schema 1 progress resumes without replacing the first answer',
    () {
      final lesson = PilotLesson.fromJson(_rawLesson());
      final saved = <String, Object?>{
        'schema': 1,
        'lessonId': 'hard-12',
        'version': 1,
        'order': [
          'hard-12-intro-1',
          'hard-12-intro-2',
          'hard-12-practice-3',
          'hard-12-practice-4',
          'hard-12-practice-5',
          'hard-12-practice-6',
          'hard-12-practice-7',
          'hard-12-transfer-8',
          'hard-12-transfer-9',
          'hard-12-transfer-10',
          'hard-12-transfer-11',
          'hard-12-transfer-12',
        ],
        'attempt': 1,
        'phase': 'coaching',
        'index': 2,
        'revealed': 0,
        'countInput': null,
        'hint': true,
        'corrected': true,
        'answers': ['stand', 'hit', 'stand'],
        'hints': [false, false, true],
        'awardedXp': null,
      };
      final session = DecisionLessonSession.restore(lesson, saved);
      expect(session.toJson(), {
        ...saved,
        'schema': 2,
        'contentSignature': lesson.resumeSignature,
        'adaptiveAnswer': null,
        'adaptiveCount': 0,
      });
      expect(session.firstAnswer, 'stand');
      expect(session.corrected, isTrue);
      expect(session.correctAnswers, 0);
      session.next();
      expect(session.index, 3);
    },
  );
}
