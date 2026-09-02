/// Presentation wrapper around the pure-Dart blackjack table engine.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/blackjack_engine/blackjack_engine.dart';
import '../domain/blackjack_engine/game_rules.dart';
import '../domain/learning/table_training.dart';

class TableViewModel extends ChangeNotifier {
  TableViewModel({
    BlackjackEngine? engine,
    this.mode = TableTrainingMode.guided,
    this.onEvent,
  }) : engine = engine ?? BlackjackEngine();

  final BlackjackEngine engine;
  final void Function(String, Map<String, Object?>)? onEvent;
  Timer? _dealTimer;
  List<int> _dealTargets = const [];
  var _dealStep = 0;
  var _isDealing = false;
  TableTrainingMode mode;
  TableDecisionAttempt? _decisionFeedback;
  TableSessionSummary? _sessionSummary;
  var _roundsCompleted = 0;
  var _correctStrategyDecisions = 0;
  var _totalStrategyDecisions = 0;
  var _correctCountChecks = 0;
  var _totalCountChecks = 0;
  var _roundRecorded = false;
  var _awaitingCountCheck = false;
  var _submittedCount = 0;
  int? _revealedCount;
  bool? _countWasCorrect;
  List<SeatRole>? _pendingSeatRoles;

  bool get isDealing => _isDealing;
  TableDecisionAttempt? get decisionFeedback => _decisionFeedback;
  TableSessionSummary? get sessionSummary => _sessionSummary;
  int get roundsCompleted => _roundsCompleted;
  int get roundsPerSession => 5;
  bool get awaitingCountCheck => _awaitingCountCheck;
  int get submittedCount => _submittedCount;
  int? get revealedCount => _revealedCount;
  bool? get countWasCorrect => _countWasCorrect;
  bool get showsRunningCount => mode == TableTrainingMode.guided;
  bool get canChangeMode =>
      !_isDealing &&
      !_awaitingCountCheck &&
      _decisionFeedback == null &&
      engine.phase != RoundPhase.playerTurn &&
      engine.phase != RoundPhase.dealerTurn;

  List<SeatRole> get configuredSeatRoles => List.unmodifiable(
    _pendingSeatRoles ?? engine.seats.map((seat) => seat.role),
  );
  bool get hasPendingSeatConfiguration => _pendingSeatRoles != null;

  double get dealProgress {
    if (_dealTargets.isEmpty) {
      return 1;
    }
    return _dealStep / _dealTargets.length;
  }

  int visibleCardsForSeat(int seatIndex) {
    if (!_isDealing) {
      return engine.seats[seatIndex].hands.isEmpty
          ? 0
          : engine.seats[seatIndex].hands.first.hand.cards.length;
    }
    return _visibleTargetCount(seatIndex);
  }

  int get visibleDealerCards {
    if (!_isDealing) {
      return engine.dealerHand.cards.length;
    }
    return _visibleTargetCount(-1);
  }

  void startRound() {
    if (_awaitingCountCheck ||
        _decisionFeedback != null ||
        _sessionSummary != null) {
      return;
    }
    _dealTimer?.cancel();
    _applyPendingSeatConfiguration();
    engine.startRound();
    onEvent?.call('table_round_started', {
      'session_type': mode.name,
      'round_number': _roundsCompleted + 1,
    });
    _roundRecorded = false;
    _dealTargets = _buildDealTargets();
    _dealStep = 0;
    _isDealing = _dealTargets.isNotEmpty;
    notifyListeners();
    if (!_isDealing) {
      return;
    }
    _dealTimer = Timer.periodic(const Duration(milliseconds: 340), (_) {
      if (_dealStep < _dealTargets.length) {
        _dealStep++;
        notifyListeners();
      }
      if (_dealStep >= _dealTargets.length) {
        _isDealing = false;
        _dealTimer?.cancel();
        _dealTimer = null;
        _recordCompletedRoundIfNeeded();
        notifyListeners();
      }
    });
  }

  void applyAction(PlayerAction action) {
    if (_isDealing || _decisionFeedback != null || _awaitingCountCheck) {
      return;
    }
    final hand = engine.activeHand;
    final upCard = engine.dealerUpCard;
    if (hand == null || upCard == null) {
      return;
    }
    final recommendation = engine.strategyEngine.recommendWithReason(
      hand: hand.hand,
      dealerUpCard: upCard,
      rules: engine.rules,
      availableActions: engine.availableActions,
    );
    final attempt = TableDecisionAttempt(
      selectedAction: action,
      recommendedAction: recommendation.action,
      reason: recommendation.reason,
    );
    _totalStrategyDecisions++;
    if (attempt.isCorrect) {
      _correctStrategyDecisions++;
    } else {
      _decisionFeedback = attempt;
    }
    onEvent?.call('strategy_decision', {
      'session_type': mode.name,
      'is_correct': attempt.isCorrect,
    });
    engine.applyAction(action);
    _recordCompletedRoundIfNeeded();
    notifyListeners();
  }

