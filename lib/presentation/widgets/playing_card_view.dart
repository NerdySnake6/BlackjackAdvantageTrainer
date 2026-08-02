/// Reusable visual representation of a playing card.
library;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../domain/blackjack_engine/card.dart';

class PlayingCardView extends StatelessWidget {
  const PlayingCardView({
    required this.card,
    this.width = 72,
    this.hidden = false,
    super.key,
  });

  final PlayingCard card;
  final double width;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final height = width * 1.42;
    if (hidden) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF12314C),
          borderRadius: BorderRadius.circular(width * 0.12),
          border: Border.all(color: AppColors.gold, width: 2),
        ),
        child: Center(
          child: Icon(
            Icons.auto_awesome,
            color: AppColors.gold,
            size: width * 0.35,
          ),
        ),
      );
    }

    final cardColor = card.isRed ? const Color(0xFFC73B48) : AppColors.ink;
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(width * 0.1),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(width * 0.12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.rank.label,
            style: TextStyle(
              color: cardColor,
              fontSize: width * 0.28,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          Text(
            card.suitSymbol,
            style: TextStyle(
              color: cardColor,
              fontSize: width * 0.25,
              height: 1,
            ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              card.suitSymbol,
              style: TextStyle(color: cardColor, fontSize: width * 0.34),
            ),
          ),
        ],
      ),
    );
  }
}
