import 'dart:convert';
import 'dart:io';

import 'package:blackjack_advantage_trainer/domain/blackjack_engine/hand.dart';
import 'package:blackjack_advantage_trainer/domain/learning/decision_lesson.dart';
import 'package:blackjack_advantage_trainer/domain/learning/lesson_adaptation.dart';
import 'package:blackjack_advantage_trainer/domain/learning/mastery_check.dart';
import 'package:blackjack_advantage_trainer/domain/learning/pilot_lesson.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pilot_adaptation.dart';

List<Map<String, Object?>> rawLessons() =>
    (jsonDecode(File('assets/content/en/pilot_lessons.json').readAsStringSync())
            as List)
        .cast<Map<String, Object?>>();

void main() {
  final lessons = rawLessons().map(PilotLesson.fromJson).toList();
  final fixture =
      jsonDecode(
            File(
              'test/fixtures/iteration6_lesson_pack_reference.json',
            ).readAsStringSync(),
          )
          as Map;

  void verifyExample(String id, AdaptiveExample example) {
    String fingerprint(Iterable<String> cards, String? dealer) =>
        '${cards.join(',')}/$dealer';
    final key = fingerprint(
      example.cards.map((c) => c.rank.label),
      example.dealer?.rank.label,
    );
    for (var form = 0; form < MasteryCheckBank.formCount; form++) {
      expect(
        MasteryCheckBank.tasks(id, form).any(
          (t) =>
              fingerprint(
                t.cards.map((c) => c.rank.label),
                t.dealer?.rank.label,
              ) ==
              key,
        ),
        isFalse,
        reason: 'Adaptive practice must not reveal held-out check tasks',
      );
    }
    if (example.isCounting) {
      const tags = {
        '2': 1,
        '3': 1,
        '4': 1,
        '5': 1,
        '6': 1,
        '7': 0,
        '8': 0,
        '9': 0,
        '10': -1,
        'J': -1,
        'Q': -1,
        'K': -1,
        'A': -1,
      };
      expect(
        example.expected,
        '${example.cards.fold(0, (sum, c) => sum + tags[c.rank.label]!)}',
      );
    } else {
      final hand = const HandEvaluator().evaluate(example.cards);
      expect(hand.total, id == 'hard-12' ? 12 : 18);
      expect(hand.isSoft, id == 'soft-18');
      final package = (fixture['packages'] as List).cast<Map>().firstWhere(
        (p) => p['lessonId'] == id,
      );
      final cases =
          ((package['independentTest'] as Map)[id == 'hard-12'
                      ? 'cases'
                      : 'twoCardCases']
                  as List)
              .cast<Map>();
      final expected = cases.firstWhere(
        (c) => c['dealer'] == example.dealer!.rank.label,
      )['expectedAction'];
      expect(
        example.expected,
        example.cards.length > 2 && expected == 'doubleDown'
            ? 'stand'
            : expected,
      );
    }
    expect(example.accepts(example.expected), isTrue);
    expect(example.accepts('invalid'), isFalse);
  }

  for (final lesson in lessons) {
    test(
      '${lesson.id}: challenge is unscored, resumable, optional and reference-checked',
      () {
        var session = boundary(lesson);
        expect(session.isAdaptiveBoundary, isTrue);
        expect(session.adaptation!.isChallenge, isTrue);
        verifyExample(lesson.id, session.adaptation!.example);
        final before = session.toJson();
        expect(() => session.answerAdaptive('invalid'), throwsStateError);
        if (lesson.id == 'hi-lo-cancellation') {
          session.adjustAdaptiveCount(1);
          session = DecisionLessonSession.restore(lesson, session.toJson());
          expect(session.adaptiveCount, 1);
          session.adjustAdaptiveCount(-1);
        } else {
          expect(() => session.adjustAdaptiveCount(1), throwsStateError);
        }
        session.answerAdaptive(session.adaptation!.example.expected);
        session = DecisionLessonSession.restore(lesson, session.toJson());
        expect(session.toJson()['answers'], before['answers']);
        expect(session.toJson()['hints'], before['hints']);
        expect(session.correctAnswers, 5);
        expect(
          () => session.answerAdaptive(session.adaptiveAnswer!),
          throwsStateError,
        );
        expect(() => session.adjustAdaptiveCount(1), throwsStateError);
        session.next();
        expect(session.isAdaptiveBoundary, isFalse);
        expect(session.current.id, lesson.scenarios[7].id);
        final skipped = boundary(lesson)..next();
        expect(skipped.current.id, session.current.id);
        expect(skipped.score, session.score);
        expect(skipped.toJson()['order'], session.toJson()['order']);
        expect(boundary(lesson, hinted: true).adaptation, isNull);
        expect(boundary(lesson, errors: {2}).adaptation, isNull);
        final early = DecisionLessonSession(lesson)..begin();
        expect(early.adaptation, isNull);
        expect(() => early.answerAdaptive('hit'), throwsStateError);
        expect(
          () => DecisionLessonSession.restore(lesson, {
            ...early.toJson(),
            'adaptiveAnswer': 'hit',
          }),
          throwsFormatException,
        );
        expect(
          () => DecisionLessonSession.restore(lesson, {
            ...early.toJson(),
            'adaptiveCount': 1,
          }),
          throwsFormatException,
        );
      },
    );
  }

  for (final (id, errors, focus) in [
    ('hard-12', {3, 4}, AdaptiveFocus.hardStand),
    ('hard-12', {2, 5}, AdaptiveFocus.hardHit),
    ('soft-18', {2, 5}, AdaptiveFocus.softStand),
    ('soft-18', {3, 6}, AdaptiveFocus.softHit),
    ('hi-lo-cancellation', {2, 3}, AdaptiveFocus.countResult),
  ]) {
    test(
      '$focus: only repeated observed categories select a simple example',
      () {
        final lesson = lessons.firstWhere((l) => l.id == id);
        final session = boundary(lesson, errors: errors);
        expect(session.adaptation!.focus, focus);
        expect(session.adaptation!.isChallenge, isFalse);
        verifyExample(id, session.adaptation!.example);
      },
    );
  }

  for (final multiCard in [false, true]) {
    test(
      'soft 18 repeated Double/fallback cases use the appropriate example ($multiCard)',
      () {
        final raw = rawLessons()[1];
        final tasks = (raw['scenarios'] as List).cast<Map<String, Object?>>();
        for (final index in [2, 3]) {
          tasks[index]['cards'] = multiCard ? ['A', '2', '5'] : ['A', '7'];
          tasks[index]['dealer'] = '6';
          tasks[index]['actions'] = multiCard
              ? ['hit', 'stand']
              : ['hit', 'stand', 'doubleDown'];
          tasks[index]['expected'] = multiCard ? 'stand' : 'doubleDown';
        }
        final lesson = PilotLesson.fromJson(raw);
        final session = boundary(lesson, errors: {2, 3});
        expect(
          session.adaptation!.focus,
          multiCard ? AdaptiveFocus.softFallback : AdaptiveFocus.softDouble,
        );
        verifyExample(lesson.id, session.adaptation!.example);
      },
    );
  }

  test('old saves need no reset; adaptive count is bounded', () {
    final lesson = lessons.last;
    final session = boundary(lesson);
    final old = session.toJson()
      ..remove('adaptiveAnswer')
      ..remove('adaptiveCount');
    expect(DecisionLessonSession.restore(lesson, old).adaptiveAnswer, isNull);
    expect(() => session.adjustAdaptiveCount(2), throwsStateError);
    for (var i = 0; i < 20; i++) {
      session.adjustAdaptiveCount(-1);
    }
    expect(session.adaptiveCount, -session.adaptation!.example.cards.length);
    expect(
      () =>
          DecisionLessonSession.restore(lesson, {...old, 'adaptiveCount': 99}),
      throwsFormatException,
    );
    final unknownRaw = rawLessons().first..['id'] = 'future-lesson';
    expect(boundary(PilotLesson.fromJson(unknownRaw)).adaptation, isNull);
  });
}