  void dismissDecisionFeedback() {
    _decisionFeedback = null;
    notifyListeners();
  }

  void changeSubmittedCount(int delta) {
    if (!_awaitingCountCheck || _countWasCorrect != null) {
      return;
    }
    _submittedCount += delta;
    notifyListeners();
  }

  void submitCount() {
    if (!_awaitingCountCheck || _countWasCorrect != null) {
      return;
    }
    _revealedCount = engine.countingEngine.runningCount;
    _countWasCorrect = _submittedCount == _revealedCount;
    _totalCountChecks++;
    if (_countWasCorrect!) {
      _correctCountChecks++;
    }
    onEvent?.call('count_check', {
      'session_type': 'table_${mode.name}',
      'is_correct': _countWasCorrect!,
    });
    notifyListeners();
  }

  void continueAfterCountCheck() {
    if (_countWasCorrect == null) {
      return;
    }
    _awaitingCountCheck = false;
    _submittedCount = 0;
    _revealedCount = null;
    _countWasCorrect = null;
    if (_roundsCompleted >= roundsPerSession) {
      _finishSession();
    }
    notifyListeners();
  }

  void setMode(TableTrainingMode newMode) {
    if (!canChangeMode || newMode == mode) {
      return;
    }
    mode = newMode;
    notifyListeners();
  }

  void startNewSession() {
    if (_sessionSummary == null) {
      return;
    }
    _roundsCompleted = 0;
    _correctStrategyDecisions = 0;
    _totalStrategyDecisions = 0;
    _correctCountChecks = 0;
    _totalCountChecks = 0;
    _sessionSummary = null;
    notifyListeners();
  }

  bool cycleSeat(int seatIndex) {
    final current = configuredSeatRoles[seatIndex];
    final nextIndex = (current.index + 1) % SeatRole.values.length;
    return setSeatRole(seatIndex, SeatRole.values[nextIndex]);
  }

  bool canSetSeatRole(int seatIndex, SeatRole role) {
    final roles = configuredSeatRoles;
    final current = roles[seatIndex];
    if (current != SeatRole.human || role == SeatRole.human) {
      return true;
    }
    return roles.indexed.any(
      (entry) => entry.$1 != seatIndex && entry.$2 == SeatRole.human,
    );
  }

  bool setSeatRole(int seatIndex, SeatRole role) {
    if (!canSetSeatRole(seatIndex, role)) {
      return false;
    }
    final roles = configuredSeatRoles.toList();
    roles[seatIndex] = role;
    if (_roundIsActive) {
      _pendingSeatRoles = roles;
    } else {
      engine.configureSeats(SeatConfiguration(roles));
      _pendingSeatRoles = null;
    }
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    _dealTimer?.cancel();
    super.dispose();
  }

  List<int> _buildDealTargets() {
    final occupiedSeats = engine.seats
        .where((seat) => seat.role != SeatRole.empty)
        .map((seat) => seat.index)
        .toList();
    return [...occupiedSeats, -1, ...occupiedSeats, -1];
  }

  bool get _roundIsActive =>
      _isDealing ||
      engine.phase == RoundPhase.playerTurn ||
      engine.phase == RoundPhase.dealerTurn;

  void _applyPendingSeatConfiguration() {
    final roles = _pendingSeatRoles;
    if (roles == null) {
      return;
    }
    engine.configureSeats(SeatConfiguration(roles));
    _pendingSeatRoles = null;
  }

  int _visibleTargetCount(int target) {
    return _dealTargets
        .take(_dealStep)
        .where((dealTarget) => dealTarget == target)
        .length;
  }

  void _recordCompletedRoundIfNeeded() {
    if (_isDealing || _roundRecorded || engine.phase != RoundPhase.complete) {
      return;
    }
    _roundRecorded = true;
    _roundsCompleted++;
    if (mode == TableTrainingMode.practice) {
      _awaitingCountCheck = true;
      return;
    }
    if (_roundsCompleted >= roundsPerSession) {
      _finishSession();
    }
  }

  void _finishSession() {
    _sessionSummary = TableSessionSummary(
      mode: mode,
      roundsCompleted: _roundsCompleted,
      correctStrategyDecisions: _correctStrategyDecisions,
      totalStrategyDecisions: _totalStrategyDecisions,
      correctCountChecks: _correctCountChecks,
      totalCountChecks: _totalCountChecks,
    );
    onEvent?.call('table_session_completed', {
      'session_type': mode.name,
      'rounds_completed': _roundsCompleted,
      'strategy_correct': _correctStrategyDecisions,
      'strategy_total': _totalStrategyDecisions,
      'count_correct': _correctCountChecks,
      'count_total': _totalCountChecks,
    });
  }
}
