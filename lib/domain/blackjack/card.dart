/// Immutable playing-card model used by the blackjack domain.
library;

enum CardSuit { clubs, diamonds, hearts, spades }

enum CardRank {
  ace('A', 1),
  two('2', 2),
  three('3', 3),
  four('4', 4),
  five('5', 5),
  six('6', 6),
  seven('7', 7),
  eight('8', 8),
  nine('9', 9),
  ten('10', 10),
  jack('J', 10),
  queen('Q', 10),
  king('K', 10);

  const CardRank(this.label, this.blackjackValue);

  final String label;
  final int blackjackValue;
}

class PlayingCard {
  const PlayingCard({
    required this.deckIndex,
    required this.suit,
    required this.rank,
  });

  final int deckIndex;
  final CardSuit suit;
  final CardRank rank;

  String get id => '$deckIndex-${suit.name}-${rank.name}';

  int get hiLoTag {
    return switch (rank) {
      CardRank.two ||
      CardRank.three ||
      CardRank.four ||
      CardRank.five ||
      CardRank.six => 1,
      CardRank.seven || CardRank.eight || CardRank.nine => 0,
      _ => -1,
    };
  }

  bool get isRed => suit == CardSuit.diamonds || suit == CardSuit.hearts;

  String get suitSymbol => switch (suit) {
    CardSuit.clubs => '♣',
    CardSuit.diamonds => '♦',
    CardSuit.hearts => '♥',
    CardSuit.spades => '♠',
  };

  @override
  String toString() => '${rank.label}$suitSymbol';
}
