/// Landscape guided blackjack practice table.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../domain/blackjack_engine/blackjack_engine.dart';
import '../../domain/blackjack_engine/game_rules.dart';
import '../../domain/blackjack_engine/hand.dart';
import '../../domain/blackjack_engine/strategy_engine.dart';
import '../../domain/learning/models.dart';
import '../../domain/learning/table_training.dart';
import '../../l10n/app_localizations.dart';
import '../../viewmodels/app_state.dart';
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
    final appState = context.read<AppState>();
    final experienceLevel = appState.progress.experienceLevel;
    return ChangeNotifierProvider(
      create: (context) => TableViewModel(
        mode: experienceLevel == ExperienceLevel.experienced
            ? TableTrainingMode.practice
            : TableTrainingMode.guided,
        onEvent: (eventName, parameters) {
          unawaited(appState.trackTrainingEvent(eventName, parameters));
        },
      ),
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
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 1000;
    final isPortraitTransition = width < 480;
    return Row(
      children: [
        IconButton(
          onPressed: () => context.go('/learn'),
          tooltip: strings.backToPath,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PopupMenuButton<TableTrainingMode>(
                enabled: viewModel.canChangeMode,
                initialValue: viewModel.mode,
                onSelected: viewModel.setMode,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: TableTrainingMode.guided,
                    child: Text(strings.guidedModeName),
                  ),
                  PopupMenuItem(
                    value: TableTrainingMode.practice,
                    child: Text(strings.practiceModeName),
                  ),
                ],
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      viewModel.mode == TableTrainingMode.guided
                          ? strings.guidedMode
                          : strings.practiceMode,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.arrow_drop_down,
                      size: 16,
                      color: AppColors.gold,
                    ),
                  ],
                ),
              ),
              Text(
                engine.rules.id == GameRulesProfile.standard.id
                    ? strings.standardRulesName
                    : engine.rules.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ),
        if (!isPortraitTransition && viewModel.showsRunningCount) ...[
          _HeaderPill(
            icon: Icons.speed_rounded,
            label: strings.currentCount(engine.countingEngine.runningCount),
            color: AppColors.mint,
          ),
          const SizedBox(width: 6),
        ],
        if (!isCompact && !isPortraitTransition)
          _HeaderPill(
            icon: Icons.flag_outlined,
            label: strings.tableRoundProgress(
              viewModel.roundsCompleted,
              viewModel.roundsPerSession,
            ),
            color: AppColors.gold,
          ),
        if (!isCompact) ...[
          const SizedBox(width: 6),
          _HeaderPill(
            icon: Icons.layers_outlined,
            label: strings.shoeStatus(engine.dealtCards, engine.totalCards),
            color: Colors.white70,
          ),
        ],
        const SizedBox(width: 4),
        IconButton(
          onPressed: () => _showSeatConfiguration(context),
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
      isScrollControlled: true,
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

class _DecisionFeedbackBar extends StatelessWidget {
  const _DecisionFeedbackBar({required this.viewModel, required this.feedback});

  final TableViewModel viewModel;
  final TableDecisionAttempt feedback;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF4B2529),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger),
      ),
      child: Row(
        children: [
          const Icon(Icons.school_outlined, color: AppColors.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.recommendedAction(
                    _actionLabel(strings, feedback.recommendedAction),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  _reasonLabel(strings, feedback.reason),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: viewModel.dismissDecisionFeedback,
            child: Text(strings.continueAction),
          ),
        ],
      ),
    );
  }
}

class _CountCheckBar extends StatelessWidget {
  const _CountCheckBar({required this.viewModel});

