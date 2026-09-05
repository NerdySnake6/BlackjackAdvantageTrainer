/// Basic-strategy recommendations for the validated standard rule profile.
library;

import 'card.dart';
import 'game_rules.dart';
import 'hand.dart';

enum StrategyReason {
  splitPair,
  standPair,
  doublePair,
  hitPair,
  surrenderHardTotal,
  doubleSoftTotal,
  standSoftTotal,
  hitSoftTotal,
  doubleHardTotal,
  standHardTotal,
  hitHardTotal,
  unavailableActionFallback,
}

class StrategyRecommendation {
  const StrategyRecommendation({required this.action, required this.reason});

  final PlayerAction action;
  final StrategyReason reason;
}

class StrategyEngine {
  const StrategyEngine({this.evaluator = const HandEvaluator()});

  final HandEvaluator evaluator;

  PlayerAction recommend({
    required BlackjackHand hand,
    required PlayingCard dealerUpCard,
    required GameRulesProfile rules,
    required Set<PlayerAction> availableActions,
  }) => recommendWithReason(
    hand: hand,
    dealerUpCard: dealerUpCard,
    rules: rules,
    availableActions: availableActions,
  ).action;

  StrategyRecommendation recommendWithReason({
    required BlackjackHand hand,
    required PlayingCard dealerUpCard,
    required GameRulesProfile rules,
    required Set<PlayerAction> availableActions,
  }) {
    var preferredActionUnavailable = false;
    if (hand.cards.length == 2 && _isPair(hand)) {
      final pairAction = _pairAction(
        hand.cards.first.rank.blackjackValue,
        dealerUpCard.rank.blackjackValue,
        rules,
      );
      if (pairAction == PlayerAction.split &&
          availableActions.contains(PlayerAction.split)) {
        return const StrategyRecommendation(
          action: PlayerAction.split,
          reason: StrategyReason.splitPair,
        );
      }
      if (pairAction == PlayerAction.split) {
        preferredActionUnavailable = true;
      }
      if (pairAction != PlayerAction.split) {
        return _recommendAvailable(
          pairAction,
          availableActions,
          switch (pairAction) {
            PlayerAction.stand => StrategyReason.standPair,
            PlayerAction.doubleDown => StrategyReason.doublePair,
            _ => StrategyReason.hitPair,
          },
        );
      }
    }

    final evaluation = evaluator.evaluate(hand.cards);
    final dealerValue = dealerUpCard.rank.blackjackValue;

    final shouldSurrender =
        !evaluation.isSoft &&
        ((evaluation.total == 16 && (dealerValue == 1 || dealerValue >= 9)) ||
            (evaluation.total == 15 && dealerValue == 10));
    if (shouldSurrender && availableActions.contains(PlayerAction.surrender)) {
      return StrategyRecommendation(
        action: PlayerAction.surrender,
        reason: preferredActionUnavailable
            ? StrategyReason.unavailableActionFallback
            : StrategyReason.surrenderHardTotal,
      );
    }
    if (shouldSurrender) {
      preferredActionUnavailable = true;
    }

    final preferred = evaluation.isSoft
        ? _softAction(evaluation.total, dealerValue)
        : _hardAction(evaluation.total, dealerValue);
    final reason = evaluation.isSoft
        ? switch (preferred) {
            PlayerAction.doubleDown => StrategyReason.doubleSoftTotal,
            PlayerAction.stand => StrategyReason.standSoftTotal,
            _ => StrategyReason.hitSoftTotal,
          }
        : switch (preferred) {
            PlayerAction.doubleDown => StrategyReason.doubleHardTotal,
            PlayerAction.stand => StrategyReason.standHardTotal,
            _ => StrategyReason.hitHardTotal,
          };
    // Soft 18 uses double-or-stand, unlike the other double-or-hit totals.
    if (evaluation.isSoft &&
        evaluation.total == 18 &&
        preferred == PlayerAction.doubleDown &&
        !availableActions.contains(PlayerAction.doubleDown)) {
      return const StrategyRecommendation(
        action: PlayerAction.stand,
        reason: StrategyReason.unavailableActionFallback,
      );
    }
    final recommendation = _recommendAvailable(
      preferred,
      availableActions,
      reason,
    );
    if (preferredActionUnavailable &&
        recommendation.reason != StrategyReason.unavailableActionFallback) {
      return StrategyRecommendation(
        action: recommendation.action,
        reason: StrategyReason.unavailableActionFallback,
      );
    }
    return recommendation;
  }

