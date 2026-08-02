/// Landscape guided blackjack practice table.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../domain/blackjack_engine/blackjack_engine.dart';
import '../../domain/blackjack_engine/game_rules.dart';
import '../../domain/blackjack_engine/hand.dart';
import '../../l10n/app_localizations.dart';
import '../../viewmodels/table_view_model.dart';
import '../widgets/playing_card_view.dart';

class TableScreen extends StatefulWidget {
  const TableScreen({super.key});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TableViewModel(),
      child: const _TableView(),
    );
  }
}

class _TableView extends StatelessWidget {
  const _TableView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TableViewModel>();
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          child: Column(
            children: [
              _TableHeader(viewModel: viewModel),
              const SizedBox(height: 8),
              Expanded(child: _TableTop(viewModel: viewModel)),
              const SizedBox(height: 8),
              _TableActionTray(viewModel: viewModel),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.viewModel});

  final TableViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final engine = viewModel.engine;
    final canConfigure =
        !viewModel.isDealing &&
        engine.phase != RoundPhase.playerTurn &&
        engine.phase != RoundPhase.dealerTurn;
    return Row(
      children: [
        IconButton(
          onPressed: () => context.go('/learn'),
          tooltip: strings.backToPath,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.guidedMode,
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              engine.rules.id == GameRulesProfile.standard.id
                  ? strings.standardRulesName
                  : engine.rules.name,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        const Spacer(),
        _HeaderPill(
          icon: Icons.speed_rounded,
          label: strings.currentCount(engine.countingEngine.runningCount),
          color: AppColors.mint,
        ),
        const SizedBox(width: 8),
        _HeaderPill(
          icon: Icons.layers_outlined,
          label: strings.shoeStatus(engine.dealtCards, engine.totalCards),
          color: Colors.white70,
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: canConfigure
              ? () => _showSeatConfiguration(context)
              : null,
          tooltip: strings.configureSeats,
          icon: const Icon(Icons.tune_rounded),
        ),
      ],
    );
  }

  void _showSeatConfiguration(BuildContext context) {
    final viewModel = context.read<TableViewModel>();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => ChangeNotifierProvider.value(
        value: viewModel,
        child: const _SeatConfigurationSheet(),
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableTop extends StatelessWidget {
  const _TableTop({required this.viewModel});

  final TableViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableRadius = (constraints.maxWidth * 0.18).clamp(90.0, 220.0);
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
                painter: _TableMarkingsPainter(),
                child: Stack(
                  children: [
                    Positioned(
                      top: 12,
                      left: 0,
                      right: 0,
                      child: _DealerSpot(viewModel: viewModel),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 54, 12, 14),
                        child: _PlayerRow(viewModel: viewModel),
                      ),
                    ),
                    if (viewModel.isDealing)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 10,
                        child: Center(
                          child: _DealingBadge(viewModel: viewModel),
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

class _TableMarkingsPainter extends CustomPainter {
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

class _DealerSpot extends StatelessWidget {
  const _DealerSpot({required this.viewModel});

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
            _CompactHand(
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

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.viewModel});

  final TableViewModel viewModel;

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
              child: _PlayerSpot(
                viewModel: viewModel,
                seat: seat,
                isActive:
                    seat.index == engine.activeSeatIndex &&
                    engine.phase == RoundPhase.playerTurn,
              ),
            ),
          ),
      ],
    );
  }
}

class _PlayerSpot extends StatelessWidget {
  const _PlayerSpot({
    required this.viewModel,
    required this.seat,
    required this.isActive,
  });

  final TableViewModel viewModel;
  final TableSeat seat;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final isEmpty = seat.role == SeatRole.empty;
    final accent = isActive
        ? AppColors.gold
        : seat.role == SeatRole.human
        ? AppColors.mint
        : Colors.white38;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
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
                Icon(
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
                  const SizedBox(height: 59)
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (
                        var handIndex = 0;
                        handIndex < seat.hands.length;
                        handIndex++
                      )
                        if (handIndex > 0) const SizedBox(width: 3),
                      for (final handState in seat.hands.take(2))
                        _PlayerHand(
                          viewModel: viewModel,
                          seatIndex: seat.index,
                          handState: handState,
                          isActive: isActive,
                        ),
                    ],
                  ),
                const SizedBox(height: 3),
                _PracticeUnitChip(label: strings.practiceUnits, color: accent),
              ],
            ),
    );
  }
}

