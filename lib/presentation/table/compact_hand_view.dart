/// Compact fanned playing card stack for dealer and player hands.
library;

import 'package:flutter/material.dart';

import '../../domain/blackjack_engine/hand.dart';
import '../widgets/playing_card_view.dart';

class CompactHandView extends StatelessWidget {
  const CompactHandView({
    super.key,
    required this.hand,
    required this.cardWidth,
    this.visibleCardCount,
    this.hideSecondCard = false,
  });

  final BlackjackHand hand;
  final double cardWidth;
  final int? visibleCardCount;
  final bool hideSecondCard;

  @override
  Widget build(BuildContext context) {
    final count = (visibleCardCount ?? hand.cards.length).clamp(
      0,
      hand.cards.length,
    );
    if (count == 0) {
      return SizedBox(width: cardWidth, height: cardWidth * 1.42);
    }
    final cards = hand.cards.take(count).toList();
    final offset = cardWidth * 0.48;
    final width = cardWidth + (cards.length - 1) * offset;
    return SizedBox(
      width: width,
      height: cardWidth * 1.42,
      child: Stack(
        children: [
          for (var index = 0; index < cards.length; index++)
            Positioned(
              left: index * offset,
              child: PlayingCardView(
                card: cards[index],
                width: cardWidth,
                hidden: hideSecondCard && index == 1,
              ),
            ),
        ],
      ),
    );
  }
}
