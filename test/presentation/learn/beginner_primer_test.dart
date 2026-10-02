import 'package:blackjack_advantage_trainer/l10n/app_localizations.dart';
import 'package:blackjack_advantage_trainer/presentation/learn/beginner_primer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/pilot_journey.dart';

void main() {
  for (final locale in ['en', 'ru']) {
    testWidgets(
      '$locale unscored basics reveal 17, bust 24, blackjack 21 at 320px/200%',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 568);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                child: ListView(children: const [BeginnerPrimer()]),
              ),
            ),
          ),
        );
        final strings = AppLocalizations.of(
          tester.element(find.byType(BeginnerPrimer)),
        );
        for (final example in [(2, 17), (3, 24), (2, 21)]) {
          for (var card = 0; card < example.$1; card++) {
            await tapPilot(tester, find.byKey(const ValueKey('primer-reveal')));
          }
          expect(find.text(strings.handTotal(example.$2)), findsOneWidget);
          if (example.$2 != 21) {
            await tapPilot(tester, find.byKey(const ValueKey('primer-next')));
          }
        }
        expect(find.byKey(const ValueKey('primer-reveal')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
