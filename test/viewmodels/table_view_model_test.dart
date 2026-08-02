import 'dart:math';

import 'package:blackjack_advantage_trainer/domain/blackjack_engine/blackjack_engine.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/card.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/game_rules.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/shoe.dart';
import 'package:blackjack_advantage_trainer/domain/learning/table_training.dart';
import 'package:blackjack_advantage_trainer/viewmodels/table_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('table reveals cards in casino dealing order', (tester) async {
    final viewModel = TableViewModel(
      engine: BlackjackEngine(random: Random(14)),
    );
    addTearDown(viewModel.dispose);

    viewModel.startRound();

    expect(viewModel.isDealing, isTrue);
    expect(viewModel.dealProgress, 0);
    expect(viewModel.visibleCardsForSeat(0), 0);
    expect(viewModel.visibleDealerCards, 0);

    await tester.pump(const Duration(milliseconds: 350));
    expect(viewModel.visibleCardsForSeat(0), 1);
    expect(viewModel.visibleCardsForSeat(1), 0);

    await tester.pump(const Duration(milliseconds: 1_700));
    expect(viewModel.visibleDealerCards, 1);

    await tester.pump(const Duration(milliseconds: 2_040));
    expect(viewModel.isDealing, isFalse);
    expect(viewModel.visibleCardsForSeat(0), 2);
    expect(viewModel.visibleDealerCards, 2);
  });

  testWidgets('wrong strategy action is applied and explained', (tester) async {
    final viewModel = TableViewModel(
      engine: _scriptedEngine([
        CardRank.ten,
        CardRank.six,
        CardRank.two,
        CardRank.ten,
        CardRank.ten,
        CardRank.ten,
      ]),
    );
    addTearDown(viewModel.dispose);

    viewModel.startRound();
    await tester.pump(const Duration(seconds: 2));
    expect(viewModel.engine.phase, RoundPhase.playerTurn);

    viewModel.applyAction(PlayerAction.hit);

    expect(viewModel.engine.seats.first.hands.single.hand.cards, hasLength(3));
    expect(viewModel.engine.phase, RoundPhase.complete);
    expect(viewModel.decisionFeedback, isNotNull);
    expect(viewModel.decisionFeedback!.recommendedAction, PlayerAction.stand);
    expect(viewModel.decisionFeedback!.isCorrect, isFalse);
  });

  testWidgets('practice mode checks count after every completed round', (
    tester,
  ) async {
    final viewModel = TableViewModel(
      engine: _scriptedEngine([
        CardRank.ten,
        CardRank.ten,
        CardRank.seven,
        CardRank.seven,
      ]),
      mode: TableTrainingMode.practice,
    );
    addTearDown(viewModel.dispose);

    viewModel.startRound();
    await tester.pump(const Duration(seconds: 2));
    viewModel.applyAction(PlayerAction.stand);

    expect(viewModel.showsRunningCount, isFalse);
    expect(viewModel.awaitingCountCheck, isTrue);
    viewModel.changeSubmittedCount(-1);
    viewModel.changeSubmittedCount(-1);
    viewModel.submitCount();
    expect(viewModel.countWasCorrect, isTrue);
    viewModel.continueAfterCountCheck();
    expect(viewModel.awaitingCountCheck, isFalse);
  });

  testWidgets('five rounds produce a strategy-only session summary', (
    tester,
  ) async {
    final viewModel = TableViewModel(
      engine: _scriptedEngine([
        CardRank.ten,
        CardRank.ten,
        CardRank.seven,
        CardRank.seven,
      ]),
    );
    addTearDown(viewModel.dispose);

    for (var round = 0; round < 5; round++) {
      viewModel.startRound();
      await tester.pump(const Duration(seconds: 2));
      viewModel.applyAction(PlayerAction.stand);
    }

    expect(viewModel.sessionSummary, isNotNull);
    expect(viewModel.sessionSummary!.roundsCompleted, 5);
    expect(viewModel.sessionSummary!.strategyAccuracy, 1);
    expect(viewModel.sessionSummary!.countAccuracy, isNull);
  });
}

BlackjackEngine _scriptedEngine(List<CardRank> ranks) {
  return BlackjackEngine(
    shoe: Shoe.scripted(
      rules: GameRulesProfile.standard,
      cards: [
        for (var index = 0; index < ranks.length; index++)
          PlayingCard(
            deckIndex: 0,
            suit: CardSuit.values[index % CardSuit.values.length],
            rank: ranks[index],
          ),
      ],
    ),
    seatConfiguration: SeatConfiguration([
      SeatRole.human,
      SeatRole.empty,
      SeatRole.empty,
      SeatRole.empty,
      SeatRole.empty,
    ]),
  );
}
