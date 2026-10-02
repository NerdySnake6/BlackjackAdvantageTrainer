// Native Android orientation with real storage under isolated test keys.
import 'package:blackjack_advantage_trainer/app/app.dart';
import 'package:blackjack_advantage_trainer/data/content_repository.dart';
import 'package:blackjack_advantage_trainer/data/local_progress_repository.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/game_rules.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:blackjack_advantage_trainer/l10n/app_localizations.dart';
import 'package:blackjack_advantage_trainer/presentation/table/player_spots_view.dart';
import 'package:blackjack_advantage_trainer/presentation/table/table_top_view.dart';
import 'package:blackjack_advantage_trainer/viewmodels/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final locale in ['en', 'ru']) {
    testWidgets(
      'Android $locale: solo/full native orientation keeps the round',
      (tester) async {
        final catalog = await ContentRepository().loadCatalog(
          localeCode: locale,
        );
        final repository = LocalProgressRepository.withStorage(
          _PresetStorage(locale),
        );
        await repository.save(
          ProgressSnapshot(
            languageCode: locale,
            experienceLevel: ExperienceLevel.beginner,
            hasSeenTelemetryConsent: true,
          ),
        );
        final state = AppState(
          catalog: catalog,
          progress: await repository.load(),
          progressRepository: repository,
        );
        final strings = lookupAppLocalizations(Locale(locale));
        try {
          await tester.pumpWidget(BlackjackTrainerApp(appState: state));
          await tester.pumpAndSettle();
          await _tap(tester, find.text(strings.tableTab));
          await _waitOrientation(tester, portrait: true);
          final vm = tester
              .widget<TableTopView>(find.byType(TableTopView))
              .viewModel;
          expect(vm.isSinglePlayer, isTrue);
          expect(
            vm.configuredSeatRoles.where((r) => r == SeatRole.empty),
            hasLength(4),
          );
          expect(find.byType(PlayerSpot), findsOneWidget);

          await _tap(tester, find.byTooltip(strings.configureSeats));
          await _tap(tester, find.byKey(const ValueKey('table-preset-full')));
          await _waitOrientation(tester, portrait: false);
          expect(vm.isSinglePlayer, isFalse);
          expect(
            tester.widget<TableTopView>(find.byType(TableTopView)).viewModel,
            same(vm),
          );
          await _tap(tester, find.text(strings.done));
          expect(find.byType(PlayerSpot), findsNWidgets(5));

          // Test during dealing, before a random natural blackjack can end it.
          vm.startRound();
          await tester.pump();
          final dealt = vm.engine.dealtCards;
          final count = vm.engine.countingEngine.runningCount;
          await tester.tap(find.byTooltip(strings.configureSeats));
          await tester.pump(const Duration(milliseconds: 300));
          expect(vm.isDealing, isTrue);
          final preset = tester.widget<OutlinedButton>(
            find.byKey(const ValueKey('table-preset-solo')),
          );
          expect(preset.onPressed, isNull);
          expect(vm.setSinglePlayer(true), isFalse);
          expect(vm.engine.dealtCards, dealt);
          expect(vm.engine.countingEngine.runningCount, count);
          expect(vm.isSinglePlayer, isFalse);
          await _tap(tester, find.text(strings.done));
          await tester.pump(const Duration(seconds: 5));
          expect(
            tester.widget<TableTopView>(find.byType(TableTopView)).viewModel,
            same(vm),
          );
          expect(vm.engine.dealtCards, dealt);
          expect(tester.takeException(), isNull);

          await _tap(tester, find.byTooltip(strings.backToPath));
          await _waitOrientation(tester, portrait: true);
          expect(find.byType(TableTopView), findsNothing);
          expect(
            (await repository.load()).experienceLevel,
            ExperienceLevel.beginner,
          );
          expect((await repository.load()).languageCode, locale);
        } finally {
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
          state.dispose();
          await repository.clear();
        }
      },
    );
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

Future<void> _waitOrientation(
  WidgetTester tester, {
  required bool portrait,
}) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.pump(const Duration(milliseconds: 250));
    final size = tester.view.physicalSize;
    if ((size.height > size.width) == portrait) {
      return;
    }
  }
  fail(
    'Native orientation did not become ${portrait ? 'portrait' : 'landscape'}',
  );
}

class _PresetStorage implements ProgressStorage {
  _PresetStorage(this.locale);
  final String locale;
  final preferences = SharedPreferencesAsync();
  String _key(String key) => 'table_preset_integration_${locale}_$key';

  @override
  Future<String?> getString(String key) => preferences.getString(_key(key));
  @override
  Future<void> remove(String key) => preferences.remove(_key(key));
  @override
  Future<void> setString(String key, String value) =>
      preferences.setString(_key(key), value);
}
