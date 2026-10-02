import 'dart:convert';
import 'dart:io';

import 'package:blackjack_advantage_trainer/domain/learning/count_certification.dart';
import 'package:blackjack_advantage_trainer/domain/learning/decision_lesson.dart';
import 'package:blackjack_advantage_trainer/domain/learning/pilot_lesson.dart';
import 'package:flutter_test/flutter_test.dart';

import 'iteration26_count_lessons_test.dart' show tags;

CountCertificationSession completeDeck(CountCertificationSession session) {
  session.begin();
  session.addTime(session.limitSeconds * 1000 - 52);
  for (var i = 0; i < 52; i++) {
    session.addTime(1);
    session.reveal();
    session = CountCertificationSession.restore(session.toJson());
    if (session.needsAnswer) {
      final expected = session.cards
          .take(i + 1)
          .fold<int>(0, (sum, c) => sum + tags[c.rank.label]!);
      for (var step = 0; step < expected.abs(); step++) {
        session.adjust(expected > 0 ? 1 : -1);
      }
      session.answer();
      session = CountCertificationSession.restore(session.toJson());
    }
  }
  return session;
}

void main() {
  test(
    'three full decks require exact intermediate counts at all three time limits',
    () {
      var session = CountCertificationSession(seed: 27);
      expect(() => session.reveal(), throwsStateError);
      for (var level = 0; level < 3; level++) {
        expect(session.level, level);
        expect(session.limitSeconds, [60, 45, 30][level]);
        expect(session.cards, hasLength(52));
        expect(
          session.cards.map((c) => '${c.suit}/${c.rank}').toSet(),
          hasLength(52),
        );
        expect(
          session.cards.fold<int>(0, (sum, c) => sum + tags[c.rank.label]!),
          0,
        );
        session = completeDeck(session);
        expect(session.passed, level == 2);
      }
      expect(() => session.begin(), throwsStateError);
      expect(() => session.answer(), throwsStateError);
      session.addTime(1);
      expect(session.elapsedMs, 0);
      expect(() => session.orders.clear(), throwsUnsupportedError);
      expect(() => session.answers.clear(), throwsUnsupportedError);
    },
  );
  test(
    'a wrong checkpoint fails even though the balanced deck ends at zero',
    () {
      final session = CountCertificationSession(seed: 2)..begin();
      for (var i = 0; i < 8; i++) {
        session.reveal();
      }
      expect(() => session.reveal(), throwsStateError);
      final expected = session.cards
          .take(8)
          .fold<int>(0, (sum, c) => sum + tags[c.rank.label]!);
      if (expected == 0) session.adjust(1);
      session.answer();
      expect(session.failed, isTrue);
      expect(
        session.cards.fold<int>(0, (sum, c) => sum + tags[c.rank.label]!),
        0,
      );
      expect(
        CountCertificationSession.restore(session.toJson()).failed,
        isTrue,
      );
      expect(() => session.reveal(), throwsStateError);
    },
  );
  test('time overflow at a checkpoint fails and restores safely', () {
    var session = CountCertificationSession(seed: 7)..begin();
    for (var i = 0; i < 8; i++) {
      session.reveal();
    }
    session.adjust(1);
    session.addTime(60001);
    expect(session.failed, isTrue);
    session = CountCertificationSession.restore(session.toJson());
    expect(session.input, 0);
    expect(() => session.adjust(1), throwsStateError);
    expect(() => session.addTime(-1), throwsArgumentError);
  });
  test(
    'seed is reproducible but attempts and levels use distinct full decks',
    () {
      for (var seed = 0; seed < 100; seed++) {
        final a = CountCertificationSession(seed: seed);
        final b = CountCertificationSession(seed: seed);
        expect(a.orders, b.orders);
        expect(a.orders.toSet(), hasLength(3));
        expect(
          a.orders.first,
          isNot(CountCertificationSession(seed: seed + 1).orders.first),
        );
      }
      expect(() => CountCertificationSession(seed: -1), throwsArgumentError);
      expect(
        () => CountCertificationSession(seed: 0, attempt: 0),
        throwsArgumentError,
      );
    },
  );
  test('malformed or forged completed evidence fails closed', () {
    final good = CountCertificationSession(seed: 7).toJson();
    for (final patch in <Map<String, Object?>>[
      {'version': 0},
      {'seed': -1},
      {'level': 4},
      {'level': '1'},
      {'revealed': 53},
      {'elapsedMs': -1},
      {'orders': []},
      {'orders': List.filled(3, List.filled(52, 0))},
      {'orders': List.filled(3, List.generate(52, (i) => i))},
      {
        'answers': [0],
      },
      {
        'completed': [
          {'answers': [], 'elapsedMs': 0},
        ],
      },
      {'failed': true},
      {'input': 21},
    ]) {
      expect(
        () => CountCertificationSession.restore({...good, ...patch}),
        throwsFormatException,
      );
    }
    var complete = CountCertificationSession(seed: 19);
    for (var i = 0; i < 3; i++) {
      complete = completeDeck(complete);
    }
    final saved =
        jsonDecode(jsonEncode(complete.toJson())) as Map<String, Object?>;
    (saved['completed'] as List).first['elapsedMs'] = 60001;
    expect(
      () => CountCertificationSession.restore(saved),
      throwsFormatException,
    );
  });
  for (final locale in ['en', 'ru']) {
    test(
      '$locale continuity/checkpoints/speed authored tasks preserve nonzero RC',
      () {
        final lessons =
            (jsonDecode(
                      File(
                        'assets/content/$locale/count_lessons.json',
                      ).readAsStringSync(),
                    )
                    as List)
                .skip(2)
                .map((l) => PilotLesson.fromJson(l as Map<String, Object?>));
        expect(lessons, hasLength(3));
        for (final lesson in lessons) {
          var session = DecisionLessonSession(lesson)..begin();
          int? previous;
          for (final task in lesson.scenarios) {
            if (previous != null) expect(task.initialCount, previous);
            final expected =
                task.initialCount +
                task.cards.fold<int>(0, (sum, c) => sum + tags[c.rank.label]!);
            expect(task.expected, '$expected');
            previous = expected;
            for (final _ in task.cards) {
              session.reveal();
            }
            session.answer(task.expected);
            session = DecisionLessonSession.restore(lesson, session.toJson());
            session.next();
          }
          expect(session.correctAnswers, 10);
        }
      },
    );
  }
}
