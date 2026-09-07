import 'dart:math' as math;

import 'package:blackjack_advantage_trainer/app/theme.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/card.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/game_rules.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/hand.dart';
import 'package:blackjack_advantage_trainer/l10n/app_localizations.dart';
import 'package:blackjack_advantage_trainer/presentation/drill/cancellation_scene.dart';
import 'package:blackjack_advantage_trainer/presentation/learn/decision_scene.dart';
import 'package:blackjack_advantage_trainer/presentation/widgets/learn_card_view.dart';
import 'package:blackjack_advantage_trainer/presentation/widgets/playing_card_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

PlayingCard card(CardRank rank, [CardSuit suit = CardSuit.hearts]) =>
    PlayingCard(deckIndex: 0, suit: suit, rank: rank);

Widget host(Widget child, String locale, double scale) => MaterialApp(
  theme: buildAppTheme(),
  locale: Locale(locale),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: Scaffold(
      body: SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  ),
);

void main() {
  test(
    'Learn card inks meet 4.5:1 contrast without changing Table defaults',
    () {
      double ratio(Color first, Color second) {
        final a = first.computeLuminance();
        final b = second.computeLuminance();
        return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
      }

      expect(
        ratio(LearnCardView.redInk, AppColors.cream),
        greaterThanOrEqualTo(4.5),
      );
      expect(ratio(AppColors.ink, AppColors.cream), greaterThanOrEqualTo(4.5));
      expect(
        PlayingCardView(card: card(CardRank.ace)).redColor,
        const Color(0xFFC73B48),
      );
    },
  );

  for (final locale in ['en', 'ru']) {
    testWidgets(
      '$locale: rank/suit announced once and card grows with text size',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 568));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final names = locale == 'en'
            ? ['Ace', 'Jack', 'Queen', 'King', '2']
            : ['Туз', 'Валет', 'Дама', 'Король', '2'];
        final suits = locale == 'en'
            ? ['clubs', 'diamonds', 'hearts', 'spades']
            : ['треф', 'бубен', 'червей', 'пик'];
        for (final (index, rank) in [
          CardRank.ace,
          CardRank.jack,
          CardRank.queen,
          CardRank.king,
          CardRank.two,
        ].indexed) {
          for (final suit in CardSuit.values) {
            await tester.pumpWidget(
              host(LearnCardView(card: card(rank, suit), width: 52), locale, 2),
            );
            await tester.pumpAndSettle();
            final label = locale == 'en'
                ? '${names[index]} of ${suits[suit.index]}'
                : '${names[index]} ${suits[suit.index]}';
            expect(find.bySemanticsLabel(label), findsOneWidget);
            expect(
              find.bySemanticsLabel(card(rank, suit).suitSymbol),
              findsNothing,
            );
            expect(
              tester.getSize(find.byType(PlayingCardView)).width,
              closeTo(104, 0.01),
            );
            expect(tester.takeException(), isNull);
          }
        }
      },
    );

    for (final scale in [1.0, 2.0]) {
      testWidgets(
        '$locale: decision controls work at 320px/$scale with accessible targets',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(320, 568));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          PlayerAction? chosen;
          await tester.pumpWidget(
            host(
              DecisionScene(
                playerHand: BlackjackHand([
                  card(CardRank.ace),
                  card(CardRank.ace, CardSuit.clubs),
                  card(CardRank.six),
                ]),
                dealerUpCard: card(CardRank.six, CardSuit.spades),
                availableActions: const {PlayerAction.hit, PlayerAction.stand},
                onAction: (action) => chosen = action,
              ),
              locale,
              scale,
            ),
          );
          await tester.pumpAndSettle();
          final strings = AppLocalizations.of(
            tester.element(find.byType(DecisionScene)),
          );
          await tester.scrollUntilVisible(find.text(strings.stand), 150);
          await tester.ensureVisible(find.text(strings.stand));
          await tester.pumpAndSettle();
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          await tester.tap(find.text(strings.stand));
          expect(chosen, PlayerAction.stand);
          expect(tester.takeException(), isNull);
        },
        timeout: const Timeout(Duration(seconds: 30)),
      );

      testWidgets(
        '$locale: count reveal uses a labeled button, never a required gesture ($scale)',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(320, 568));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          var revealed = 0;
          await tester.pumpWidget(
            host(
              StatefulBuilder(
                builder: (context, setState) => CancellationScene(
                  sequence: [card(CardRank.three), card(CardRank.king)],
                  revealedCount: revealed,
                  runningCount: 0,
                  showExplanation: false,
                  onRevealNext: () => setState(() => revealed++),
                ),
              ),
              locale,
              scale,
            ),
          );
          await tester.pumpAndSettle();
          final strings = AppLocalizations.of(
            tester.element(find.byType(CancellationScene)),
          );
          for (var i = 0; i < 2; i++) {
            await tester.ensureVisible(find.text(strings.nextCard));
            await tester.pumpAndSettle();
            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
            await expectLater(
              tester,
              meetsGuideline(labeledTapTargetGuideline),
            );
            await expectLater(tester, meetsGuideline(textContrastGuideline));
            await tester.tap(find.text(strings.nextCard));
            await tester.pumpAndSettle();
          }
          expect(revealed, 2);
          expect(find.text(strings.currentCount(0)), findsNothing);
          expect(tester.takeException(), isNull);
        },
        timeout: const Timeout(Duration(seconds: 30)),
      );
    }
  }
}
