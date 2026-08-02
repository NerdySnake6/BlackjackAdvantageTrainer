/// Scoring models for guided blackjack table training.
library;

import '../blackjack_engine/game_rules.dart';
import '../blackjack_engine/strategy_engine.dart';

enum TableTrainingMode { guided, practice }

class TableDecisionAttempt {
  const TableDecisionAttempt({
    required this.selectedAction,
    required this.recommendedAction,
    required this.reason,
  });

  final PlayerAction selectedAction;
  final PlayerAction recommendedAction;
  final StrategyReason reason;

  bool get isCorrect => selectedAction == recommendedAction;
}

class TableSessionSummary {
  const TableSessionSummary({
    required this.mode,
    required this.roundsCompleted,
    required this.correctStrategyDecisions,
    required this.totalStrategyDecisions,
    required this.correctCountChecks,
    required this.totalCountChecks,
  });

  final TableTrainingMode mode;
  final int roundsCompleted;
  final int correctStrategyDecisions;
  final int totalStrategyDecisions;
  final int correctCountChecks;
  final int totalCountChecks;

  double get strategyAccuracy => totalStrategyDecisions == 0
      ? 1
      : correctStrategyDecisions / totalStrategyDecisions;

  double? get countAccuracy =>
      totalCountChecks == 0 ? null : correctCountChecks / totalCountChecks;
}
