/// Scrollable felt layout with unclipped, readable dealer and player hands.
library;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../viewmodels/table_view_model.dart';
import 'compact_hand_view.dart';
import 'player_spots_view.dart';

class TableTopView extends StatelessWidget {
  const TableTopView({super.key, required this.viewModel});

  final TableViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF0C5C4F),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF6F4A26), width: 3),
          ),
          child: SingleChildScrollView(
            key: const ValueKey('table-content-scroll'),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                DealerSpot(viewModel: viewModel),
                const SizedBox(height: 12),
                PlayerRow(
                  viewModel: viewModel,
                  compact: constraints.maxHeight < 300,
                ),
                if (viewModel.isDealing) DealingBadge(viewModel: viewModel),
              ],
            ),
          ),
        );
      },
    );
  }
}

class DealerSpot extends StatelessWidget {
  const DealerSpot({super.key, required this.viewModel});

  final TableViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final engine = viewModel.engine;
    final evaluation = engine.evaluate(engine.dealerHand);
    final visibleCards = viewModel.visibleDealerCards;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            const CircleAvatar(
              radius: 15,
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.ink,
              child: Icon(Icons.smart_toy_outlined, size: 18),
            ),
            const SizedBox(width: 7),
            Text(
              engine.dealerHoleRevealed
                  ? '${strings.dealer} · ${strings.handTotal(evaluation.total)}'
                  : strings.dealer,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: CompactHandView(
                hand: engine.dealerHand,
                cardWidth: 64,
                visibleCardCount: visibleCards,
                hideSecondCard: !engine.dealerHoleRevealed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DealingBadge extends StatelessWidget {
  const DealingBadge({super.key, required this.viewModel});

  final TableViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: viewModel.dealProgress,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            strings.dealingCards,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
