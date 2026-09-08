import 'dart:convert';
import 'dart:io';

import 'package:blackjack_advantage_trainer/domain/blackjack_engine/blackjack_engine.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/game_rules.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/hand.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/shoe.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/strategy_engine.dart';
import 'package:blackjack_advantage_trainer/domain/learning/decision_lesson.dart';
import 'package:blackjack_advantage_trainer/domain/learning/pilot_lesson.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/hand_reference.dart';

List<PilotLesson> lessons(String locale) =>
    (jsonDecode(
              File(
                'assets/content/$locale/strategy_lessons.json',
              ).readAsStringSync(),
            )
            as List)
        .skip(3)
        .map((l) => PilotLesson.fromJson(l as Map<String, Object?>))
        .toList();

void main() {
  final reference =
      jsonDecode(
            File(
              'test/fixtures/standard_strategy_s17_das_ls.json',
            ).readAsStringSync(),
          )
          as Map;
  for (final locale in ['en', 'ru']) {
    test(
      '$locale: every hard/soft/pair task matches the independent full table',
      () {
        final course = lessons(locale);
        expect(course.map((l) => l.id), [
          'hard-13-16',
          'soft-13-17',
          'pairs-core',
        ]);
        for (final lesson in course) {
          expect(lesson.scenarios, hasLength(12));
          for (final task in lesson.scenarios) {
            final ranks = task.cards.map((c) => c.rank.label).toList();
            final (total, soft) = referenceHand(ranks);
            int value(String rank) =>
                rank == 'A' ? 1 : int.tryParse(rank) ?? 10;
            final pair =
                ranks.length == 2 && value(ranks[0]) == value(ranks[1]);
            final family = pair
                ? 'pairs'
                : soft
                ? 'soft'
                : 'hard';
            final key = pair
                ? ranks[0] == 'A'
                      ? 'A'
                      : '${value(ranks[0])}'
                : '$total';
            final dealerIndex = (reference['dealerOrder'] as List).indexOf(
              task.dealer!.rank.label,
            );
            final row = (reference[family] as Map)[key] as String;
            var expected =
                (reference['codes'] as Map)[row[dealerIndex]] as String;
            if ((expected == 'doubleDown' || expected == 'surrender') &&
                !task.availableActions.any((a) => a.name == expected)) {
              expected = 'hit'; // Only hard 13–16 and soft 13–17 in this bank.
            }
            expect(task.evaluation.total, total);
            expect(task.evaluation.isSoft, soft);
            expect(task.expected, expected, reason: task.id);
            expect(
              const StrategyEngine()
                  .recommend(
                    hand: BlackjackHand(task.cards),
                    dealerUpCard: task.dealer!,
                    rules: GameRulesProfile.standard,
                    availableActions: task.availableActions,
                  )
                  .name,
              expected,
            );
            final engine = BlackjackEngine()
              ..phase = RoundPhase.playerTurn
              ..activeSeatIndex = 0
              ..activeHandIndex = 0;
            engine.seats.first.hands.add(
              PlayerHandState(
                hand: BlackjackHand(task.cards),
                fromSplit: task.afterSplit,
              ),
            );
            expect(task.availableActions, engine.availableActions);
          }
          String fingerprint(PilotScenario task) =>
              '${task.cards.map((c) => c.rank.label).join(',')}/${task.dealer!.rank.label}/${task.afterSplit}';
          final seen = lesson.scenarios.take(7).map(fingerprint).toSet();
          expect(
            lesson.scenarios.skip(7).map(fingerprint).any(seen.contains),
            isFalse,
          );
        }
      },
    );
    test(
      '$locale: first answers and split context survive cross-language restoration',
      () {
        final course = lessons(locale);
        final translated = lessons(locale == 'en' ? 'ru' : 'en');
        for (var j = 0; j < course.length; j++) {
          final lesson = course[j];
          var session = DecisionLessonSession(lesson)..begin();
          expect(lesson.resumeSignature, translated[j].resumeSignature);
          for (var index = 0; index < 12; index++) {
            final task = session.current;
            final wrong = task.availableActions
                .firstWhere((a) => a.name != task.expected)
                .name;
            session.answer(index == 2 ? wrong : task.expected);
            session = DecisionLessonSession.restore(
              translated[j],
              session.toJson(),
            );
            if (index == 2) {
              session.answer(task.expected);
              expect(session.firstAnswer, wrong);
            }
            session.next();
            session = DecisionLessonSession.restore(lesson, session.toJson());
          }
          expect(session.correctAnswers, 9);
          expect(session.passed, isTrue);
        }
      },
    );
  }

  test('8+8 Split yields the authored 8+3 hand with DAS and no Surrender', () {
    final pairLesson = lessons('en').last;
    final splitTask = pairLesson.scenarios[5];
    final followup = pairLesson.scenarios[6];
    expect(splitTask.expected, 'split');
    expect(followup.afterSplit, isTrue);
    final engine =
        BlackjackEngine(
            shoe: Shoe.scripted(
              rules: GameRulesProfile.standard,
              cards: ['3', '2', '10'].indexed.map(
                (e) => PilotScenario.cardFromLabel(e.$2, e.$1 + 10),
              ),
            ),
          )
          ..phase = RoundPhase.playerTurn
          ..activeSeatIndex = 0
          ..activeHandIndex = 0;
    engine.seats.first.hands.add(
      PlayerHandState(hand: BlackjackHand(splitTask.cards)),
    );
    engine.applyAction(PlayerAction.split);
    expect(
      engine.activeHand!.hand.cards.map((c) => c.rank.label),
      followup.cards.map((c) => c.rank.label),
    );
    expect(engine.availableActions, followup.availableActions);
    expect(() => engine.applyAction(PlayerAction.surrender), throwsStateError);
    engine.applyAction(PlayerAction.doubleDown);
    expect(engine.seats.first.hands.first.isStanding, isTrue);
    expect(engine.seats.first.hands.first.hand.cards.map((c) => c.rank.label), [
      '8',
      '3',
      '10',
    ]);
  });

  test('changing afterSplit invalidates the saved content signature', () {
    final raw =
        (jsonDecode(
                      File(
                        'assets/content/en/strategy_lessons.json',
                      ).readAsStringSync(),
                    )
                    as List)
                .last
            as Map<String, Object?>;
    final lesson = PilotLesson.fromJson(raw);
    final saved = DecisionLessonSession(lesson).toJson();
    ((raw['scenarios'] as List)[6] as Map)['afterSplit'] = false;
    expect(
      () => DecisionLessonSession.restore(PilotLesson.fromJson(raw), saved),
      throwsFormatException,
    );
  });
}
