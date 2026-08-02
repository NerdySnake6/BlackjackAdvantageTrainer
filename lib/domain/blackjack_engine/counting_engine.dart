/// Hi-Lo running-count and true-count calculations.
library;

import 'card.dart';

abstract interface class TrueCountPolicy {
  int convert({required int runningCount, required double decksRemaining});
}

class NearestWholeTrueCountPolicy implements TrueCountPolicy {
  const NearestWholeTrueCountPolicy();

  @override
  int convert({required int runningCount, required double decksRemaining}) {
    if (decksRemaining <= 0) {
      return runningCount;
    }
    return (runningCount / decksRemaining).round();
  }
}

class CountingEngine {
  CountingEngine({this.policy = const NearestWholeTrueCountPolicy()});

  final TrueCountPolicy policy;
  var _runningCount = 0;
  var _cardsSeen = 0;

  int get runningCount => _runningCount;
  int get cardsSeen => _cardsSeen;

  void reveal(PlayingCard card) {
    _runningCount += card.hiLoTag;
    _cardsSeen++;
  }

  void reset() {
    _runningCount = 0;
    _cardsSeen = 0;
  }

  double estimateDecksRemaining(int cardsRemaining) {
    if (cardsRemaining <= 0) {
      return 0;
    }
    final exactDecks = cardsRemaining / 52;
    final nearestHalfDeck = (exactDecks * 2).round() / 2;
    return nearestHalfDeck.clamp(0.5, double.infinity);
  }

  int trueCount(int cardsRemaining) {
    return policy.convert(
      runningCount: runningCount,
      decksRemaining: estimateDecksRemaining(cardsRemaining),
    );
  }
}