  bool _isPair(BlackjackHand hand) {
    return hand.cards[0].rank.blackjackValue ==
        hand.cards[1].rank.blackjackValue;
  }

  PlayerAction _pairAction(
    int pairValue,
    int dealerValue,
    GameRulesProfile rules,
  ) {
    return switch (pairValue) {
      1 || 8 => PlayerAction.split,
      10 => PlayerAction.stand,
      9 =>
        (dealerValue >= 2 && dealerValue <= 6) ||
                dealerValue == 8 ||
                dealerValue == 9
            ? PlayerAction.split
            : PlayerAction.stand,
      7 =>
        dealerValue >= 2 && dealerValue <= 7
            ? PlayerAction.split
            : PlayerAction.hit,
      6 =>
        dealerValue >= (rules.doubleAfterSplit ? 2 : 3) && dealerValue <= 6
            ? PlayerAction.split
            : PlayerAction.hit,
      5 =>
        dealerValue >= 2 && dealerValue <= 9
            ? PlayerAction.doubleDown
            : PlayerAction.hit,
      4 =>
        rules.doubleAfterSplit && dealerValue >= 5 && dealerValue <= 6
            ? PlayerAction.split
            : PlayerAction.hit,
      2 || 3 =>
        dealerValue >= (rules.doubleAfterSplit ? 2 : 4) && dealerValue <= 7
            ? PlayerAction.split
            : PlayerAction.hit,
      _ => PlayerAction.hit,
    };
  }

  PlayerAction _softAction(int total, int dealerValue) {
    if (total >= 19) {
      return PlayerAction.stand;
    }
    if (total == 18) {
      if (dealerValue >= 3 && dealerValue <= 6) {
        return PlayerAction.doubleDown;
      }
      if (dealerValue == 2 || dealerValue == 7 || dealerValue == 8) {
        return PlayerAction.stand;
      }
      return PlayerAction.hit;
    }
    if (total == 17 && dealerValue >= 3 && dealerValue <= 6) {
      return PlayerAction.doubleDown;
    }
    if ((total == 15 || total == 16) && dealerValue >= 4 && dealerValue <= 6) {
      return PlayerAction.doubleDown;
    }
    if ((total == 13 || total == 14) && dealerValue >= 5 && dealerValue <= 6) {
      return PlayerAction.doubleDown;
    }
    return PlayerAction.hit;
  }

  PlayerAction _hardAction(int total, int dealerValue) {
    if (total >= 17) {
      return PlayerAction.stand;
    }
    if (total >= 13) {
      return dealerValue >= 2 && dealerValue <= 6
          ? PlayerAction.stand
          : PlayerAction.hit;
    }
    if (total == 12) {
      return dealerValue >= 4 && dealerValue <= 6
          ? PlayerAction.stand
          : PlayerAction.hit;
    }
    if (total == 11) {
      return dealerValue == 1 ? PlayerAction.hit : PlayerAction.doubleDown;
    }
    if (total == 10) {
      return dealerValue >= 2 && dealerValue <= 9
          ? PlayerAction.doubleDown
          : PlayerAction.hit;
    }
    if (total == 9) {
      return dealerValue >= 3 && dealerValue <= 6
          ? PlayerAction.doubleDown
          : PlayerAction.hit;
    }
    return PlayerAction.hit;
  }

  PlayerAction _availableOrFallback(
    PlayerAction preferred,
    Set<PlayerAction> availableActions,
  ) {
    if (availableActions.contains(preferred)) {
      return preferred;
    }
    if (preferred == PlayerAction.doubleDown ||
        preferred == PlayerAction.surrender ||
        preferred == PlayerAction.split) {
      return PlayerAction.hit;
    }
    return PlayerAction.stand;
  }

  StrategyRecommendation _recommendAvailable(
    PlayerAction preferred,
    Set<PlayerAction> availableActions,
    StrategyReason reason,
  ) {
    final action = _availableOrFallback(preferred, availableActions);
    return StrategyRecommendation(
      action: action,
      reason: action == preferred
          ? reason
          : StrategyReason.unavailableActionFallback,
    );
  }
}
