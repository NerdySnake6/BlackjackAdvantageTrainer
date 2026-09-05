import 'package:blackjack_advantage_trainer/domain/blackjack_engine/card.dart';
import 'package:blackjack_advantage_trainer/l10n/app_localizations.dart';
import 'package:blackjack_advantage_trainer/presentation/drill/cancellation_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('reveals tags and marks a low/high cancellation pair', (
    tester,
  ) async {
    var revealedCount = 2;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CancellationScene(
            sequence: [
              _card(CardRank.five),
              _card(CardRank.king),
              _card(CardRank.eight),
            ],
            revealedCount: revealedCount,
            runningCount: 0,
            onRevealNext: () => revealedCount++,
          ),
        ),
      ),
    );

    expect(find.text('5'), findsOneWidget);
    expect(find.text('K'), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);
    expect(find.text('−1'), findsOneWidget);
    expect(find.byIcon(Icons.sync_alt_rounded), findsOneWidget);
    expect(find.text('Running count: 0'), findsOneWidget);
    final strings = AppLocalizations.of(
      tester.element(find.byType(CancellationScene)),
    );
    final nextCardButton = find.widgetWithText(FilledButton, strings.nextCard);
    expect(nextCardButton, findsOneWidget);

    await tester.tap(nextCardButton);
    expect(revealedCount, 3);
  });
}

PlayingCard _card(CardRank rank) =>
    PlayingCard(deckIndex: 0, suit: CardSuit.spades, rank: rank);
