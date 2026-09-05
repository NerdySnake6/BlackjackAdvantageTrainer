import 'dart:convert';

import 'package:blackjack_advantage_trainer/app/app.dart';
import 'package:blackjack_advantage_trainer/core/persistence/progress_repository.dart';
import 'package:blackjack_advantage_trainer/data/content_repository.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:blackjack_advantage_trainer/viewmodels/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/pilot_journey.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final catalogs = <String, CourseCatalog>{};
  setUpAll(() async {
    for (final locale in ['en', 'ru']) {
      catalogs[locale] = await ContentRepository().loadCatalog(
        localeCode: locale,
      );
    }
  });

  for (final locale in ['en', 'ru']) {
    testWidgets(
      'all three $locale lessons work at 320px with large text and resume',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 568);
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        final repository = _Repository(
          ProgressSnapshot(
            experienceLevel: ExperienceLevel.basics,
            hasSeenTelemetryConsent: true,
            languageCode: locale,
          ),
        );
        AppState? app;
        Future<AppState> reload() async {
          await tester.pumpWidget(const SizedBox());
          app?.dispose();
          app = AppState(
            catalog: catalogs[locale]!,
            progress: await repository.load(),
            progressRepository: repository,
          );
          await tester.pumpWidget(BlackjackTrainerApp(appState: app!));
          await tester.pumpAndSettle();
          return app!;
        }

        addTearDown(() async {
          await tester.pumpWidget(const SizedBox());
          app?.dispose();
          tester.view.reset();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });
        await reload();
        for (final lesson in catalogs[locale]!.pilotLessons) {
          await runPilotJourney(tester, app!, lesson, reloadApp: reload);
        }
        expect(app!.progress.xp, 420);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _Repository implements ProgressRepository {
  _Repository(this.snapshot);
  ProgressSnapshot snapshot;
  @override
  Future<void> clear() async => snapshot = const ProgressSnapshot();
  @override
  Future<ProgressSnapshot> load() async => ProgressSnapshot.fromJson(
    jsonDecode(jsonEncode(snapshot.toJson())) as Map<String, Object?>,
  );
  @override
  Future<void> save(ProgressSnapshot snapshot) async =>
      this.snapshot = snapshot;
}
