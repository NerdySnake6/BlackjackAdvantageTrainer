import 'dart:convert';
import 'dart:io';

import 'package:blackjack_advantage_trainer/domain/blackjack_engine/card.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/game_rules.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/hand.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/strategy_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const strategy = StrategyEngine();
  final allActions = PlayerAction.values.toSet();

  PlayerAction action(List<CardRank> player, CardRank dealer) {
    return strategy.recommend(
      hand: BlackjackHand(player.map(_card)),
      dealerUpCard: _card(dealer),
      rules: GameRulesProfile.standard,
      availableActions: allActions,
    );
  }

  group('standard S17 basic strategy', () {
    test(
      'matches the complete independently transcribed reference fixture',
      () async {
        final fixture =
            jsonDecode(
                  await File(
                    'test/fixtures/standard_strategy_s17_das_ls.json',
                  ).readAsString(),
                )!
                as Map<String, Object?>;
        expect(fixture['profileId'], GameRulesProfile.standard.id);
        expect(fixture['source'], startsWith('https://wizardofodds.com/'));
        expect(
          fixture['independentlyConfirmedBy'],
          'https://www.blackjackapprenticeship.com/wp-content/uploads/'
          '2024/09/S17-Basic-Strategy.pdf',
        );
        expect(fixture['independentCheckDate'], '2026-09-02');
        expect(fixture['independentCheckResult'], isNotEmpty);

        final dealerOrder = (fixture['dealerOrder']! as List<Object?>)
            .cast<String>();
        final codes = (fixture['codes']! as Map<String, Object?>)
            .cast<String, String>();

        void verifyRows(
          String section,
          List<CardRank> Function(String row) handForRow,
        ) {
          final rows = (fixture[section]! as Map<String, Object?>)
              .cast<String, String>();
          for (final row in rows.entries) {
            expect(
              row.value.length,
              dealerOrder.length,
              reason: '$section ${row.key} must cover every dealer up-card',
            );
            for (var index = 0; index < dealerOrder.length; index++) {
              final expectedName = codes[row.value[index]]!;
              expect(
                action(handForRow(row.key), _rank(dealerOrder[index])).name,
                expectedName,
                reason: '$section ${row.key} vs ${dealerOrder[index]}',
              );
            }
          }
        }

        verifyRows('hard', _hardHand);
        verifyRows(
          'soft',
          (row) => [CardRank.ace, _rank('${int.parse(row) - 11}')],
        );
        verifyRows('pairs', (row) {
          final rank = _rank(row);
          return [rank, rank];
        });
      },
    );

    test('matches the independently transcribed action constraints', () async {
      final fixture =
          jsonDecode(
                await File(
                  'test/fixtures/standard_strategy_action_constraints.json',
                ).readAsString(),
              )!
              as Map<String, Object?>;
      expect(fixture['profileId'], GameRulesProfile.standard.id);
      expect(fixture['source'], startsWith('https://wizardofodds.com/'));
      expect(fixture['rulesSource'], startsWith('https://wizardofodds.com/'));
      expect(
        fixture['surrenderSource'],
        startsWith('https://wizardofodds.com/'),
      );
      expect(fixture['sourceCheckedAt'], '2026-09-05');
      expect(fixture['excludedState'], isNotEmpty);

      final cases = (fixture['cases']! as List<Object?>)
          .cast<Map<String, Object?>>();
      expect(cases, hasLength(25));
      for (final scenario in cases) {
        final recommendation = strategy.recommendWithReason(
          hand: BlackjackHand(
            (scenario['cards']! as List<Object?>)
                .cast<String>()
                .map(_rank)
                .map(_card),
          ),
          dealerUpCard: _card(_rank(scenario['dealer']! as String)),
          rules: GameRulesProfile.standard,
          availableActions: (scenario['availableActions']! as List<Object?>)
              .cast<String>()
              .map(_action)
              .toSet(),
        );

        expect(
          recommendation.action.name,
          scenario['expectedAction'],
          reason: scenario['id']! as String,
        );
        expect(
          recommendation.reason.name,
          scenario['expectedReason'],
          reason: scenario['id']! as String,
        );
      }
    });

    test('stands hard 12 against dealer 4', () {
      expect(
        action([CardRank.ten, CardRank.two], CardRank.four),
        PlayerAction.stand,
      );
    });

    test('doubles hard 11 against dealer 6', () {
      expect(
        action([CardRank.six, CardRank.five], CardRank.six),
        PlayerAction.doubleDown,
      );
    });

    test('hits soft 18 against dealer 9', () {
      expect(
        action([CardRank.ace, CardRank.seven], CardRank.nine),
        PlayerAction.hit,
      );
    });

    // Independent S17 reference: Wizard of Odds, 4–8 deck text strategy,
    // Double then Hit/Stand sections, checked 2026-09-05:
    // https://wizardofodds.com/games/blackjack/strategy/4-decks/
    group('soft 18 double-or-stand', () {
      for (final dealer in [
        CardRank.three,
        CardRank.four,
        CardRank.five,
        CardRank.six,
      ]) {
        test('doubles against ${dealer.name} when available', () {
          final recommendation = strategy.recommendWithReason(
            hand: BlackjackHand([_card(CardRank.ace), _card(CardRank.seven)]),
            dealerUpCard: _card(dealer),
            rules: GameRulesProfile.standard,
            availableActions: allActions,
          );

          expect(recommendation.action, PlayerAction.doubleDown);
          expect(recommendation.reason, StrategyReason.doubleSoftTotal);
        });

        for (final ranks in [
          [CardRank.ace, CardRank.seven],
          [CardRank.ace, CardRank.two, CardRank.five],
          [CardRank.ace, CardRank.ace, CardRank.six],
        ]) {
          test('stands $ranks against ${dealer.name} without double', () {
            final recommendation = strategy.recommendWithReason(
              hand: BlackjackHand(ranks.map(_card)),
              dealerUpCard: _card(dealer),
              rules: GameRulesProfile.standard,
              availableActions: {PlayerAction.hit, PlayerAction.stand},
            );

            expect(recommendation.action, PlayerAction.stand);
            expect(
              recommendation.reason,
              StrategyReason.unavailableActionFallback,
            );
          });
        }
      }
    });

    test('splits eights and stands on paired tens', () {
      expect(
        action([CardRank.eight, CardRank.eight], CardRank.ten),
        PlayerAction.split,
      );
      expect(
        action([CardRank.king, CardRank.queen], CardRank.six),
        PlayerAction.stand,
      );
    });

    test('uses late surrender for hard 15 against dealer 10', () {
      expect(
        action([CardRank.nine, CardRank.six], CardRank.ten),
        PlayerAction.surrender,
      );
    });

    test('falls back to hit when double is unavailable', () {
      final recommendation = strategy.recommendWithReason(
        hand: BlackjackHand([_card(CardRank.six), _card(CardRank.five)]),
        dealerUpCard: _card(CardRank.six),
        rules: GameRulesProfile.standard,
        availableActions: {PlayerAction.hit, PlayerAction.stand},
      );

      expect(recommendation.action, PlayerAction.hit);
      expect(recommendation.reason, StrategyReason.unavailableActionFallback);
    });
  });
}

