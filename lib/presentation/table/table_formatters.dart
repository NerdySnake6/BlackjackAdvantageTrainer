/// Pure presentation formatters and icon mappings for the blackjack table.
library;

import 'package:flutter/material.dart';

import '../../domain/blackjack_engine/game_rules.dart';
import '../../domain/blackjack_engine/strategy_engine.dart';
import '../../l10n/app_localizations.dart';

String roleLabel(AppLocalizations strings, SeatRole role) => switch (role) {
  SeatRole.human => strings.human,
  SeatRole.bot => strings.bot,
  SeatRole.empty => strings.empty,
};

IconData roleIcon(SeatRole role) => switch (role) {
  SeatRole.human => Icons.person,
  SeatRole.bot => Icons.smart_toy_outlined,
  SeatRole.empty => Icons.event_seat_outlined,
};

String outcomeLabel(AppLocalizations strings, HandOutcome outcome) =>
    switch (outcome) {
      HandOutcome.blackjack => strings.outcomeBlackjack,
      HandOutcome.win => strings.outcomeWin,
      HandOutcome.push => strings.outcomePush,
      HandOutcome.loss => strings.outcomeLoss,
      HandOutcome.surrender => strings.outcomeSurrender,
    };

String formatUnits(double units) {
  final sign = units > 0 ? '+' : '';
  final value = units == units.roundToDouble()
      ? units.toInt().toString()
      : units.toStringAsFixed(1);
  return '$sign$value';
}

String actionLabel(AppLocalizations strings, PlayerAction action) =>
    switch (action) {
      PlayerAction.hit => strings.hit,
      PlayerAction.stand => strings.stand,
      PlayerAction.doubleDown => strings.doubleAction,
      PlayerAction.split => strings.split,
      PlayerAction.surrender => strings.surrender,
    };

String reasonLabel(AppLocalizations strings, StrategyReason reason) =>
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
