/// Pair-completion positions for disjoint Hi-Lo cancellations.
library;

import '../blackjack_engine/card.dart';

Set<int> cancellationEnds(List<PlayingCard> cards) {
  final unmatched = <int>[];
  final ends = <int>{};
  for (var index = 0; index < cards.length; index++) {
    final tag = cards[index].hiLoTag;
    if (tag == 0) continue;
    if (unmatched.isNotEmpty && cards[unmatched.last].hiLoTag == -tag) {
      unmatched.removeLast();
      ends.add(index);
    } else {
      unmatched.add(index);
    }
  }
  return ends;
}
