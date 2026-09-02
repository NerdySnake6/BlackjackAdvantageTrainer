import 'dart:math';

import 'package:blackjack_advantage_trainer/domain/blackjack_engine/counting_engine.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/game_rules.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/shoe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Shoe and Hi-Lo', () {
    test('single-deck shoe contains 52 unique physical cards', () {
      final shoe = Shoe(rules: _rules(deckCount: 1), random: Random(4));
      final ids = <String>{};

      while (shoe.remainingCount > 0) {
        ids.add(shoe.draw().id);
      }

      expect(ids, hasLength(52));
      expect(shoe.dealtCount, 52);
    });

    test('a complete balanced deck finishes at running count zero', () {
      final shoe = Shoe(rules: _rules(deckCount: 1), random: Random(9));
      final counting = CountingEngine();

      while (shoe.remainingCount > 0) {
        counting.reveal(shoe.draw());
      }

      expect(counting.runningCount, 0);
      expect(counting.cardsSeen, 52);
    });

    test('75 percent of a six-deck shoe is 234 cards', () {
      final shoe = Shoe(rules: GameRulesProfile.standard, random: Random(3));

      for (var index = 0; index < 233; index++) {
        shoe.draw();
      }
      expect(shoe.penetrationReached, isFalse);

      shoe.draw();
      expect(shoe.dealtCount, 234);
      expect(shoe.penetrationReached, isTrue);
      expect(shoe.remainingCount, 78);
    });

    test(
      'true count rounds both positive and negative values consistently',
      () {
        const policy = NearestWholeTrueCountPolicy();

        expect(policy.convert(runningCount: 7, decksRemaining: 4), 2);
        expect(policy.convert(runningCount: -7, decksRemaining: 4), -2);
        expect(policy.convert(runningCount: 5, decksRemaining: 0), 5);
        expect(policy.convert(runningCount: -3, decksRemaining: -1), -3);
      },
    );

    test('reset clears running count and cards seen', () {
      final shoe = Shoe(rules: _rules(deckCount: 1), random: Random(1));
      final counting = CountingEngine();

      for (var index = 0; index < 10; index++) {
        counting.reveal(shoe.draw());
      }
      expect(counting.cardsSeen, 10);

      counting.reset();
      expect(counting.runningCount, 0);
      expect(counting.cardsSeen, 0);
    });

    test('estimateDecksRemaining handles edge cases and clamps to 0.5', () {
      final counting = CountingEngine();

      expect(counting.estimateDecksRemaining(0), 0.0);
      expect(counting.estimateDecksRemaining(-10), 0.0);
      expect(counting.estimateDecksRemaining(5), 0.5);
      expect(counting.estimateDecksRemaining(26), 0.5);
      expect(counting.estimateDecksRemaining(52), 1.0);
      expect(counting.estimateDecksRemaining(78), 1.5);
      expect(counting.estimateDecksRemaining(130), 2.5);
      expect(counting.estimateDecksRemaining(312), 6.0);
    });

    test('trueCount computes correct value via policy and deck estimation', () {
      final shoe = Shoe(rules: _rules(deckCount: 1), random: Random(2));
      final counting = CountingEngine();

      for (var index = 0; index < 20; index++) {
        counting.reveal(shoe.draw());
      }
      // Running count evaluated with 104 cards remaining (2.0 decks)
      final expected = (counting.runningCount / 2.0).round();
      expect(counting.trueCount(104), expected);
    });
  });
}

GameRulesProfile _rules({required int deckCount}) {
  return GameRulesProfile(
    id: 'test_$deckCount',
    name: 'Test',
    deckCount: deckCount,
    blackjackPayout: BlackjackPayout.threeToTwo,
    dealerHitsSoft17: false,
    doubleAfterSplit: true,
    lateSurrender: true,
    dealerPeek: true,
    penetration: 0.75,
  );
}
