// Pilot UI on Android with real storage under isolated test keys.
import 'package:blackjack_advantage_trainer/app/app.dart';
import 'package:blackjack_advantage_trainer/data/content_repository.dart';
import 'package:blackjack_advantage_trainer/data/local_progress_repository.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:blackjack_advantage_trainer/viewmodels/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/support/pilot_journey.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final locale in ['en', 'ru']) {
    testWidgets(
      'Android $locale: three pilot lessons, storage reload, no duplicate reward',
      (tester) async {
        final catalog = await ContentRepository().loadCatalog(
          localeCode: locale,
        );
        final storage = _PilotStorage(locale);
        final repository = LocalProgressRepository.withStorage(storage);
        await repository.save(
          ProgressSnapshot(
            languageCode: locale,
            experienceLevel: ExperienceLevel.basics,
            hasSeenTelemetryConsent: true,
          ),
        );
        AppState? app;
        Future<AppState> reload() async {
          await tester.pumpWidget(const SizedBox());
          app?.dispose();
          app = AppState(
            catalog: catalog,
            progress: await repository.load(),
            progressRepository: repository,
          );
          await tester.pumpWidget(BlackjackTrainerApp(appState: app!));
          await tester.pumpAndSettle();
          return app!;
        }

        try {
          await reload();
          for (final lesson in catalog.pilotLessons) {
            await runPilotJourney(tester, app!, lesson, reloadApp: reload);
          }
          expect((await repository.load()).xp, 420);
        } finally {
          await tester.pumpWidget(const SizedBox());
          app?.dispose();
          await repository.clear();
        }
      },
    );
  }
}

class _PilotStorage implements ProgressStorage {
  _PilotStorage(this.locale);
  final String locale;
  final preferences = SharedPreferencesAsync();
  String _key(String key) => 'pilot_integration_${locale}_$key';

  @override
  Future<String?> getString(String key) => preferences.getString(_key(key));
  @override
  Future<void> remove(String key) => preferences.remove(_key(key));
  @override
  Future<void> setString(String key, String value) =>
      preferences.setString(_key(key), value);
}
