import 'dart:convert';
import 'dart:io';

import 'package:blackjack_advantage_trainer/domain/blackjack_engine/game_rules.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/hand.dart';
import 'package:blackjack_advantage_trainer/domain/learning/decision_lesson.dart';
import 'package:blackjack_advantage_trainer/domain/learning/lesson_adaptation.dart';
import 'package:blackjack_advantage_trainer/domain/learning/mastery_check.dart';
import 'package:blackjack_advantage_trainer/domain/learning/pilot_lesson.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pilot_adaptation.dart';

String fingerprint(AdaptiveExample example) =>
    '${example.cards.map((c) => c.rank.label).join(',')}/${example.dealer?.rank.label}';

void main() {
  final reference =
      jsonDecode(
            File(
              'test/fixtures/iteration6_lesson_pack_reference.json',
            ).readAsStringSync(),
          )
          as Map;
  const focuses = {
    'hard-12': [
      AdaptiveFocus.hardStand,
      AdaptiveFocus.hardHit,
      AdaptiveFocus.extraCard,
    ],
    'soft-18': [
      AdaptiveFocus.softDouble,
      AdaptiveFocus.softStand,
      AdaptiveFocus.softHit,
      AdaptiveFocus.softFallback,
      AdaptiveFocus.extraCard,
    ],
    'hi-lo-cancellation': [AdaptiveFocus.countResult, AdaptiveFocus.extraCard],
  };

  for (final entry in focuses.entries) {
    for (final focus in entry.value) {
      test(
        '${entry.key} $focus: 1000 seeds match independent reference and exclude exams',
        () {
          final id = entry.key;
          final heldOut = {
            for (var form = 0; form < MasteryCheckBank.formCount; form++)
              for (final t in MasteryCheckBank.tasks(id, form))
                '${t.cards.map((c) => c.rank.label).join(',')}/${t.dealer?.rank.label}',
          };
          final package = (reference['packages'] as List)
              .cast<Map>()
              .firstWhere((p) => p['lessonId'] == id);
          String? previous;
          final dealers = <String>{};
          final counts = <int>{};
          for (var seed = 0; seed < 1000; seed++) {
            final example = AdaptiveExampleGenerator.generate(id, focus, seed);
            final signature = fingerprint(example);
            expect(signature, isNot(previous));
            previous = signature;
            expect(
              signature,
              fingerprint(AdaptiveExampleGenerator.generate(id, focus, seed)),
            );
            expect(heldOut.contains(signature), isFalse);
            expect(example.accepts(example.expected), isTrue);
            expect(
              example.cards.length,
              focus == AdaptiveFocus.extraCard
                  ? (id == 'hi-lo-cancellation' ? 5 : 3)
                  : focus == AdaptiveFocus.softFallback
                  ? 3
                  : 2,
            );
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
              final count = example.cards.fold(
                0,
                (sum, card) => sum + tags[card.rank.label]!,
              );
              counts.add(count);
              expect(example.expected, '$count');
            } else {
              final hand = const HandEvaluator().evaluate(example.cards);
              expect(hand.total, id == 'hard-12' ? 12 : 18);
              expect(hand.isSoft, id == 'soft-18');
              final cases =
                  ((package['independentTest'] as Map)[id == 'hard-12'
                              ? 'cases'
                              : 'twoCardCases']
                          as List)
                      .cast<Map>();
              final dealer = example.dealer!.rank.label;
              dealers.add(dealer);
              final expected = cases.firstWhere(
                (c) => c['dealer'] == dealer,
              )['expectedAction'];
              final canDouble = example.cards.length == 2;
              expect(
                example.actions.contains(PlayerAction.doubleDown),
                canDouble,
              );
              expect(
                example.expected,
                !canDouble && expected == 'doubleDown' ? 'stand' : expected,
              );
            }
          }
          if (focus == AdaptiveFocus.extraCard) {
            if (id == 'hi-lo-cancellation') {
              expect(counts, containsAll([0, 1, -1, 3, -3]));
            } else {
              expect(dealers, {
                '2',
                '3',
                '4',
                '5',
                '6',
                '7',
                '8',
                '9',
                '10',
                'A',
              });
            }
          }
        },
      );
    }
  }

  test(
    'seed and generator version survive resume; old saves keep variant zero',
    () {
      for (final locale in ['en', 'ru']) {
        final lessons =
            (jsonDecode(
                      File(
                        'assets/content/$locale/pilot_lessons.json',
                      ).readAsStringSync(),
                    )
                    as List)
                .map((e) => PilotLesson.fromJson(e as Map<String, Object?>));
        for (final lesson in lessons) {
          final initial = boundary(lesson);
          final saved = {...initial.toJson(), 'attempt': 10, 'adaptiveSeed': 9};
          final session = DecisionLessonSession.restore(lesson, saved);
          final before = fingerprint(session.adaptation!.example);
          session.answerAdaptive(session.adaptation!.example.expected);
          final restored = DecisionLessonSession.restore(
            lesson,
            session.toJson(),
          );
          expect(restored.adaptiveSeed, 9);
          expect(fingerprint(restored.adaptation!.example), before);
          expect(restored.adaptiveAnswer, session.adaptiveAnswer);
          final legacy = initial.toJson()
            ..remove('adaptiveSeed')
            ..remove('adaptiveGeneratorVersion')
            ..['attempt'] = 10;
          expect(DecisionLessonSession.restore(lesson, legacy).adaptiveSeed, 0);
          expect(DecisionLessonSession(lesson, attempt: 10).adaptiveSeed, 9);
          for (final patch in <Map<String, Object?>>[
            {'adaptiveSeed': -1},
            {'adaptiveSeed': AdaptiveExampleGenerator.maxSeed + 1},
            {'adaptiveSeed': '9'},
            {'adaptiveGeneratorVersion': 99},
          ]) {
            expect(
              () => DecisionLessonSession.restore(lesson, {...saved, ...patch}),
              throwsFormatException,
            );
          }
          expect(
            AdaptiveExampleGenerator.generate(
              lesson.id,
              AdaptiveFocus.extraCard,
              AdaptiveExampleGenerator.maxSeed,
            ).expected,
            isNotEmpty,
          );
        }
      }
    },
  );

  test('unknown skill, mismatched focus and invalid seeds fail closed', () {
    for (final (id, focus, seed) in [
      ('unknown', AdaptiveFocus.extraCard, 1),
      ('hard-12', AdaptiveFocus.softHit, 1),
      ('soft-18', AdaptiveFocus.countResult, 1),
      ('hi-lo-cancellation', AdaptiveFocus.hardHit, 1),
      ('hard-12', AdaptiveFocus.extraCard, -1),
      (
        'hard-12',
        AdaptiveFocus.extraCard,
        AdaptiveExampleGenerator.maxSeed + 1,
      ),
    ]) {
      expect(
        () => AdaptiveExampleGenerator.generate(id, focus, seed),
        throwsArgumentError,
      );
    }
  });
}
