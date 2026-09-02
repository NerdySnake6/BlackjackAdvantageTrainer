import 'package:blackjack_advantage_trainer/domain/blackjack_engine/game_rules.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/strategy_engine.dart';
import 'package:blackjack_advantage_trainer/l10n/app_localizations_en.dart';
import 'package:blackjack_advantage_trainer/presentation/table/table_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final strings = AppLocalizationsEn();

  group('table_formatters', () {
    test('roleLabel and roleIcon cover all SeatRole values', () {
      expect(roleLabel(strings, SeatRole.human), strings.human);
      expect(roleLabel(strings, SeatRole.bot), strings.bot);
      expect(roleLabel(strings, SeatRole.empty), strings.empty);

      expect(roleIcon(SeatRole.human), Icons.person);
      expect(roleIcon(SeatRole.bot), Icons.smart_toy_outlined);
      expect(roleIcon(SeatRole.empty), Icons.event_seat_outlined);
    });

    test('outcomeLabel covers all HandOutcome values', () {
      expect(
        outcomeLabel(strings, HandOutcome.blackjack),
        strings.outcomeBlackjack,
      );
      expect(outcomeLabel(strings, HandOutcome.win), strings.outcomeWin);
      expect(outcomeLabel(strings, HandOutcome.push), strings.outcomePush);
      expect(outcomeLabel(strings, HandOutcome.loss), strings.outcomeLoss);
      expect(
        outcomeLabel(strings, HandOutcome.surrender),
        strings.outcomeSurrender,
      );
    });

    test('formatUnits formats whole and decimal numbers with signs', () {
      expect(formatUnits(2.0), '+2');
      expect(formatUnits(1.5), '+1.5');
      expect(formatUnits(0.0), '0');
      expect(formatUnits(-1.0), '-1');
      expect(formatUnits(-0.5), '-0.5');
    });

    test('actionLabel covers all PlayerAction values', () {
      expect(actionLabel(strings, PlayerAction.hit), strings.hit);
      expect(actionLabel(strings, PlayerAction.stand), strings.stand);
      expect(
        actionLabel(strings, PlayerAction.doubleDown),
        strings.doubleAction,
      );
      expect(actionLabel(strings, PlayerAction.split), strings.split);
      expect(actionLabel(strings, PlayerAction.surrender), strings.surrender);
    });

    test('reasonLabel covers all StrategyReason values', () {
      for (final reason in StrategyReason.values) {
        final label = reasonLabel(strings, reason);
        expect(label, isNotEmpty);
      }
      expect(
        reasonLabel(strings, StrategyReason.splitPair),
        strings.strategyReasonSplitPair,
      );
      expect(
        reasonLabel(strings, StrategyReason.standPair),
        strings.strategyReasonStandPair,
      );
      expect(
        reasonLabel(strings, StrategyReason.doublePair),
        strings.strategyReasonDoublePair,
      );
      expect(
        reasonLabel(strings, StrategyReason.hitPair),
        strings.strategyReasonHitPair,
      );
      expect(
        reasonLabel(strings, StrategyReason.surrenderHardTotal),
        strings.strategyReasonSurrenderHard,
      );
      expect(
        reasonLabel(strings, StrategyReason.doubleSoftTotal),
        strings.strategyReasonDoubleSoft,
      );
      expect(
        reasonLabel(strings, StrategyReason.standSoftTotal),
        strings.strategyReasonStandSoft,
      );
      expect(
        reasonLabel(strings, StrategyReason.hitSoftTotal),
        strings.strategyReasonHitSoft,
      );
      expect(
        reasonLabel(strings, StrategyReason.doubleHardTotal),
        strings.strategyReasonDoubleHard,
      );
      expect(
        reasonLabel(strings, StrategyReason.standHardTotal),
        strings.strategyReasonStandHard,
      );
      expect(
        reasonLabel(strings, StrategyReason.hitHardTotal),
        strings.strategyReasonHitHard,
      );
      expect(
        reasonLabel(strings, StrategyReason.unavailableActionFallback),
        strings.strategyReasonFallback,
      );
    });
  });
}
