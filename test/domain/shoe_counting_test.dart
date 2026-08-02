import 'dart:math';

import 'package:blackjack_advantage_trainer/domain/blackjack/counting_engine.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack/game_rules.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack/shoe.dart';
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
      },
    );
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
