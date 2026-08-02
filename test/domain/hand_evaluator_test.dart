import 'package:blackjack_advantage_trainer/domain/blackjack/card.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack/hand.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const evaluator = HandEvaluator();

  group('HandEvaluator', () {
    test('uses an ace as eleven when it does not bust', () {
      final result = evaluator.evaluate([
        _card(CardRank.ace),
        _card(CardRank.six),
      ]);

      expect(result.total, 17);
      expect(result.isSoft, isTrue);
      expect(result.isBust, isFalse);
    });

    test('reduces aces to one as additional cards arrive', () {
      final result = evaluator.evaluate([
        _card(CardRank.ace),
        _card(CardRank.ace),
        _card(CardRank.nine),
        _card(CardRank.five),
      ]);

      expect(result.total, 16);
      expect(result.isSoft, isFalse);
      expect(result.isBust, isFalse);
    });

    test('distinguishes natural blackjack from a three-card 21', () {
      final natural = evaluator.evaluate([
        _card(CardRank.ace),
        _card(CardRank.king),
      ]);
      final threeCardTwentyOne = evaluator.evaluate([
        _card(CardRank.seven),
        _card(CardRank.seven),
        _card(CardRank.seven),
      ]);

      expect(natural.isBlackjack, isTrue);
      expect(threeCardTwentyOne.total, 21);
      expect(threeCardTwentyOne.isBlackjack, isFalse);
    });

    test('marks totals over 21 as bust', () {
      final result = evaluator.evaluate([
        _card(CardRank.king),
        _card(CardRank.queen),
        _card(CardRank.two),
      ]);

      expect(result.total, 22);
      expect(result.isBust, isTrue);
    });
  });
}

PlayingCard _card(CardRank rank) {
  return PlayingCard(deckIndex: 0, suit: CardSuit.spades, rank: rank);
}
