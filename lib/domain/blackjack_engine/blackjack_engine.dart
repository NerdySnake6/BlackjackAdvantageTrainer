/// A self-contained blackjack round engine for the five-seat training table.
library;

import 'dart:math';

import 'card.dart';
import 'counting_engine.dart';
import 'game_rules.dart';
import 'hand.dart';
import 'shoe.dart';
import 'strategy_engine.dart';

class PlayerHandState {
  PlayerHandState({BlackjackHand? hand, this.fromSplit = false})
    : hand = hand ?? BlackjackHand();

  final BlackjackHand hand;
  bool fromSplit;
  bool isStanding = false;
  bool isSurrendered = false;
  double wagerUnits = 1;
  HandOutcome? outcome;
  double? resultUnits;

  bool get isComplete => isStanding || isSurrendered;
}

class TableSeat {
  TableSeat({required this.index, required this.role});

  final int index;
  SeatRole role;
  final List<PlayerHandState> hands = [];
}

class BlackjackEngine {
  BlackjackEngine({
    this.rules = GameRulesProfile.standard,
    SeatConfiguration? seatConfiguration,
    Random? random,
    this.strategyEngine = const StrategyEngine(),
    this.handEvaluator = const HandEvaluator(),
  }) : _shoe = Shoe(rules: rules, random: random),
       seats = [
         for (var index = 0; index < 5; index++)
           TableSeat(
             index: index,
             role: (seatConfiguration ?? SeatConfiguration.standard())
                 .roles[index],
           ),
       ];

  final GameRulesProfile rules;
  final StrategyEngine strategyEngine;
  final HandEvaluator handEvaluator;
  final Shoe _shoe;
  final CountingEngine countingEngine = CountingEngine();
  final List<TableSeat> seats;
  BlackjackHand dealerHand = BlackjackHand();

  RoundPhase phase = RoundPhase.waiting;
  int activeSeatIndex = -1;
  int activeHandIndex = -1;
  bool dealerHoleRevealed = false;
  bool reshuffledBeforeRound = false;

  int get dealtCards => _shoe.dealtCount;
  int get totalCards => _shoe.totalCards;
  int get remainingCards => _shoe.remainingCount;

  PlayingCard? get dealerUpCard =>
      dealerHand.cards.isEmpty ? null : dealerHand.cards.first;

  PlayerHandState? get activeHand {
    if (activeSeatIndex < 0 || activeHandIndex < 0) {
      return null;
    }
    return seats[activeSeatIndex].hands[activeHandIndex];
  }

  Set<PlayerAction> get availableActions {
    final state = activeHand;
    if (phase != RoundPhase.playerTurn || state == null || state.isComplete) {
      return {};
    }

    final evaluation = handEvaluator.evaluate(state.hand.cards);
    if (evaluation.isBust || evaluation.total == 21) {
      return {};
    }

    final actions = <PlayerAction>{PlayerAction.hit, PlayerAction.stand};
    if (state.hand.cards.length == 2) {
      if (!state.fromSplit || rules.doubleAfterSplit) {
        actions.add(PlayerAction.doubleDown);
      }
      if (!state.fromSplit && rules.lateSurrender) {
        actions.add(PlayerAction.surrender);
      }
      final seat = seats[activeSeatIndex];
      final valuesMatch =
          state.hand.cards[0].rank.blackjackValue ==
          state.hand.cards[1].rank.blackjackValue;
      if (valuesMatch && seat.hands.length < rules.maxSplitHands) {
        actions.add(PlayerAction.split);
      }
    }
    return actions;
  }

  void configureSeats(SeatConfiguration configuration) {
    if (phase == RoundPhase.playerTurn || phase == RoundPhase.dealerTurn) {
      throw StateError('Seats cannot be changed during an active round.');
    }
    for (var index = 0; index < seats.length; index++) {
      seats[index].role = configuration.roles[index];
    }
  }

  void startRound() {
    reshuffledBeforeRound = false;
    if (_shoe.penetrationReached || _shoe.remainingCount < 32) {
      _shoe.reset();
      countingEngine.reset();
      reshuffledBeforeRound = true;
    }

    phase = RoundPhase.waiting;
    activeSeatIndex = -1;
    activeHandIndex = -1;
    dealerHoleRevealed = false;
    dealerHand = BlackjackHand();

    for (final seat in seats) {
      seat.hands.clear();
      if (seat.role != SeatRole.empty) {
        seat.hands.add(PlayerHandState());
      }
    }

    for (var pass = 0; pass < 2; pass++) {
      for (final seat in seats) {
        if (seat.role == SeatRole.empty) {
          continue;
        }
        _dealVisible(seat.hands.single.hand);
      }
      final dealerCard = _shoe.draw();
      dealerHand.add(dealerCard);
      if (pass == 0) {
        countingEngine.reveal(dealerCard);
      }
    }

    for (final seat in seats) {
      for (final handState in seat.hands) {
        final evaluation = handEvaluator.evaluate(handState.hand.cards);
        if (evaluation.isBlackjack) {
          handState.isStanding = true;
        }
      }
    }

    final dealerEvaluation = handEvaluator.evaluate(dealerHand.cards);
    final upValue = dealerUpCard!.rank.blackjackValue;
    final shouldPeek = rules.dealerPeek && (upValue == 1 || upValue == 10);
    if (shouldPeek && dealerEvaluation.isBlackjack) {
      _revealDealerHole();
      _settleRound();
      return;
    }

    _advanceToNextHand();
  }

  void applyAction(PlayerAction action) {
    if (!availableActions.contains(action)) {
      throw StateError('Action ${action.name} is not available.');
    }
    _performAction(action);
    final state = activeHand;
    if (state == null || state.isComplete) {
      _advanceToNextHand();
    }
  }