  final TableViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final answered = viewModel.countWasCorrect != null;
    return SizedBox(
      height: 58,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            answered
                ? viewModel.countWasCorrect!
                      ? strings.countCorrect
                      : strings.countIncorrect(viewModel.revealedCount!)
                : strings.tableCountPrompt,
            style: TextStyle(
              color: answered && !viewModel.countWasCorrect!
                  ? AppColors.danger
                  : Colors.white70,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 12),
          if (!answered) ...[
            IconButton.filledTonal(
              onPressed: () => viewModel.changeSubmittedCount(-1),
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 54,
              child: Text(
                '${viewModel.submittedCount >= 0 ? '+' : ''}${viewModel.submittedCount}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton.filledTonal(
              onPressed: () => viewModel.changeSubmittedCount(1),
              icon: const Icon(Icons.add),
            ),
          ],
          const SizedBox(width: 12),
          FilledButton(
            onPressed: answered
                ? viewModel.continueAfterCountCheck
                : viewModel.submitCount,
            child: Text(
              answered ? strings.continueAction : strings.submitCount,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionSummaryBar extends StatelessWidget {
  const _SessionSummaryBar({required this.viewModel, required this.summary});

  final TableViewModel viewModel;
  final TableSessionSummary summary;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return SizedBox(
      height: 58,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.verified_outlined, color: AppColors.mint),
          const SizedBox(width: 8),
          Text(
            strings.tableSessionComplete,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 16),
          Text(
            strings.strategyAccuracy((summary.strategyAccuracy * 100).round()),
          ),
          if (summary.countAccuracy case final accuracy?) ...[
            const SizedBox(width: 12),
            Text(strings.countAccuracy((accuracy * 100).round())),
          ],
          const SizedBox(width: 16),
          FilledButton(
            onPressed: viewModel.startNewSession,
            child: Text(strings.startAnotherSession),
          ),
        ],
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
    final compactHeight = MediaQuery.sizeOf(context).height <= 340;
    final usesLargeText = MediaQuery.textScalerOf(context).scale(1) > 1.1;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      constraints: BoxConstraints(minHeight: compactHeight ? 104 : 112),
      padding: EdgeInsets.symmetric(
        horizontal: 6,
        vertical: compactHeight ? 4 : 7,
      ),
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
                  SizedBox(height: compactHeight ? 52 : 59)
                else
                  SizedBox(
                    height: compactHeight ? 52 : 59,
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
                            _PlayerHand(
                              viewModel: viewModel,
                              seatIndex: seat.index,
                              handState: handState,
                              isActive: isActive,
                            ),
                        ],
                      ),
                    ),
                  ),
                if (!compactHeight && !usesLargeText) ...[
                  const SizedBox(height: 3),
                  _PracticeUnitChip(
                    label: strings.practiceUnits,
                    color: accent,
                  ),
                ],
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
    if (viewModel.sessionSummary case final summary?) {
      return _SessionSummaryBar(viewModel: viewModel, summary: summary);
    }
    if (viewModel.decisionFeedback case final feedback?) {
      return _DecisionFeedbackBar(viewModel: viewModel, feedback: feedback);
    }
    if (viewModel.awaitingCountCheck) {
      return _CountCheckBar(viewModel: viewModel);
    }
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
    final isCompact = MediaQuery.sizeOf(context).width < 1000;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!isCompact) ...[
          Text(
            strings.turnPrompt,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
          const SizedBox(width: 10),
        ],
        for (final item in actions)
          if (available.contains(item.$1))
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: FilledButton.tonal(
                  onPressed: () => viewModel.applyAction(item.$1),
                  style: FilledButton.styleFrom(
                    minimumSize: Size(isCompact ? 0 : 78, 42),
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 6 : 10,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.$2,
                      textScaler: isCompact ? TextScaler.noScaling : null,
                      style: TextStyle(fontSize: isCompact ? 11 : null),
                    ),
                  ),
                ),
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
      child: SingleChildScrollView(
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
            if (viewModel.hasPendingSeatConfiguration) ...[
              const SizedBox(height: 4),
              Text(
                strings.seatChangesPending,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                for (final (seatIndex, role)
                    in viewModel.configuredSeatRoles.indexed)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: PopupMenuButton<SeatRole>(
                        initialValue: role,
                        onSelected: (role) =>
                            viewModel.setSeatRole(seatIndex, role),
                        itemBuilder: (context) => [
                          for (final role in SeatRole.values)
                            PopupMenuItem(
                              value: role,
                              enabled: viewModel.canSetSeatRole(
                                seatIndex,
                                role,
                              ),
                              child: Row(
                                children: [
                                  Icon(_roleIcon(role), size: 20),
                                  const SizedBox(width: 10),
                                  Text(_roleLabel(strings, role)),
                                ],
                              ),
                            ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Icon(_roleIcon(role)),
                              const SizedBox(height: 5),
                              Text(
                                strings.seat(seatIndex + 1),
                                style: const TextStyle(fontSize: 11),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      _roleLabel(strings, role),
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down, size: 16),
                                ],
                              ),
                            ],
                          ),
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

String _actionLabel(AppLocalizations strings, PlayerAction action) =>
    switch (action) {
      PlayerAction.hit => strings.hit,
      PlayerAction.stand => strings.stand,
      PlayerAction.doubleDown => strings.doubleAction,
      PlayerAction.split => strings.split,
      PlayerAction.surrender => strings.surrender,
    };

String _reasonLabel(AppLocalizations strings, StrategyReason reason) =>
    switch (reason) {
      StrategyReason.splitPair => strings.strategyReasonSplitPair,
      StrategyReason.standPair => strings.strategyReasonStandPair,
      StrategyReason.doublePair => strings.strategyReasonDoublePair,
      StrategyReason.hitPair => strings.strategyReasonHitPair,
      StrategyReason.surrenderHardTotal => strings.strategyReasonSurrenderHard,
      StrategyReason.doubleSoftTotal => strings.strategyReasonDoubleSoft,
      StrategyReason.standSoftTotal => strings.strategyReasonStandSoft,
      StrategyReason.hitSoftTotal => strings.strategyReasonHitSoft,
      StrategyReason.doubleHardTotal => strings.strategyReasonDoubleHard,
      StrategyReason.standHardTotal => strings.strategyReasonStandHard,
      StrategyReason.hitHardTotal => strings.strategyReasonHitHard,
      StrategyReason.unavailableActionFallback =>
        strings.strategyReasonFallback,
    };
