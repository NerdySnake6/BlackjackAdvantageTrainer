/// Felt tabletop layout, dealer spot, and table markings painter.
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
        final tableRadius = (constraints.maxWidth * 0.18).clamp(90.0, 220.0);
        final compact = constraints.maxHeight < 300;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                center: Alignment(0, -0.2),
                radius: 1.2,
                colors: [
                  Color(0xFF197A69),
                  Color(0xFF0C5C4F),
                  Color(0xFF063B35),
                ],
              ),
              borderRadius: BorderRadius.all(
                Radius.elliptical(tableRadius, tableRadius * 0.72),
              ),
              border: Border.all(color: const Color(0xFF6F4A26), width: 8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.all(
                Radius.elliptical(tableRadius, tableRadius * 0.72),
              ),
              child: CustomPaint(
                painter: TableMarkingsPainter(),
                child: Stack(
                  children: [
                    Positioned(
                      top: 12,
                      left: 0,
                      right: 0,
                      child: DealerSpot(viewModel: viewModel),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          12,
                          compact ? 30 : 54,
                          12,
                          14,
                        ),
                        child: PlayerRow(
                          viewModel: viewModel,
                          compact: compact,
                        ),
                      ),
                    ),
                    if (viewModel.isDealing)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 10,
                        child: Center(
                          child: DealingBadge(viewModel: viewModel),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class TableMarkingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final center = Offset(size.width / 2, size.height * 0.58);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.24),
        width: size.width * 0.56,
        height: size.height * 0.58,
      ),
      0.15,
      2.84,
      false,
      linePaint,
    );
    canvas.drawCircle(center, size.shortestSide * 0.08, linePaint);
    canvas.drawCircle(center, size.shortestSide * 0.055, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
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
            CompactHandView(
              hand: engine.dealerHand,
              cardWidth: 42,
              visibleCardCount: visibleCards,
              hideSecondCard: !engine.dealerHoleRevealed,
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
