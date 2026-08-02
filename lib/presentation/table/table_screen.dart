/// Landscape five-seat blackjack training table.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final strings = AppLocalizations.of(context);
    final viewModel = context.watch<TableViewModel>();
    final engine = viewModel.engine;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        title: Text(engine.rules.name, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            onPressed:
                engine.phase == RoundPhase.playerTurn ||
                    engine.phase == RoundPhase.dealerTurn
                ? null
                : () => _showSeatConfiguration(context),
            tooltip: strings.configureSeats,
            icon: const Icon(Icons.event_seat_outlined),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            radius: 1.1,
            colors: [AppColors.feltLight, AppColors.felt, Color(0xFF06352F)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            child: engine.phase == RoundPhase.waiting
                ? _WaitingTable(viewModel: viewModel)
                : _ActiveTable(viewModel: viewModel),
          ),
        ),
      ),
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

class _WaitingTable extends StatelessWidget {
  const _WaitingTable({required this.viewModel});

  final TableViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.style, color: AppColors.gold, size: 72),
            const SizedBox(height: 12),
            Text(
              strings.guidedMode,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              strings.educationDisclaimer,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: viewModel.startRound,
              icon: const Icon(Icons.casino_outlined),
              label: Text(strings.startFirstRound),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveTable extends StatelessWidget {
  const _ActiveTable({required this.viewModel});

  final TableViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final engine = viewModel.engine;
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                strings.currentCount(engine.countingEngine.runningCount),
                style: const TextStyle(
                  color: AppColors.mint,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              strings.shoeStatus(engine.dealtCards, engine.totalCards),
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const Spacer(),
            if (engine.reshuffledBeforeRound)
              Text(
                strings.reshuffled,
                style: const TextStyle(color: AppColors.gold, fontSize: 12),
              ),
          ],
        ),
        Expanded(flex: 4, child: _DealerArea(engine: engine)),
        Expanded(
          flex: 5,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final seat in engine.seats)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _SeatArea(
                      engine: engine,
                      seat: seat,
                      isActive: seat.index == engine.activeSeatIndex,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 54,
          child: engine.phase == RoundPhase.complete
              ? Center(
                  child: FilledButton.icon(
                    onPressed: viewModel.startRound,
                    icon: const Icon(Icons.refresh),
                    label: Text(strings.newRound),
                  ),
                )
              : _ActionBar(viewModel: viewModel),
        ),
      ],
    );
  }
}

class _DealerArea extends StatelessWidget {
  const _DealerArea({required this.engine});

  final BlackjackEngine engine;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final evaluation = engine.evaluate(engine.dealerHand);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          engine.dealerHoleRevealed
              ? '${strings.dealer} · ${strings.handTotal(evaluation.total)}'
              : strings.dealer,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        _CompactHand(
          hand: engine.dealerHand,
          hideSecondCard: !engine.dealerHoleRevealed,
          cardWidth: 48,
        ),
      ],
    );
  }
}

class _SeatArea extends StatelessWidget {
  const _SeatArea({
    required this.engine,
    required this.seat,
    required this.isActive,
  });

  final BlackjackEngine engine;
  final TableSeat seat;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final borderColor = isActive ? AppColors.gold : Colors.white12;
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: isActive ? Colors.black26 : Colors.black12,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: isActive ? 2 : 1),
      ),
      child: seat.role == SeatRole.empty
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event_seat_outlined, color: Colors.white24),
                Text(
                  strings.empty,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            )
          : Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      seat.role == SeatRole.human
                          ? Icons.person
                          : Icons.smart_toy_outlined,
                      size: 14,
                      color: seat.role == SeatRole.human
                          ? AppColors.mint
                          : Colors.white54,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${strings.seat(seat.index + 1)} · ${_roleLabel(strings, seat.role)}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: seat.hands.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 5),
                    itemBuilder: (context, handIndex) {
                      final state = seat.hands[handIndex];
                      final evaluation = engine.evaluate(state.hand);
                      return SizedBox(
                        width: 92,
                        child: Column(
                          children: [
                            _CompactHand(hand: state.hand, cardWidth: 35),
                            const SizedBox(height: 3),
                            Text(
                              strings.handTotal(evaluation.total),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (state.outcome != null &&
                                state.resultUnits != null)
                              Text(
                                strings.resultUnits(
                                  _outcomeLabel(strings, state.outcome!),
                                  _formatUnits(state.resultUnits!),
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: state.resultUnits! >= 0
                                      ? AppColors.mint
                                      : AppColors.danger,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _CompactHand extends StatelessWidget {
  const _CompactHand({
    required this.hand,
    required this.cardWidth,
    this.hideSecondCard = false,
  });

  final BlackjackHand hand;
  final double cardWidth;
  final bool hideSecondCard;

  @override
  Widget build(BuildContext context) {
    if (hand.cards.isEmpty) {
      return const SizedBox.shrink();
    }
    final offset = cardWidth * 0.48;
    final width = cardWidth + (hand.cards.length - 1) * offset;
    return SizedBox(
      width: width,
      height: cardWidth * 1.42,
      child: Stack(
        children: [
          for (var index = 0; index < hand.cards.length; index++)
            Positioned(
              left: index * offset,
              child: PlayingCardView(
                card: hand.cards[index],
                width: cardWidth,
                hidden: hideSecondCard && index == 1,
              ),
            ),
        ],
      ),
    );
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
    if (viewModel.engine.phase != RoundPhase.playerTurn) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          strings.turnPrompt,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 14),
        for (final item in actions)
          if (available.contains(item.$1))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilledButton.tonal(
                onPressed: () => viewModel.applyAction(item.$1),
                style: FilledButton.styleFrom(minimumSize: const Size(86, 44)),
                child: Text(item.$2),
              ),
            ),
      ],
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
