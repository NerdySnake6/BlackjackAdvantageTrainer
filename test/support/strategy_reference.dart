import 'dart:convert';
import 'dart:io';

import 'package:blackjack_advantage_trainer/domain/blackjack_engine/game_rules.dart';

import 'hand_reference.dart';

final strategyReference =
    jsonDecode(
          File(
            'test/fixtures/standard_strategy_s17_das_ls.json',
          ).readAsStringSync(),
        )
        as Map;

String strategyFamily(List<String> ranks, Set<PlayerAction> actions) {
  final (_, soft) = referenceHand(ranks);
  return actions.contains(PlayerAction.split)
      ? 'pairs'
      : soft
      ? 'soft'
      : 'hard';
}

String strategyRow(List<String> ranks, String family) {
  final (total, _) = referenceHand(ranks);
  return family == 'pairs'
      ? ranks.first == 'A'
            ? 'A'
            : '${int.tryParse(ranks.first) ?? 10}'
      : '${family == 'hard' && total >= 17 ? 17 : total}';
}

String referenceStrategy(
  List<String> ranks,
  String dealer,
  Set<PlayerAction> actions,
) {
  final family = strategyFamily(ranks, actions);
  final row = strategyRow(ranks, family);
  final column = (strategyReference['dealerOrder'] as List).indexOf(
    const ['J', 'Q', 'K'].contains(dealer) ? '10' : dealer,
  );
  final code = ((strategyReference[family] as Map)[row] as String)[column];
  final answer = (strategyReference['codes'] as Map)[code] as String;
  if (actions.any((a) => a.name == answer)) return answer;
  final (total, soft) = referenceHand(ranks);
  return soft && total == 18 && answer == 'doubleDown' ? 'stand' : 'hit';
}

String strategyFingerprint(List<String> ranks, String? dealer) {
  final sorted = List<String>.of(ranks)..sort();
  return '${sorted.join(',')}/$dealer';
}
