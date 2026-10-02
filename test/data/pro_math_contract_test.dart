import 'dart:convert';
import 'dart:io';

import 'package:blackjack_advantage_trainer/domain/blackjack_engine/card.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/counting_engine.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/game_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, Object?> contract;
  setUp(() {
    contract =
        jsonDecode(File('docs/PRO_MATH_CONTRACT.json').readAsStringSync())
            as Map<String, Object?>;
  });

  test('contract profile matches the existing baseline without activation', () {
    final profile = contract['profile']! as Map<String, Object?>;
    const rules = GameRulesProfile.standard;
    expect(contract['schemaVersion'], 1);
    expect(contract['contractVersion'], 1);
    expect(contract['status'], 'specified-pending-independent-review');
    expect(contract['productionEnabled'], isFalse);
    expect(profile['id'], rules.id);
    expect(profile['deckCount'], rules.deckCount);
    expect(profile['cardsPerDeck'], 52);
    expect(profile['dealerHitsSoft17'], rules.dealerHitsSoft17);
    expect(profile['doubleAfterSplit'], rules.doubleAfterSplit);
    expect(profile['lateSurrender'], rules.lateSurrender);
    expect(profile['dealerPeek'], rules.dealerPeek);
    expect(profile['maxSplitHands'], rules.maxSplitHands);
    expect(
      (profile['blackjackProfitNumerator']! as int) /
          (profile['blackjackProfitDenominator']! as int),
      rules.blackjackPayout.profitUnits,
    );
    expect(
      (profile['penetrationNumerator']! as int) /
          (profile['penetrationDenominator']! as int),
      rules.penetration,
    );
  });

  test('contract covers all ranks and a balanced physical deck', () {
    final counting = contract['counting']! as Map<String, Object?>;
    final tags = counting['tags']! as Map<String, Object?>;
    expect(tags.keys.toSet(), CardRank.values.map((r) => r.name).toSet());
    var deckTotal = 0;
    for (final rank in CardRank.values) {
      final tag = tags[rank.name]! as int;
      expect(const [-1, 0, 1], contains(tag));
      for (final suit in CardSuit.values) {
        expect(PlayingCard(deckIndex: 0, suit: suit, rank: rank).hiLoTag, tag);
        deckTotal += tag;
      }
    }
    expect(deckTotal, 0);
    expect(counting['countOnlyExposed'], isTrue);
    expect(counting['oneRevealPerPhysicalCard'], isTrue);
    expect(counting['resetOnlyOnShuffle'], isTrue);
  });

  test('floor examples satisfy exact rational bounds, including negatives', () {
    final policy = contract['trueCount']! as Map<String, Object?>;
    expect(policy['rounding'], 'floor');
    expect(policy['nonPositiveDenominator'], 'invalid');
    final cases = (contract['trueCountCases']! as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(cases, hasLength(16));
    var negativeFractions = 0;
    var exactIntegers = 0;
    for (final sample in cases) {
      final rc = sample['runningCount']! as int;
      final q = sample['quarterDecks']! as int;
      final answer = sample['expectedFloor']! as int;
      expect(
        q,
        inInclusiveRange(
          policy['quarterDeckNumeratorMin']! as int,
          policy['quarterDeckNumeratorMax']! as int,
        ),
      );
      // Integer inequalities independently verify the authored answer. No
      // floating division, floor policy, or production converter is the oracle.
      expect(answer * q, lessThanOrEqualTo(4 * rc));
      expect((answer + 1) * q, greaterThan(4 * rc));
      if (4 * rc % q == 0) {
        exactIntegers++;
      } else if (rc < 0) {
        negativeFractions++;
      }
    }
    expect(negativeFractions, greaterThanOrEqualTo(4));
    expect(exactIntegers, greaterThanOrEqualTo(4));
  });

  test('legacy rounding and invalid-denominator fallback remain separate', () {
    final policy = contract['trueCount']! as Map<String, Object?>;
    expect(policy['legacyPolicyUnchanged'], isTrue);
    const legacy = NearestWholeTrueCountPolicy();
    expect(legacy.convert(runningCount: 7, decksRemaining: 4), 2);
    expect(legacy.convert(runningCount: -5, decksRemaining: 4), -1);
    expect(legacy.convert(runningCount: 5, decksRemaining: 0), 5);
  });

  test('finite-horizon toy risk has one exhaustion path out of four', () {
    final model = contract['riskDiagnostic']! as Map<String, Object?>;
    expect(model['model'], 'toy-not-blackjack');
    expect(model['horizonRounds'], 2);
    expect(model['initialUnits'], 2);
    expect(model['outcomes'], [-1, 1]);
    expect(model['equallyLikelyIndependentRounds'], isTrue);
    final outcomes = (model['outcomes']! as List<Object?>).cast<int>();
    var total = 0;
    var exhausted = 0;
    for (final first in outcomes) {
      for (final second in outcomes) {
        total++;
        final afterFirst = (model['initialUnits']! as int) + first;
        final afterSecond = afterFirst + second;
        if (afterFirst <= (model['exhaustionBoundary']! as int) ||
            afterSecond <= (model['exhaustionBoundary']! as int)) {
          exhausted++;
        }
      }
    }
    expect(total, model['expectedTotalPaths']);
    expect(exhausted, model['expectedExhaustionPaths']);
    expect(total, 4);
    expect(exhausted, 1);
  });

  test('unreviewed indices and blackjack risk distributions stay empty', () {
    final indices = contract['indices']! as Map<String, Object?>;
    final risk = contract['risk']! as Map<String, Object?>;
    expect(indices['type'], 'ev-maximizing');
    expect(indices['requiredIndependentReview'], isTrue);
    expect(indices['approvedEntries'], isEmpty);
    expect(
      indices['requiredFields'],
      containsAll([
        'profileId',
        'rounding',
        'comparison',
        'compositionSampling',
        'sourceLicense',
        'reviewApproval',
      ]),
    );
    expect(risk['approvedBlackjackDistributions'], isEmpty);
    expect(risk['units'], 'fictional');
    expect(risk['credit'], isFalse);
    expect(risk['replenishment'], isFalse);
    expect(risk['persistentBalance'], isFalse);
  });
}
