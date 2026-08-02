/// Presentation wrapper around the pure-Dart blackjack table engine.
library;

import 'package:flutter/foundation.dart';

import '../domain/blackjack/blackjack_engine.dart';
import '../domain/blackjack/game_rules.dart';

class TableViewModel extends ChangeNotifier {
  TableViewModel({BlackjackEngine? engine})
    : engine = engine ?? BlackjackEngine();

  final BlackjackEngine engine;

  void startRound() {
    engine.startRound();
    notifyListeners();
  }

  void applyAction(PlayerAction action) {
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
}