  HandEvaluation evaluate(BlackjackHand hand) =>
      handEvaluator.evaluate(hand.cards);

  void _advanceToNextHand() {
    while (true) {
      final next = _findNextPlayableHand();
      if (next == null) {
        _playDealerAndSettle();
        return;
      }

      activeSeatIndex = next.$1;
      activeHandIndex = next.$2;
      phase = RoundPhase.playerTurn;

      if (seats[activeSeatIndex].role == SeatRole.human) {
        return;
      }

      _playActiveBotHand();
    }
  }

  (int, int)? _findNextPlayableHand() {
    var seatIndex = activeSeatIndex < 0 ? 0 : activeSeatIndex;
    var handIndex = activeSeatIndex < 0 ? 0 : activeHandIndex + 1;

    while (seatIndex < seats.length) {
      final seat = seats[seatIndex];
      while (handIndex < seat.hands.length) {
        final state = seat.hands[handIndex];
        final evaluation = handEvaluator.evaluate(state.hand.cards);
        if (!state.isComplete && !evaluation.isBust && evaluation.total < 21) {
          return (seatIndex, handIndex);
        }
        state.isStanding = true;
        handIndex++;
      }
      seatIndex++;
      handIndex = 0;
    }
    return null;
  }

  void _playActiveBotHand() {
    while (activeHand != null && !activeHand!.isComplete) {
      final evaluation = handEvaluator.evaluate(activeHand!.hand.cards);
      if (evaluation.isBust || evaluation.total >= 21) {
        activeHand!.isStanding = true;
        return;
      }
      final action = strategyEngine.recommend(
        hand: activeHand!.hand,
        dealerUpCard: dealerUpCard!,
        rules: rules,
        availableActions: availableActions,
      );
      _performAction(action);
    }
  }

  void _performAction(PlayerAction action) {
    final state = activeHand!;
    switch (action) {
      case PlayerAction.hit:
        _dealVisible(state.hand);
        final evaluation = handEvaluator.evaluate(state.hand.cards);
        if (evaluation.isBust || evaluation.total == 21) {
          state.isStanding = true;
        }
      case PlayerAction.stand:
        state.isStanding = true;
      case PlayerAction.doubleDown:
        state.wagerUnits *= 2;
        _dealVisible(state.hand);
        state.isStanding = true;
      case PlayerAction.surrender:
        state.isSurrendered = true;
        state.isStanding = true;
      case PlayerAction.split:
        _splitActiveHand();
    }
  }

  void _splitActiveHand() {
    final seat = seats[activeSeatIndex];
    final original = activeHand!;
    final secondCard = original.hand.cards.removeLast();
    final splitHand = PlayerHandState(
      hand: BlackjackHand([secondCard]),
      fromSplit: true,
    );
    original.fromSplit = true;
    seat.hands.insert(activeHandIndex + 1, splitHand);

    _dealVisible(original.hand);
    _dealVisible(splitHand.hand);

    final splitAces = original.hand.cards.first.rank == CardRank.ace;
    if (splitAces) {
      original.isStanding = true;
      splitHand.isStanding = true;
    } else if (handEvaluator.evaluate(original.hand.cards).total == 21) {
      original.isStanding = true;
    }
  }

  void _dealVisible(BlackjackHand hand) {
    final card = _shoe.draw();
    hand.add(card);
    countingEngine.reveal(card);
  }

  void _revealDealerHole() {
    if (dealerHoleRevealed || dealerHand.cards.length < 2) {
      return;
    }
    dealerHoleRevealed = true;
    countingEngine.reveal(dealerHand.cards[1]);
  }

  void _playDealerAndSettle() {
    phase = RoundPhase.dealerTurn;
    activeSeatIndex = -1;
    activeHandIndex = -1;
    _revealDealerHole();

    while (true) {
      final evaluation = handEvaluator.evaluate(dealerHand.cards);
      final shouldHit =
          evaluation.total < 17 ||
          (evaluation.total == 17 &&
              evaluation.isSoft &&
              rules.dealerHitsSoft17);
      if (!shouldHit) {
        break;
      }
      _dealVisible(dealerHand);
    }
    _settleRound();
  }

  void _settleRound() {
    phase = RoundPhase.complete;
    activeSeatIndex = -1;
    activeHandIndex = -1;
    final dealerEvaluation = handEvaluator.evaluate(dealerHand.cards);

    for (final seat in seats) {
      for (final state in seat.hands) {
        final playerEvaluation = handEvaluator.evaluate(state.hand.cards);
        final isNatural = playerEvaluation.isBlackjack && !state.fromSplit;
        if (state.isSurrendered) {
          state
            ..outcome = HandOutcome.surrender
            ..resultUnits = -0.5 * state.wagerUnits;
        } else if (playerEvaluation.isBust) {
          state
            ..outcome = HandOutcome.loss
            ..resultUnits = -state.wagerUnits;
        } else if (isNatural && !dealerEvaluation.isBlackjack) {
          state
            ..outcome = HandOutcome.blackjack
            ..resultUnits =
                state.wagerUnits * rules.blackjackPayout.profitUnits;
        } else if (dealerEvaluation.isBlackjack && !isNatural) {
          state
            ..outcome = HandOutcome.loss
            ..resultUnits = -state.wagerUnits;
        } else if (dealerEvaluation.isBust ||
            playerEvaluation.total > dealerEvaluation.total) {
          state
            ..outcome = HandOutcome.win
            ..resultUnits = state.wagerUnits;
        } else if (playerEvaluation.total == dealerEvaluation.total) {
          state
            ..outcome = HandOutcome.push
            ..resultUnits = 0;
        } else {
          state
            ..outcome = HandOutcome.loss
            ..resultUnits = -state.wagerUnits;
        }
      }
    }
  }
}
