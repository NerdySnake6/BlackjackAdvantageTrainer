/// Multi-deck shoe with injectable randomness and penetration tracking.
library;

import 'dart:math';

import 'card.dart';
import 'game_rules.dart';

class Shoe {
  Shoe({required this.rules, Random? random})
    : _random = random ?? Random.secure() {
    reset();
  }

  final GameRulesProfile rules;
  final Random _random;
  final List<PlayingCard> _cards = [];
  var _nextCardIndex = 0;

  int get totalCards => rules.deckCount * 52;
  int get dealtCount => _nextCardIndex;
  int get remainingCount => _cards.length - _nextCardIndex;
  double get dealtFraction => dealtCount / totalCards;
  bool get penetrationReached => dealtFraction >= rules.penetration;

  void reset() {
    _cards
      ..clear()
      ..addAll(_buildCards());
    _fisherYatesShuffle(_cards);
    _nextCardIndex = 0;
  }

  PlayingCard draw() {
    if (_nextCardIndex >= _cards.length) {
      throw StateError('Cannot draw from an empty shoe.');
    }
    return _cards[_nextCardIndex++];
  }

  List<PlayingCard> _buildCards() {
    return [
      for (var deckIndex = 0; deckIndex < rules.deckCount; deckIndex++)
        for (final suit in CardSuit.values)
          for (final rank in CardRank.values)
            PlayingCard(deckIndex: deckIndex, suit: suit, rank: rank),
    ];
  }

  void _fisherYatesShuffle(List<PlayingCard> cards) {
    for (var index = cards.length - 1; index > 0; index--) {
      final swapIndex = _random.nextInt(index + 1);
      final current = cards[index];
      cards[index] = cards[swapIndex];
      cards[swapIndex] = current;
    }
  }
}
