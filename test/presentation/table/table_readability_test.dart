import 'package:blackjack_advantage_trainer/domain/blackjack_engine/blackjack_engine.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/card.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/hand.dart';
import 'package:blackjack_advantage_trainer/l10n/app_localizations.dart';
import 'package:blackjack_advantage_trainer/presentation/table/player_spots_view.dart';
import 'package:blackjack_advantage_trainer/presentation/table/table_top_view.dart';
import 'package:blackjack_advantage_trainer/presentation/widgets/playing_card_view.dart';
import 'package:blackjack_advantage_trainer/viewmodels/table_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final locale in ['en', 'ru']) {
    testWidgets(
      '$locale all split hands and long cards remain available without scaling or oval clipping',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(568, 320);
        addTearDown(tester.view.reset);
        final vm = TableViewModel();
        addTearDown(vm.dispose);
        for (final seat in vm.engine.seats) {
          for (var hand = 0; hand < 4; hand++) {
            seat.hands.add(
              PlayerHandState(
                hand: BlackjackHand([
                  for (var card = 0; card < 2 + hand * 2; card++)
                    PlayingCard(
                      deckIndex: hand,
                      suit: CardSuit.hearts,
                      rank: CardRank.values[card],
                    ),
                ]),
              ),
            );
          }
        }
        vm.engine.dealerHand = BlackjackHand([
          const PlayingCard(
            deckIndex: 0,
            suit: CardSuit.clubs,
            rank: CardRank.ten,
          ),
          const PlayingCard(
            deckIndex: 0,
            suit: CardSuit.spades,
            rank: CardRank.ace,
          ),
        ]);
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: MediaQuery(
                data: const MediaQueryData(
                  size: Size(568, 320),
                  textScaler: TextScaler.linear(2),
                ),
                child: TableTopView(viewModel: vm),
              ),
            ),
          ),
        );
        expect(find.byType(PlayerHandView), findsNWidgets(20));
        expect(find.byType(FittedBox), findsNothing);
        expect(find.byType(ClipRRect), findsNothing);
        // Every split hand gets its own visibility; it is not capped by hand 1.
        expect(find.byType(PlayingCardView), findsNWidgets(102));
        expect(
          tester
              .widgetList<PlayingCardView>(find.byType(PlayingCardView))
              .where((c) => c.hidden),
          hasLength(1),
        );
        final scroll = tester.state<ScrollableState>(
          find.byType(Scrollable).first,
        );
        scroll.position.jumpTo(scroll.position.maxScrollExtent);
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(
          tester
              .widgetList<Text>(find.byType(Text))
              .where((t) => t.style?.fontSize == 16),
          isNotEmpty,
        );
      },
    );
  }
}
