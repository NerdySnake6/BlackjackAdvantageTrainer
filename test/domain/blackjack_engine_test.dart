import 'dart:math';

import 'package:blackjack_advantage_trainer/domain/blackjack/blackjack_engine.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack/game_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BlackjackEngine', () {
    test('deals five active seats and completes a round', () {
      final engine = BlackjackEngine(random: Random(14));

      engine.startRound();

      expect(engine.seats.where((seat) => seat.hands.isNotEmpty), hasLength(5));
      while (engine.phase == RoundPhase.playerTurn) {
        expect(engine.availableActions, contains(PlayerAction.stand));
        engine.applyAction(PlayerAction.stand);
      }

      expect(engine.phase, RoundPhase.complete);
      expect(engine.dealerHoleRevealed, isTrue);
      for (final seat in engine.seats) {
        for (final hand in seat.hands) {
          expect(hand.outcome, isNotNull);
          expect(hand.resultUnits, isNotNull);
        }
      }
    });

    test('rejects a seat configuration without a human player', () {
      expect(
        () => SeatConfiguration(List.filled(5, SeatRole.bot)),
        throwsArgumentError,
      );
    });

    test('supports one person occupying every seat', () {
      final engine = BlackjackEngine(random: Random(8));
      engine.configureSeats(SeatConfiguration(List.filled(5, SeatRole.human)));

      engine.startRound();

      expect(engine.seats.every((seat) => seat.role == SeatRole.human), isTrue);
      expect(engine.phase, anyOf(RoundPhase.playerTurn, RoundPhase.complete));
    });
  });
}
