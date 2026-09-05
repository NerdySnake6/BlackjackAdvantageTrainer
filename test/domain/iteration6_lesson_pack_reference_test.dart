import 'dart:convert';
import 'dart:io';

import 'package:blackjack_advantage_trainer/domain/blackjack_engine/card.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/game_rules.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/hand.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/strategy_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const strategy = StrategyEngine();
  final allActions = PlayerAction.values.toSet();

  late Map<String, Object?> fixture;

  setUpAll(() {
    fixture =
        jsonDecode(
              File(
                'test/fixtures/iteration6_lesson_pack_reference.json',
              ).readAsStringSync(),
            )!
            as Map<String, Object?>;
  });

  test('reference fixture contains the three approved lesson packages', () {
    expect(fixture['schemaVersion'], 1);
    expect(fixture['profileId'], GameRulesProfile.standard.id);
    expect(fixture['source'], startsWith('https://wizardofodds.com/'));
    expect(fixture['independentReference'], contains('standard_strategy'));

    final packages = (fixture['packages']! as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(packages.map((package) => package['lessonId']), [
      'hard-12',
      'soft-18',
      'hi-lo-cancellation',
    ]);
    for (final package in packages) {
      expect((package['skillId']! as String).trim(), isNotEmpty);
      expect((package['theory']! as String).trim(), isNotEmpty);
      expect(package['misconceptions'], anyOf(hasLength(2), hasLength(3)));
      expect(package['guidedPractice'], isNotEmpty);
      expect(package['independentTest'], isA<Map<String, Object?>>());
    }
  });

  test('hard 12 reference cases match the validated strategy', () {
    final hard12 = _package('hard-12');
    final testData = hard12['independentTest']! as Map<String, Object?>;
    final cards = (testData['cards']! as List<Object?>).cast<String>();
    final cases = (testData['cases']! as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(cases, hasLength(10));

    for (final scenario in cases) {
      final recommendation = strategy.recommend(
        hand: BlackjackHand(cards.map(_cardFromLabel)),
        dealerUpCard: _card(_rank(scenario['dealer']! as String)),
        rules: GameRulesProfile.standard,
        availableActions: allActions,
      );
      expect(
        recommendation.name,
        scenario['expectedAction'],
        reason: 'hard-12 vs ${scenario['dealer']}',
      );
    }
  });

  test('soft 18 reference cases preserve double and fallback rules', () {
    final soft18 = _package('soft-18');
    final testData = soft18['independentTest']! as Map<String, Object?>;
    final twoCardCases = (testData['twoCardCases']! as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(twoCardCases, hasLength(10));

    for (final scenario in twoCardCases) {
      final recommendation = strategy.recommend(
        hand: BlackjackHand([_card(CardRank.ace), _card(CardRank.seven)]),
        dealerUpCard: _card(_rank(scenario['dealer']! as String)),
        rules: GameRulesProfile.standard,
        availableActions: allActions,
      );
      expect(
        recommendation.name,
        scenario['expectedAction'],
        reason: 'soft-18 vs ${scenario['dealer']}',
      );
    }

    final fallbackCases = (testData['fallbackCases']! as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(fallbackCases, hasLength(4));
    for (final scenario in fallbackCases) {
      final recommendation = strategy.recommendWithReason(
        hand: BlackjackHand(
          (scenario['cards']! as List<Object?>).cast<String>().map(
            _cardFromLabel,
          ),
        ),
        dealerUpCard: _card(_rank(scenario['dealer']! as String)),
        rules: GameRulesProfile.standard,
        availableActions: {PlayerAction.hit, PlayerAction.stand},
      );
      expect(recommendation.action, PlayerAction.stand);
      expect(recommendation.reason, StrategyReason.unavailableActionFallback);
    }
  });

  test('Hi-Lo cancellation reference uses an independent rank table', () {
    final cancellation = _package('hi-lo-cancellation');
    final testData = cancellation['independentTest']! as Map<String, Object?>;
    final cases = (testData['cases']! as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(cases, hasLength(5));

    for (final scenario in cases) {
      final cards = (scenario['cards']! as List<Object?>).cast<String>();
      final expectedTags = (scenario['expectedTags']! as List<Object?>)
          .cast<int>();
      final actualTags = cards.map(_referenceTag).toList();
      expect(actualTags, expectedTags, reason: cards.join(','));
      expect(
        actualTags.reduce((left, right) => left + right),
        scenario['expectedRunningCount'],
        reason: cards.join(','),
      );
    }
  });
}

Map<String, Object?> _package(String lessonId) {
  final raw =
      jsonDecode(
            File(
              'test/fixtures/iteration6_lesson_pack_reference.json',
            ).readAsStringSync(),
          )!
          as Map<String, Object?>;
  return (raw['packages']! as List<Object?>)
      .cast<Map<String, Object?>>()
      .firstWhere((package) => package['lessonId'] == lessonId);
}

PlayingCard _card(CardRank rank) =>
    PlayingCard(deckIndex: 0, suit: CardSuit.spades, rank: rank);

PlayingCard _cardFromLabel(String label) => _card(_rank(label));

CardRank _rank(String label) =>
    CardRank.values.firstWhere((rank) => rank.label == label);

int _referenceTag(String label) {
  return switch (label) {
    '2' || '3' || '4' || '5' || '6' => 1,
    '7' || '8' || '9' => 0,
    '10' || 'J' || 'Q' || 'K' || 'A' => -1,
    _ => throw ArgumentError.value(label, 'label'),
  };
}
