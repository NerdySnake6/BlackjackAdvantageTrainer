/// Player seat row, spots, hands, and chips at the table.
library;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../domain/blackjack_engine/blackjack_engine.dart';
import '../../domain/blackjack_engine/game_rules.dart';
import '../../l10n/app_localizations.dart';
import '../../viewmodels/table_view_model.dart';
import 'compact_hand_view.dart';
import 'table_formatters.dart';

class PlayerRow extends StatelessWidget {
  const PlayerRow({super.key, required this.viewModel, required this.compact});

  final TableViewModel viewModel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final engine = viewModel.engine;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final seat in engine.seats)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: PlayerSpot(
                viewModel: viewModel,
                seat: seat,
                isActive:
                    seat.index == engine.activeSeatIndex &&
                    engine.phase == RoundPhase.playerTurn,
                compact: compact,
              ),
            ),
          ),
      ],
    );
  }
}

class PlayerSpot extends StatelessWidget {
  const PlayerSpot({
    super.key,
    required this.viewModel,
    required this.seat,
    required this.isActive,
    required this.compact,
  });

  final TableViewModel viewModel;
  final TableSeat seat;
  final bool isActive;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final isEmpty = seat.role == SeatRole.empty;
    final accent = isActive
        ? AppColors.gold
        : seat.role == SeatRole.human
        ? AppColors.mint
        : Colors.white38;
    final usesLargeText = MediaQuery.textScalerOf(context).scale(1) > 1.1;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      constraints: BoxConstraints(minHeight: compact ? 104 : 112),
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: compact ? 4 : 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: isActive ? 0.32 : 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accent.withValues(alpha: isActive ? 0.9 : 0.4),
          width: isActive ? 2 : 1,
        ),
      ),
      child: isEmpty
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.event_seat_outlined,
                  color: Colors.white24,
                  size: 22,
                ),
                const SizedBox(height: 3),
                Text(
                  strings.empty,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      seat.role == SeatRole.human
                          ? Icons.person_outline
                          : Icons.smart_toy_outlined,
                      color: accent,
                      size: 14,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        strings.seat(seat.index + 1),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                if (seat.hands.isEmpty ||
                    viewModel.visibleCardsForSeat(seat.index) == 0)
                  SizedBox(height: compact ? 52 : 59)
                else
                  SizedBox(
                    height: compact ? 52 : 59,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (
                            var handIndex = 0;
                            handIndex < seat.hands.length;
                            handIndex++
                          )
                            if (handIndex > 0) const SizedBox(width: 3),
                          for (final handState in seat.hands.take(2))
                            PlayerHandView(
                              viewModel: viewModel,
                              seatIndex: seat.index,
                              handState: handState,
                              isActive: isActive,
                            ),
                        ],
                      ),
                    ),
                  ),
                if (!compact && !usesLargeText) ...[
                  const SizedBox(height: 3),
                  PracticeUnitChip(label: strings.practiceUnits, color: accent),
                ],
              ],
            ),
    );
  }
}

class PlayerHandView extends StatelessWidget {
  const PlayerHandView({
    super.key,
    required this.viewModel,
    required this.seatIndex,
    required this.handState,
    required this.isActive,
  });

  final TableViewModel viewModel;
  final int seatIndex;
  final PlayerHandState handState;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final evaluation = viewModel.engine.evaluate(handState.hand);
    final isWinning =
        handState.resultUnits != null && handState.resultUnits! >= 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CompactHandView(
          hand: handState.hand,
          cardWidth: 32,
          visibleCardCount: viewModel.visibleCardsForSeat(seatIndex),
        ),
        Text(
          strings.handTotal(evaluation.total),
          style: TextStyle(
            color: isActive ? AppColors.cream : Colors.white70,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (handState.outcome != null && handState.resultUnits != null)
          Text(
            strings.resultUnits(
              outcomeLabel(strings, handState.outcome!),
              formatUnits(handState.resultUnits!),
            ),
            style: TextStyle(
              color: isWinning ? AppColors.mint : AppColors.danger,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
  }
}

class PracticeUnitChip extends StatelessWidget {
  const PracticeUnitChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
