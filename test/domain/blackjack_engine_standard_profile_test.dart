import 'package:blackjack_advantage_trainer/domain/blackjack_engine/blackjack_engine.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/card.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/game_rules.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/shoe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('standard profile scripted scenarios', () {
    test('dealer peek reveals blackjack before player decisions', () {
      final engine = _engine([
        CardRank.ten,
        CardRank.ace,
        CardRank.nine,
        CardRank.king,
      ]);

      engine.startRound();

      expect(engine.phase, RoundPhase.complete);
      expect(engine.dealerHoleRevealed, isTrue);
      expect(engine.seats.first.hands.single.outcome, HandOutcome.loss);
      expect(engine.seats.first.hands.single.resultUnits, -1);
    });

    test('dealer stands on soft 17 under S17', () {
      final engine = _engine([
        CardRank.ten,
        CardRank.ace,
        CardRank.seven,
        CardRank.six,
      ]);

      engine.startRound();
      engine.applyAction(PlayerAction.stand);

      expect(engine.dealerHand.cards, hasLength(2));
      expect(engine.evaluate(engine.dealerHand).isSoft, isTrue);
      expect(engine.seats.first.hands.single.outcome, HandOutcome.push);
    });

    test('double uses two units and takes exactly one card', () {
      final engine = _engine([
        CardRank.five,
        CardRank.six,
        CardRank.six,
        CardRank.ten,
        CardRank.ten,
        CardRank.five,
      ]);

      engine.startRound();
      engine.applyAction(PlayerAction.doubleDown);

      final hand = engine.seats.first.hands.single;
      expect(hand.hand.cards, hasLength(3));
      expect(hand.wagerUnits, 2);
      expect(hand.outcome, HandOutcome.push);
      expect(hand.resultUnits, 0);
    });

    test('late surrender settles at minus half a unit', () {
      final engine = _engine([
        CardRank.ten,
        CardRank.ten,
        CardRank.six,
        CardRank.six,
        CardRank.five,
      ]);

      engine.startRound();
      expect(engine.availableActions, contains(PlayerAction.surrender));
      engine.applyAction(PlayerAction.surrender);

      final hand = engine.seats.first.hands.single;
      expect(hand.outcome, HandOutcome.surrender);
      expect(hand.resultUnits, -0.5);
    });

    test('resplitting is capped at four hands', () {
      final engine = _engine([
        CardRank.eight,
        CardRank.six,
        CardRank.eight,
        CardRank.ten,
        CardRank.eight,
        CardRank.two,
        CardRank.eight,
        CardRank.three,
        CardRank.four,
        CardRank.five,
        CardRank.ten,
      ]);

      engine.startRound();
      engine.applyAction(PlayerAction.split);
      engine.applyAction(PlayerAction.split);
      engine.applyAction(PlayerAction.split);

      expect(engine.seats.first.hands, hasLength(4));
      expect(engine.availableActions, isNot(contains(PlayerAction.split)));
      while (engine.phase == RoundPhase.playerTurn) {
        engine.applyAction(PlayerAction.stand);
      }
      expect(engine.phase, RoundPhase.complete);
    });

    test('double after split remains available under DAS', () {
      final engine = _engine([
        CardRank.four,
        CardRank.six,
        CardRank.four,
        CardRank.ten,
        CardRank.two,
        CardRank.three,
        CardRank.ten,
      ]);

      engine.startRound();
      engine.applyAction(PlayerAction.split);
      expect(engine.activeHand!.fromSplit, isTrue);
      expect(engine.availableActions, contains(PlayerAction.doubleDown));

      engine.applyAction(PlayerAction.doubleDown);

      final doubledHand = engine.seats.first.hands.first;
      expect(doubledHand.wagerUnits, 2);
      expect(doubledHand.hand.cards, hasLength(3));
    });

    test('split aces receive one card each and are not naturals', () {
      final engine = _engine([
        CardRank.ace,
        CardRank.six,
        CardRank.ace,
        CardRank.ten,
        CardRank.ten,
        CardRank.king,
        CardRank.ten,
      ]);

      engine.startRound();
      engine.applyAction(PlayerAction.split);

      final hands = engine.seats.first.hands;
      expect(hands, hasLength(2));
      expect(hands.every((hand) => hand.hand.cards.length == 2), isTrue);
      expect(hands.every((hand) => hand.fromSplit), isTrue);
      expect(hands.every((hand) => hand.outcome == HandOutcome.win), isTrue);
    });

    test('natural blackjack pays 3 to 2', () {
      final engine = _engine([
        CardRank.ace,
        CardRank.nine,
        CardRank.king,
        CardRank.seven,
        CardRank.ten,
      ]);

      engine.startRound();

      final hand = engine.seats.first.hands.single;
      expect(hand.outcome, HandOutcome.blackjack);
      expect(hand.resultUnits, 1.5);
    });

    test('bust loses and equal totals push', () {
      final bustEngine = _engine([
        CardRank.ten,
        CardRank.ten,
        CardRank.six,
        CardRank.seven,
        CardRank.ten,
      ]);
      bustEngine.startRound();
      bustEngine.applyAction(PlayerAction.hit);
      expect(bustEngine.seats.first.hands.single.outcome, HandOutcome.loss);
      expect(bustEngine.seats.first.hands.single.resultUnits, -1);

      final pushEngine = _engine([
        CardRank.ten,
        CardRank.ten,
        CardRank.seven,
        CardRank.seven,
      ]);
      pushEngine.startRound();
      pushEngine.applyAction(PlayerAction.stand);
      expect(pushEngine.seats.first.hands.single.outcome, HandOutcome.push);
      expect(pushEngine.seats.first.hands.single.resultUnits, 0);
    });

    test(
      'hole card enters count only when revealed and cards are conserved',
      () {
        final engine = _engine([
          CardRank.two,
          CardRank.ace,
          CardRank.three,
          CardRank.five,
          CardRank.ten,
          CardRank.king,
        ]);

        engine.startRound();
        expect(engine.dealerHoleRevealed, isFalse);
        expect(engine.countingEngine.runningCount, 1);
        expect(engine.dealtCards + engine.remainingCards, engine.totalCards);

        engine.applyAction(PlayerAction.stand);
        expect(engine.dealerHoleRevealed, isTrue);
        expect(engine.countingEngine.runningCount, 0);
        expect(engine.dealtCards + engine.remainingCards, engine.totalCards);
      },
    );

    test('a new round reshuffles once 75 percent penetration is reached', () {
      final cards = _fullStandardShoe();
      final shoe = Shoe.scripted(
        rules: GameRulesProfile.standard,
        cards: cards,
      );
      for (var index = 0; index < 234; index++) {
        shoe.draw();
      }
      final engine = BlackjackEngine(
        shoe: shoe,
        seatConfiguration: _singleHuman,
      );

      engine.startRound();

      expect(engine.reshuffledBeforeRound, isTrue);
      expect(engine.dealtCards, lessThan(32));
      expect(engine.dealtCards + engine.remainingCards, 312);
    });
  });
}

final _singleHuman = SeatConfiguration([
  SeatRole.human,
  SeatRole.empty,
  SeatRole.empty,
  SeatRole.empty,
  SeatRole.empty,
]);

BlackjackEngine _engine(List<CardRank> ranks) {
  return BlackjackEngine(
    shoe: Shoe.scripted(
      rules: GameRulesProfile.standard,
      cards: [
        for (var index = 0; index < ranks.length; index++)
          PlayingCard(
            deckIndex: index ~/ 52,
            suit: CardSuit.values[index % CardSuit.values.length],
            rank: ranks[index],
          ),
      ],
    ),
    seatConfiguration: _singleHuman,
  );
}

List<PlayingCard> _fullStandardShoe() {
  return [
    for (var deck = 0; deck < 6; deck++)
      for (final suit in CardSuit.values)
        for (final rank in CardRank.values)
          PlayingCard(deckIndex: deck, suit: suit, rank: rank),
  ];
}
