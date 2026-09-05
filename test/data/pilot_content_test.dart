import 'dart:convert';
import 'dart:io';

import 'package:blackjack_advantage_trainer/data/content_repository.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/game_rules.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/hand.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/strategy_engine.dart';
import 'package:blackjack_advantage_trainer/domain/learning/pilot_lesson.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'all authored EN/RU tasks match independent iteration 6 references',
    () async {
      final reference =
          jsonDecode(
                File(
                  'test/fixtures/iteration6_lesson_pack_reference.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final packages = reference['packages'] as List;
      final hard = {
        for (final row in packages[0]['independentTest']['cases'] as List)
          row['dealer']: row['expectedAction'],
      };
      final soft = {
        for (final row
            in packages[1]['independentTest']['twoCardCases'] as List)
          row['dealer']: row['expectedAction'],
      };
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
      final en = await ContentRepository().loadCatalog();
      final ru = await ContentRepository().loadCatalog(localeCode: 'ru');
      expect(en.lessons.length, 6);
      expect(en.pilotLessons.map((l) => l.id), [
        'hard-12',
        'soft-18',
        'hi-lo-cancellation',
      ]);
      for (var i = 0; i < en.pilotLessons.length; i++) {
        final english = en.pilotLessons[i];
        final russian = ru.pilotLessons[i];
        expect(russian.id, english.id);
        expect(russian.skillId, english.skillId);
        expect(russian.version, english.version);
        expect(russian.title, isNot(english.title));
        expect(russian.theory, isNot(english.theory));
        final practice = english.scenarios.take(7).map(_fingerprint).toSet();
        for (final task in english.scenarios.skip(7)) {
          expect(practice, isNot(contains(_fingerprint(task))));
        }
        for (var j = 0; j < 12; j++) {
          final task = english.scenarios[j];
          final translated = russian.scenarios[j];
          expect(translated.id, task.id);
          expect(_fingerprint(translated), _fingerprint(task));
          expect(translated.availableActions, task.availableActions);
          expect(translated.expected, task.expected);
          expect(translated.explanation, isNot(task.explanation));
          expect(translated.contrast, isNot(task.contrast));
          expect(task.explanation, isNotEmpty);
          expect(task.contrast, isNotEmpty);
          if (task.isCounting) {
            final expected = task.cards.fold(
              task.initialCount,
              (sum, card) => sum + tags[card.rank.label]!,
            );
            expect(task.expected, expected.toString());
            expect(task.countAfter(task.cards.length), expected);
            expect(translated.mistakes['count'], isNotEmpty);
          } else {
            final evaluation = const HandEvaluator().evaluate(task.cards);
            expect(evaluation.total, i == 0 ? 12 : 18);
            expect(evaluation.isSoft, i == 1);
            var expected = (i == 0 ? hard : soft)[task.dealer!.rank.label];
            if (expected == 'doubleDown' && task.cards.length > 2) {
              expected = 'stand'; // Independent fallback fixed in iteration 2.
            }
            expect(task.expected, expected);
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
            expect(
              task.availableActions.contains(PlayerAction.doubleDown),
              task.cards.length == 2,
            );
            for (final action in task.availableActions) {
              expect(task.mistakes[action.name], isNotEmpty);
              expect(translated.mistakes[action.name], isNotEmpty);
            }
          }
        }
      }
    },
  );
}

String _fingerprint(PilotScenario task) {
  final ranks = task.cards.map((c) => c.rank.label).toList();
  if (!task.isCounting) ranks.sort();
  return '${ranks.join(",")}|${task.dealer?.rank.label}|${task.initialCount}';
}
