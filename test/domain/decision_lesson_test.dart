import 'dart:convert';
import 'dart:io';

import 'package:blackjack_advantage_trainer/domain/learning/cancellation.dart';
import 'package:blackjack_advantage_trainer/domain/learning/decision_lesson.dart';
import 'package:blackjack_advantage_trainer/domain/learning/pilot_lesson.dart';
import 'package:flutter_test/flutter_test.dart';

List<PilotLesson> _lessons() =>
    (jsonDecode(File('assets/content/en/pilot_lessons.json').readAsStringSync())
            as List)
        .map(
          (json) =>
              PilotLesson.fromJson(Map<String, Object?>.from(json as Map)),
        )
        .toList();

void _answer(DecisionLessonSession session, {bool wrong = false}) {
  while (session.current.isCounting &&
      session.revealed < session.current.cards.length) {
    session.reveal();
  }
  final task = session.current;
  final answer = wrong
      ? task.isCounting
            ? (int.parse(task.expected) + 1).toString()
            : task.availableActions
                  .firstWhere((action) => action.name != task.expected)
                  .name
      : task.expected;
  session.answer(answer);
}

void main() {
  final lessons = _lessons();

  for (final lesson in lessons) {
    test(
      '${lesson.id} round-trips every phase and keeps feedback on same task',
      () {
        var session = DecisionLessonSession(lesson);
        expect(session.score, 0);
        expect(() => session.answer('hit'), throwsStateError);
        expect(session.phase, DecisionLessonPhase.theory);
        session = DecisionLessonSession.restore(lesson, session.toJson());
        session.begin();
        expect(session.begin, throwsStateError);
        for (var index = 0; index < 12; index++) {
          expect(session.index, index);
          expect(session.isWarmup, index < 2);
          expect(session.isIndependent, index >= 7);
          if (index == 2) session.useHint();
          session = DecisionLessonSession.restore(lesson, session.toJson());
          expect(session.hintUsed, index == 2);
          final id = session.current.id;
          _answer(session, wrong: index == 3);
          expect(session.current.id, id);
          expect(session.phase, DecisionLessonPhase.coaching);
          session = DecisionLessonSession.restore(lesson, session.toJson());
          if (index == 3) {
            final first = session.firstAnswer;
            expect(session.next, throwsStateError);
            expect(session.corrected, isFalse);
            session.answer(session.current.expected);
            expect(session.firstAnswer, first);
            expect(
              session.current.feedback(first!),
              contains(session.current.explanation),
            );
          } else {
            expect(
              session.current.feedback(session.firstAnswer!),
              session.current.explanation,
            );
          }
          expect(
            () => session.answer(session.current.expected),
            throwsStateError,
          );
          session.next();
          session = DecisionLessonSession.restore(lesson, session.toJson());
        }
        expect(session.phase, DecisionLessonPhase.result);
        expect(session.evaluatedAnswers, 10);
        expect(session.correctAnswers, 9);
        expect(session.unassistedAnswers, 8);
        expect(session.score, 0.9);
        expect(session.stars, 2);
        session.recordReward(140);
        session = DecisionLessonSession.restore(lesson, session.toJson());
        expect(session.awardedXp, 140);
        expect(() => session.recordReward(140), throwsStateError);
        expect(session.next, throwsStateError);
        expect(session.useHint, throwsStateError);
      },
    );
  }

  test(
    'warmup mistakes are unscored; stars require independent first answers',
    () {
      for (final misses in [0, 2, 3]) {
        final session = DecisionLessonSession(lessons.first)..begin();
        for (var i = 0; i < 12; i++) {
          _answer(session, wrong: i < 2 + misses);
          if (!session.corrected) session.answer(session.current.expected);
          session.next();
        }
        expect(session.correctAnswers, 10 - misses);
        expect(
          session.stars,
          misses == 0
              ? 3
              : misses == 2
              ? 1
              : 0,
        );
      }
    },
  );

  test(
    'hints are forbidden in independent tasks; invalid actions are rejected',
    () {
      final session = DecisionLessonSession(lessons.first)..begin();
      expect(() => session.answer('split'), throwsStateError);
      expect(session.reveal, throwsStateError);
      expect(() => session.adjustCount(1), throwsStateError);
      expect(() => session.recordReward(0), throwsStateError);
      while (!session.isIndependent) {
        _answer(session);
        session.next();
      }
      expect(session.useHint, throwsStateError);
      expect(session.firstAnswer, isNull);
    },
  );

  test(
    'count reveals and draft input survive restart with bounded controls',
    () {
      var session = DecisionLessonSession(lessons.last)..begin();
      expect(session.canAnswer, isFalse);
      expect(() => session.answer('0'), throwsStateError);
      session.reveal();
      session = DecisionLessonSession.restore(lessons.last, session.toJson());
      expect(session.revealed, 1);
      session.reveal();
      expect(session.reveal, throwsStateError);
      expect(() => session.adjustCount(2), throwsStateError);
      for (var i = 0; i < 5; i++) {
        session.adjustCount(1);
      }
      expect(session.countInput, 2);
      session = DecisionLessonSession.restore(lessons.last, session.toJson());
      for (var i = 0; i < 5; i++) {
        session.adjustCount(-1);
      }
      expect(session.countInput, -2);
      expect(session.current.countAfter(0), 0);
      expect(session.current.countAfter(1), 1);
      expect(session.current.countAfter(2), 0);
      expect(() => session.answer('not a number'), throwsStateError);
    },
  );

  test(
    'rejects incompatible or inconsistent saves instead of resetting progress',
    () {
      final base = DecisionLessonSession(lessons.first).toJson();
      for (final change in <Map<String, Object?>>[
        {'schema': 2},
        {'lessonId': 'other'},
        {'version': 2},
        {'order': []},
        {'attempt': 0},
        {'index': -1},
        {'index': 12},
        {'revealed': -1},
        {'revealed': 1},
        {'hint': true},
        {'countInput': 1},
        {'corrected': true},
        {'awardedXp': 50},
        {
          'answers': ['hit'],
        },
        {
          'hints': [false],
        },
        {'phase': 'result', 'index': 0},
      ]) {
        expect(
          () => DecisionLessonSession.restore(lessons.first, {
            ...base,
            ...change,
          }),
          throwsFormatException,
        );
      }
      final session = DecisionLessonSession(lessons.first)..begin();
      _answer(session);
      expect(
        () => DecisionLessonSession.restore(lessons.first, {
          ...session.toJson(),
          'answers': ['split'],
        }),
        throwsFormatException,
      );
      while (!session.isIndependent) {
        if (session.phase == DecisionLessonPhase.decision) _answer(session);
        session.next();
      }
      expect(
        () => DecisionLessonSession.restore(lessons.first, {
          ...session.toJson(),
          'hint': true,
        }),
        throwsFormatException,
      );
      _answer(session);
      expect(
        () => DecisionLessonSession.restore(lessons.first, {
          ...session.toJson(),
          'hints': [false, false, false, false, false, false, false, true],
        }),
        throwsFormatException,
      );
    },
  );

  test('cancellation never reuses a card and can span neutral cards', () {
    List<int> ends(List<String> labels) => cancellationEnds(
      labels.indexed
          .map((e) => PilotScenario.cardFromLabel(e.$2, e.$1))
          .toList(),
    ).toList();
    expect(ends(['5', 'K', '2']), [1]);
    expect(ends(['2', '4', 'Q', 'A']), [2, 3]);
    expect(ends(['A', '8', '3']), [2]);
    expect(ends(['7', '8']), isEmpty);
    expect(ends([]), isEmpty);
  });

  test('invalid content cannot construct a pilot lesson or scenario', () {
    final raw =
        (jsonDecode(
                      File(
                        'assets/content/en/pilot_lessons.json',
                      ).readAsStringSync(),
                    )
                    as List)
                .first
            as Map<String, dynamic>;
    expect(
      () => PilotLesson.fromJson({...raw, 'scenarios': []}),
      throwsFormatException,
    );
    final task = (raw['scenarios'] as List).first as Map<String, dynamic>;
    expect(
      () => PilotScenario.fromJson({...task, 'cards': []}),
      throwsFormatException,
    );
    expect(
      () => PilotScenario.fromJson({...task, 'expected': 'split'}),
      throwsFormatException,
    );
  });
}
