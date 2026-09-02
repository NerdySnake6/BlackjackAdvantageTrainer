import 'dart:math';

import 'package:blackjack_advantage_trainer/domain/blackjack_engine/blackjack_engine.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/card.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/game_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('10,000 seeded rounds preserve shoe and round invariants', () {
    var completedRounds = 0;

    for (var seed = 0; seed < 100; seed++) {
      final engine = BlackjackEngine(
        random: Random(seed),
        seatConfiguration: SeatConfiguration([
          SeatRole.human,
          SeatRole.bot,
          seed.isEven ? SeatRole.human : SeatRole.bot,
          SeatRole.empty,
          SeatRole.bot,
        ]),
      );
      final seenCardIds = <String>{};
      var expectedCount = 0;
      var dealtBeforeRound = 0;

      for (var round = 0; round < 100; round++) {
        engine.startRound();
        if (engine.reshuffledBeforeRound) {
          seenCardIds.clear();
          expectedCount = 0;
          dealtBeforeRound = 0;
        }

        var decisions = 0;
        while (engine.phase == RoundPhase.playerTurn) {
          final action = engine.strategyEngine.recommend(
            hand: engine.activeHand!.hand,
            dealerUpCard: engine.dealerUpCard!,
            rules: engine.rules,
            availableActions: engine.availableActions,
          );
          engine.applyAction(action);
          decisions++;
          expect(decisions, lessThan(100));
        }

        expect(engine.phase, RoundPhase.complete);
        expect(engine.dealerHoleRevealed, isTrue);
        expect(engine.dealtCards + engine.remainingCards, engine.totalCards);
        expect(engine.totalCards, 312);
        for (final seat in engine.seats) {
          expect(seat.hands.length, lessThanOrEqualTo(4));
          for (final hand in seat.hands) {
            expect(hand.outcome, isNotNull);
            expect(hand.resultUnits, isNotNull);
          }
        }

        final roundCards = <PlayingCard>[
          ...engine.dealerHand.cards,
          for (final seat in engine.seats)
            for (final hand in seat.hands) ...hand.hand.cards,
        ];
        expect(roundCards, hasLength(engine.dealtCards - dealtBeforeRound));
        for (final card in roundCards) {
          expect(seenCardIds.add(card.id), isTrue);
          expectedCount += card.hiLoTag;
        }
        expect(engine.countingEngine.runningCount, expectedCount);
        dealtBeforeRound = engine.dealtCards;
        completedRounds++;
      }
    }

    expect(completedRounds, 10000);
  });
}
