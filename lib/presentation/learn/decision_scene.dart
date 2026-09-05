/// Reusable card-and-action scene for strategy lesson decisions.
library;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../domain/blackjack_engine/card.dart';
import '../../domain/blackjack_engine/game_rules.dart';
import '../../domain/blackjack_engine/hand.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/playing_card_view.dart';
import '../table/table_formatters.dart';

/// Presents the player hand, dealer up-card, and every possible action.
///
/// Unavailable actions remain visible and disabled so a learner can connect a
/// fallback decision with the hand state instead of inferring that an action
/// was omitted by accident. The caller owns the strategy and progression.
class DecisionScene extends StatelessWidget {
  const DecisionScene({
    super.key,
    required this.playerHand,
    required this.dealerUpCard,
    required this.availableActions,
    required this.onAction,
    this.enabled = true,
  });

  final BlackjackHand playerHand;
  final PlayingCard dealerUpCard;
  final Set<PlayerAction> availableActions;
  final ValueChanged<PlayerAction> onAction;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final evaluator = const HandEvaluator();
    final playerEvaluation = evaluator.evaluate(playerHand.cards);
    final actions = [
      PlayerAction.hit,
      PlayerAction.stand,
      PlayerAction.doubleDown,
      PlayerAction.split,
      PlayerAction.surrender,
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _HandPanel(
                    label: strings.dealer,
                    hand: BlackjackHand([dealerUpCard]),
                    total: null,
                    accent: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HandPanel(
                    label: strings.turnPrompt,
                    hand: playerHand,
                    total: strings.handTotal(playerEvaluation.total),
                    accent: AppColors.mint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              availableActions.contains(PlayerAction.doubleDown)
                  ? strings.pilotDoubleAvailable
                  : strings.pilotDoubleUnavailable,
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final action in actions)
                  _ActionButton(
                    label: actionLabel(strings, action),
                    enabled: enabled && availableActions.contains(action),
                    onPressed: () => onAction(action),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HandPanel extends StatelessWidget {
  const _HandPanel({
    required this.label,
    required this.hand,
    required this.total,
    required this.accent,
  });

  final String label;
  final BlackjackHand hand;
  final String? total;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: accent,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            for (final card in hand.cards)
              PlayingCardView(card: card, width: 52),
          ],
        ),
        if (total != null) ...[
          const SizedBox(height: 4),
          Text(
            total!,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: enabled ? onPressed : null,
      child: Text(label),
    );
  }
}