class _PlayerHand extends StatelessWidget {
  const _PlayerHand({
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
        _CompactHand(
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
              _outcomeLabel(strings, handState.outcome!),
              _formatUnits(handState.resultUnits!),
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

class _PracticeUnitChip extends StatelessWidget {
  const _PracticeUnitChip({required this.label, required this.color});

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

class _DealingBadge extends StatelessWidget {
  const _DealingBadge({required this.viewModel});

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

class _TableActionTray extends StatelessWidget {
  const _TableActionTray({required this.viewModel});

  final TableViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final engine = viewModel.engine;
    if (viewModel.isDealing) {
      return SizedBox(
        height: 48,
        child: Center(
          child: Text(
            strings.dealingCards,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ),
      );
    }
    if (engine.phase == RoundPhase.waiting) {
      return SizedBox(
        height: 48,
        child: FilledButton.icon(
          onPressed: viewModel.startRound,
          icon: const Icon(Icons.style_rounded),
          label: Text(strings.startFirstRound),
        ),
      );
    }
    if (engine.phase == RoundPhase.complete) {
      return SizedBox(
        height: 48,
        child: FilledButton.icon(
          onPressed: viewModel.startRound,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(strings.newRound),
        ),
      );
    }
    if (engine.phase == RoundPhase.dealerTurn) {
      return SizedBox(
        height: 48,
        child: Center(
          child: Text(
            strings.dealerTurn,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ),
      );
    }
    return SizedBox(height: 48, child: _ActionBar(viewModel: viewModel));
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.viewModel});

  final TableViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final available = viewModel.engine.availableActions;
    final actions = [
      (PlayerAction.hit, strings.hit),
      (PlayerAction.stand, strings.stand),
      (PlayerAction.doubleDown, strings.doubleAction),
      (PlayerAction.split, strings.split),
      (PlayerAction.surrender, strings.surrender),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          strings.turnPrompt,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        ),
        const SizedBox(width: 10),
        for (final item in actions)
          if (available.contains(item.$1))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: FilledButton.tonal(
                onPressed: () => viewModel.applyAction(item.$1),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(78, 42),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: Text(item.$2),
              ),
            ),
      ],
    );
  }
}

class _CompactHand extends StatelessWidget {
  const _CompactHand({
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

class _SeatConfigurationSheet extends StatelessWidget {
  const _SeatConfigurationSheet();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final viewModel = context.watch<TableViewModel>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.configureSeats,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              strings.configureSeatsHint,
              style: const TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final seat in viewModel.engine.seats)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: OutlinedButton(
                        onPressed: () => viewModel.cycleSeat(seat.index),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Column(
                          children: [
                            Icon(_roleIcon(seat.role)),
                            const SizedBox(height: 5),
                            Text(
                              strings.seat(seat.index + 1),
                              style: const TextStyle(fontSize: 11),
                            ),
                            Text(
                              _roleLabel(strings, seat.role),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.done),
            ),
          ],
        ),
      ),
    );
  }
}

String _roleLabel(AppLocalizations strings, SeatRole role) => switch (role) {
  SeatRole.human => strings.human,
  SeatRole.bot => strings.bot,
  SeatRole.empty => strings.empty,
};

IconData _roleIcon(SeatRole role) => switch (role) {
  SeatRole.human => Icons.person,
  SeatRole.bot => Icons.smart_toy_outlined,
  SeatRole.empty => Icons.event_seat_outlined,
};

String _outcomeLabel(AppLocalizations strings, HandOutcome outcome) =>
    switch (outcome) {
      HandOutcome.blackjack => strings.outcomeBlackjack,
      HandOutcome.win => strings.outcomeWin,
      HandOutcome.push => strings.outcomePush,
      HandOutcome.loss => strings.outcomeLoss,
      HandOutcome.surrender => strings.outcomeSurrender,
    };

String _formatUnits(double units) {
  final sign = units > 0 ? '+' : '';
  final value = units == units.roundToDouble()
      ? units.toInt().toString()
      : units.toStringAsFixed(1);
  return '$sign$value';
}
