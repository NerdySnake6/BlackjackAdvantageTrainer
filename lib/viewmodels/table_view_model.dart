/// Presentation wrapper around the pure-Dart blackjack table engine.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/blackjack_engine/blackjack_engine.dart';
import '../domain/blackjack_engine/game_rules.dart';

class TableViewModel extends ChangeNotifier {
  TableViewModel({BlackjackEngine? engine})
    : engine = engine ?? BlackjackEngine();

  final BlackjackEngine engine;
  Timer? _dealTimer;
  List<int> _dealTargets = const [];
  var _dealStep = 0;
  var _isDealing = false;

  bool get isDealing => _isDealing;

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
    _dealTimer?.cancel();
    engine.startRound();
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
        notifyListeners();
      }
    });
  }

  void applyAction(PlayerAction action) {
    if (_isDealing) {
      return;
    }
    engine.applyAction(action);
    notifyListeners();
  }

  bool cycleSeat(int seatIndex) {
    final roles = engine.seats.map((seat) => seat.role).toList();
    final current = roles[seatIndex];
    final nextIndex = (current.index + 1) % SeatRole.values.length;
    roles[seatIndex] = SeatRole.values[nextIndex];
    if (!roles.contains(SeatRole.human)) {
      return false;
    }
    engine.configureSeats(SeatConfiguration(roles));
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

  int _visibleTargetCount(int target) {
    return _dealTargets
        .take(_dealStep)
        .where((dealTarget) => dealTarget == target)
        .length;
  }
}
