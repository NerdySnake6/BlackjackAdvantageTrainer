import 'package:blackjack_advantage_trainer/domain/blackjack_engine/card.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/game_rules.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/hand.dart';
import 'package:blackjack_advantage_trainer/l10n/app_localizations.dart';
import 'package:blackjack_advantage_trainer/presentation/learn/decision_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the dealer up-card, player hand, and unavailable Double', (
    tester,
  ) async {
    final selected = <PlayerAction>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DecisionScene(
            playerHand: BlackjackHand([
              _card(CardRank.ace),
              _card(CardRank.seven),
            ]),
            dealerUpCard: _card(CardRank.six),
            availableActions: {PlayerAction.hit, PlayerAction.stand},
            onAction: selected.add,
          ),
        ),
      ),
    );

    expect(find.text('Dealer'), findsOneWidget);
    expect(find.text('Hit'), findsOneWidget);
    expect(find.text('Stand'), findsOneWidget);
    expect(find.text('Double'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Double'))
          .onPressed,
      isNull,
    );

    await tester.tap(find.text('Stand'));
    expect(selected, [PlayerAction.stand]);
  });
}

PlayingCard _card(CardRank rank) =>
    PlayingCard(deckIndex: 0, suit: CardSuit.spades, rank: rank);