List<CardRank> _hardHand(String total) {
  return switch (int.parse(total)) {
    5 => [CardRank.two, CardRank.three],
    6 => [CardRank.two, CardRank.four],
    7 => [CardRank.two, CardRank.five],
    8 => [CardRank.three, CardRank.five],
    9 => [CardRank.four, CardRank.five],
    10 => [CardRank.four, CardRank.six],
    11 => [CardRank.five, CardRank.six],
    12 => [CardRank.five, CardRank.seven],
    13 => [CardRank.six, CardRank.seven],
    14 => [CardRank.six, CardRank.eight],
    15 => [CardRank.seven, CardRank.eight],
    16 => [CardRank.seven, CardRank.nine],
    17 => [CardRank.seven, CardRank.ten],
    _ => throw ArgumentError.value(total, 'total'),
  };
}

CardRank _rank(String label) {
  return switch (label) {
    'A' => CardRank.ace,
    '2' => CardRank.two,
    '3' => CardRank.three,
    '4' => CardRank.four,
    '5' => CardRank.five,
    '6' => CardRank.six,
    '7' => CardRank.seven,
    '8' => CardRank.eight,
    '9' => CardRank.nine,
    '10' => CardRank.ten,
    _ => throw ArgumentError.value(label, 'label'),
  };
}

PlayingCard _card(CardRank rank) {
  return PlayingCard(deckIndex: 0, suit: CardSuit.spades, rank: rank);
}

PlayerAction _action(String name) {
  return PlayerAction.values.singleWhere((action) => action.name == name);
}
