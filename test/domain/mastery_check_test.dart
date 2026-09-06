import 'dart:convert';
import 'dart:io';

import 'package:blackjack_advantage_trainer/domain/blackjack_engine/hand.dart';
import 'package:blackjack_advantage_trainer/domain/learning/mastery_check.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:blackjack_advantage_trainer/domain/learning/pilot_lesson.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ids = ['hard-12', 'soft-18', 'hi-lo-cancellation'];
  final reference =
      jsonDecode(
            File(
              'test/fixtures/iteration6_lesson_pack_reference.json',
            ).readAsStringSync(),
          )
          as Map;
  final lessons =
      (jsonDecode(
                File('assets/content/en/pilot_lessons.json').readAsStringSync(),
              )
              as List)
          .map((e) => PilotLesson.fromJson((e as Map).cast<String, Object?>()))
          .toList();
  String fingerprint(Iterable<String> cards, String? dealer) =>
      '${cards.join(',')}/$dealer';

  for (final id in ids) {
    test('$id: held-out forms are disjoint and match independent answers', () {
      final seen = lessons
          .firstWhere((l) => l.id == id)
          .scenarios
          .map(
            (s) => fingerprint(
              s.cards.map((c) => c.rank.label),
              s.dealer?.rank.label,
            ),
          )
          .toSet();
      final package = (reference['packages'] as List).cast<Map>().firstWhere(
        (p) => p['lessonId'] == id,
      );
      final referenceCheck = package['independentTest'] as Map;
      for (var form = 0; form < MasteryCheckBank.formCount; form++) {
        final tasks = MasteryCheckBank.tasks(id, form);
        expect(tasks, hasLength(10));
        for (final task in tasks) {
          expect(
            seen.add(
              fingerprint(
                task.cards.map((c) => c.rank.label),
                task.dealer?.rank.label,
              ),
            ),
            isTrue,
          );
          if (task.isCounting) {
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
            final expected = task.cards.fold(
              0,
              (sum, card) => sum + tags[card.rank.label]!,
            );
            expect(task.expected, '$expected');
          } else {
            final hand = const HandEvaluator().evaluate(task.cards);
            expect(hand.total, id == 'hard-12' ? 12 : 18);
            expect(hand.isSoft, id == 'soft-18');
            final cases =
                (referenceCheck[id == 'hard-12' ? 'cases' : 'twoCardCases']
                        as List)
                    .cast<Map>();
            final expected = cases.firstWhere(
              (c) => c['dealer'] == task.dealer!.rank.label,
            )['expectedAction'];
            expect(
              task.expected,
              expected == 'doubleDown' ? 'stand' : expected,
            );
            expect(task.accepts(task.expected), isTrue);
          }
        }
        expect(() => tasks.clear(), throwsUnsupportedError);
      }
    });

    for (final errors in [0, 1, 2]) {
      test(
        '$id: $errors errors, first answers and resume determine the result',
        () {
          var session = MasteryCheckSession(id);
          for (var i = 0; i < 10; i++) {
            final task = session.current;
            if (task.isCounting) {
              expect(() => session.answer('0'), throwsStateError);
              expect(() => session.adjust(1), throwsStateError);
              for (var card = 0; card < task.cards.length; card++) {
                session.reveal();
                session = MasteryCheckSession.restore(id, session.toJson());
              }
              expect(() => session.reveal(), throwsStateError);
              session.adjust(1);
              session.adjust(-1);
            }
            final wrong = task.isCounting
                ? '3'
                : task.expected == 'hit'
                ? 'stand'
                : 'hit';
            session.answer(i < errors ? wrong : task.expected);
            session = MasteryCheckSession.restore(id, session.toJson());
            expect(session.index, i + 1);
          }
          expect(session.correct, 10 - errors);
          expect(session.passed, errors <= 1);
          expect(() => session.answer('hit'), throwsStateError);
          expect(() => session.reveal(), throwsStateError);
          expect(() => session.answers.clear(), throwsUnsupportedError);
          final snapshot = ProgressSnapshot.fromJson(
            jsonDecode(
                  jsonEncode(
                    ProgressSnapshot(
                      masteryChecks: {id: session.toJson()},
                    ).toJson(),
                  ),
                )
                as Map<String, Object?>,
          );
          expect(snapshot.masteryChecks[id], session.toJson());
          expect(snapshot.lessonScores, isEmpty);
        },
      );
    }
  }

  test('incompatible or malformed check state fails closed', () {
    final good = MasteryCheckSession('hard-12').toJson();
    for (final patch in <Map<String, Object?>>[
      {'form': -1},
      {'form': 2},
      {'form': '0'},
      {'signature': 'old'},
      {
        'answers': ['split'],
      },
      {
        'answers': [null],
      },
      {'answers': List.filled(11, 'hit')},
      {'revealed': 1},
      {'revealed': -1},
      {'count': 1},
      {'answers': null},
    ]) {
      expect(
        () => MasteryCheckSession.restore('hard-12', {...good, ...patch}),
        throwsFormatException,
      );
    }
    expect(() => MasteryCheckBank.tasks('unknown', 0), throwsArgumentError);
    expect(
      () => MasteryCheckSession.restore('unknown', good),
      throwsFormatException,
    );
    final count = MasteryCheckSession('hi-lo-cancellation');
    expect(
      () => MasteryCheckSession.restore(count.lessonId, {
        ...count.toJson(),
        'count': 1,
      }),
      throwsFormatException,
    );
    for (var i = 0; i < count.current.cards.length; i++) {
      count.reveal();
    }
    expect(() => count.adjust(2), throwsStateError);
    for (var i = 0; i < 20; i++) {
      count.adjust(-1);
    }
    expect(count.count, -count.current.cards.length);
    expect(() => count.answer('99'), throwsStateError);
  });
}
