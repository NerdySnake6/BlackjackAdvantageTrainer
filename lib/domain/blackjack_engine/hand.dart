/// Hand evaluation and mutable hand state for blackjack rounds.
library;

import 'card.dart';

class HandEvaluation {
  const HandEvaluation({
    required this.total,
    required this.isSoft,
    required this.isBlackjack,
    required this.isBust,
  });

  final int total;
  final bool isSoft;
  final bool isBlackjack;
  final bool isBust;
}

class HandEvaluator {
  const HandEvaluator();

  HandEvaluation evaluate(Iterable<PlayingCard> cards) {
    final cardList = cards.toList(growable: false);
    var total = cardList.fold<int>(
      0,
      (sum, card) => sum + card.rank.blackjackValue,
    );
    var acesCountedAsEleven = 0;

    for (final card in cardList) {
      if (card.rank == CardRank.ace && total + 10 <= 21) {
        total += 10;
        acesCountedAsEleven++;
      }
    }

    return HandEvaluation(
      total: total,
      isSoft: acesCountedAsEleven > 0,
      isBlackjack: cardList.length == 2 && total == 21,
      isBust: total > 21,
    );
  }
}

class BlackjackHand {
  BlackjackHand([Iterable<PlayingCard> cards = const []])
    : cards = List<PlayingCard>.of(cards);

  final List<PlayingCard> cards;

  void add(PlayingCard card) => cards.add(card);
}
