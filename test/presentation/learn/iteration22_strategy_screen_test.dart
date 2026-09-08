import 'dart:convert';

import 'package:blackjack_advantage_trainer/app/app.dart';
import 'package:blackjack_advantage_trainer/core/persistence/progress_repository.dart';
import 'package:blackjack_advantage_trainer/data/content_repository.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:blackjack_advantage_trainer/presentation/learn/learning_path_screen.dart';
import 'package:blackjack_advantage_trainer/presentation/learn/pilot_lesson_screen.dart';
import 'package:blackjack_advantage_trainer/viewmodels/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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
      '$locale strategy lessons: 320px/200%, first-answer error, hint and storage reload',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 568);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        final repository = _Repository(
          ProgressSnapshot(
            experienceLevel: ExperienceLevel.experienced,
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
        for (final lesson in catalogs[locale]!.strategyLessons) {
          await runPilotJourney(
            tester,
            app!,
            lesson,
            reloadApp: reload,
            entryKeyPrefix: 'strategy',
          );
          expect(app!.isLessonMastered(lesson.id), isFalse);
        }
        expect(app!.progress.xp, 420);
        expect(tester.takeException(), isNull);
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );
  }

  testWidgets(
    'switching lesson ids replaces the session; no fabricated checkpoint for first-strategy',
    (tester) async {
      final repository = _Repository(
        const ProgressSnapshot(
          experienceLevel: ExperienceLevel.experienced,
          hasSeenTelemetryConsent: true,
          lessonScores: {'first-strategy': 1},
        ),
      );
      final app = AppState(
        catalog: catalogs['en']!,
        progress: await repository.load(),
        progressRepository: repository,
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        app.dispose();
      });
      await tester.pumpWidget(BlackjackTrainerApp(appState: app));
      await tester.pumpAndSettle();
      final router = GoRouter.of(
        tester.element(find.byType(LearningPathScreen)),
      );
      for (final lesson in catalogs['en']!.strategyLessons) {
        router.go('/lesson/${lesson.id}');
        await tester.pumpAndSettle();
        expect(find.byType(PilotLessonScreen), findsOneWidget);
        expect(find.text(lesson.theory), findsOneWidget);
      }
      router.go('/checkpoint/first-strategy');
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, '/learn');
    },
  );
}

class _Repository implements ProgressRepository {
  _Repository(this.snapshot);
  ProgressSnapshot snapshot;
  @override
  Future<void> clear() async {
    snapshot = const ProgressSnapshot();
  }

  @override
  Future<ProgressSnapshot> load() async => ProgressSnapshot.fromJson(
    jsonDecode(jsonEncode(snapshot.toJson())) as Map<String, Object?>,
  );
  @override
  Future<void> save(ProgressSnapshot value) async {
    snapshot = value;
  }
}
