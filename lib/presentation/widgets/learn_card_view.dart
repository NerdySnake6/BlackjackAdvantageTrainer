/// Scalable, contrast-checked cards with one localized screen-reader label.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/blackjack_engine/card.dart';
import '../../l10n/app_localizations.dart';
import 'playing_card_view.dart';

class LearnCardView extends StatelessWidget {
  const LearnCardView({super.key, required this.card, required this.width});
  static const redInk = Color(0xFFB02A3B);
  final PlayingCard card;
  final double width;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final rank = switch (card.rank) {
      CardRank.ace => strings.cardAce,
      CardRank.jack => strings.cardJack,
      CardRank.queen => strings.cardQueen,
      CardRank.king => strings.cardKing,
      _ => card.rank.label,
    };
    final suit = switch (card.suit) {
      CardSuit.clubs => strings.cardClubs,
      CardSuit.diamonds => strings.cardDiamonds,
      CardSuit.hearts => strings.cardHearts,
      CardSuit.spades => strings.cardSpades,
    };
    final scaledWidth =
        MediaQuery.textScalerOf(context).scale(width * 0.28) / 0.28;
    return LayoutBuilder(
      builder: (context, constraints) => Semantics(
        image: true,
        label: strings.cardDescription(rank, suit),
        excludeSemantics: true,
        child: PlayingCardView(
          card: card,
          width: math.min(scaledWidth, constraints.maxWidth),
          redColor: redInk,
        ),
      ),
    );
  }
}
