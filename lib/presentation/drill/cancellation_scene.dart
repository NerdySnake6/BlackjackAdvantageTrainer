/// Short Hi-Lo sequence scene with explicit card tags and running count.
library;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../domain/blackjack_engine/card.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/playing_card_view.dart';

/// Reveals a short sequence one card at a time for cancellation practice.
class CancellationScene extends StatelessWidget {
  const CancellationScene({
    super.key,
    required this.sequence,
    required this.revealedCount,
    required this.runningCount,
    required this.onRevealNext,
  });

  final List<PlayingCard> sequence;
  final int revealedCount;
  final int runningCount;
  final VoidCallback onRevealNext;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final visibleCount = revealedCount.clamp(0, sequence.length);
    final visibleCards = sequence.take(visibleCount).toList(growable: false);
    final isComplete = visibleCount == sequence.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  strings.cardsSeen(visibleCount),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                _CountBadge(runningCount: runningCount),
              ],
            ),
            const SizedBox(height: 16),
            if (visibleCards.isEmpty)
              Text(
                strings.revealInstruction,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var index = 0; index < visibleCards.length; index++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _RevealedCard(
                          card: visibleCards[index],
                          isCancelled: _isCancelledPair(visibleCards, index),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: isComplete ? null : onRevealNext,
              child: Text(strings.nextCard),
            ),
          ],
        ),
      ),
    );
  }

  bool _isCancelledPair(List<PlayingCard> cards, int index) {
    if (index == 0) {
      return false;
    }
    final previousTag = cards[index - 1].hiLoTag;
    final currentTag = cards[index].hiLoTag;
    return previousTag != 0 && previousTag + currentTag == 0;
  }
}

class _RevealedCard extends StatelessWidget {
  const _RevealedCard({required this.card, required this.isCancelled});

  final PlayingCard card;
  final bool isCancelled;

  @override
  Widget build(BuildContext context) {
    final tag = card.hiLoTag;
    final tagColor = tag > 0
        ? AppColors.gold
        : tag < 0
        ? AppColors.mint
        : Colors.white60;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PlayingCardView(card: card, width: 58),
        const SizedBox(height: 5),
        DecoratedBox(
          decoration: BoxDecoration(
            color: tagColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tagColor.withValues(alpha: 0.45)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: Text(
              tag > 0
                  ? '+1'
                  : tag < 0
                  ? '−1'
                  : '0',
              style: TextStyle(color: tagColor, fontWeight: FontWeight.w900),
            ),
          ),
        ),
        if (isCancelled)
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(
              Icons.sync_alt_rounded,
              size: 15,
              color: AppColors.gold,
            ),
          ),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.runningCount});

  final int runningCount;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.mint.withValues(alpha: 0.35)),
      ),
      child: Text(
        strings.currentCount(runningCount),
        style: const TextStyle(
          color: AppColors.mint,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
