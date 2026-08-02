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
      final recommendation = strategy.recommend(
        hand: BlackjackHand([_card(CardRank.six), _card(CardRank.five)]),
        dealerUpCard: _card(CardRank.six),
        rules: GameRulesProfile.standard,
        availableActions: {PlayerAction.hit, PlayerAction.stand},
      );

      expect(recommendation, PlayerAction.hit);
    });
  });
}

PlayingCard _card(CardRank rank) {
  return PlayingCard(deckIndex: 0, suit: CardSuit.spades, rank: rank);
}
