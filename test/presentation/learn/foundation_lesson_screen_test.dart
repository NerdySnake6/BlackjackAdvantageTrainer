import 'dart:convert';

import 'package:blackjack_advantage_trainer/app/app.dart';
import 'package:blackjack_advantage_trainer/core/persistence/progress_repository.dart';
import 'package:blackjack_advantage_trainer/data/content_repository.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/game_rules.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:blackjack_advantage_trainer/l10n/app_localizations.dart';
import 'package:blackjack_advantage_trainer/presentation/learn/foundation_scene.dart';
import 'package:blackjack_advantage_trainer/presentation/learn/learning_path_screen.dart';
import 'package:blackjack_advantage_trainer/presentation/learn/lesson_screen.dart';
import 'package:blackjack_advantage_trainer/presentation/learn/pilot_lesson_screen.dart';
import 'package:blackjack_advantage_trainer/presentation/table/table_formatters.dart';
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
    for (final id in [
      'quick-start',
      'card-values',
      'hard-and-soft',
      'player-actions',
    ]) {
      testWidgets(
        '$locale $id: full 320px/200% journey, error, hint, reload and reward',
        (tester) async {
          final repository = _MemoryRepository();
          final apps = <AppState>[];
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(320, 568);
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(() async {
            await tester.pumpWidget(const SizedBox());
            for (final app in apps) {
              app.dispose();
            }
            tester.view.reset();
            tester.platformDispatcher.clearTextScaleFactorTestValue();
          });
          Future<AppState> open(ProgressSnapshot progress) async {
            final app = AppState(
              catalog: catalogs[locale]!,
              progress: progress,
              progressRepository: repository,
            );
            apps.add(app);
            await tester.pumpWidget(
              BlackjackTrainerApp(key: UniqueKey(), appState: app),
            );
            await tester.pumpAndSettle();
            final router = GoRouter.of(
              tester.element(find.byType(LearningPathScreen)),
            );
            router.go('/lesson/$id');
            await tester.pumpAndSettle();
            expect(find.byType(PilotLessonScreen), findsOneWidget);
            expect(find.byType(LessonScreen), findsNothing);
            return app;
          }

          var app = await open(
            ProgressSnapshot(
              experienceLevel: ExperienceLevel.experienced,
              hasSeenTelemetryConsent: true,
              languageCode: locale,
            ),
          );
          final lesson = catalogs[locale]!.foundationLessons.firstWhere(
            (l) => l.id == id,
          );
          final strings = AppLocalizations.of(
            tester.element(find.byType(PilotLessonScreen)),
          );
          repository.fail = true;
          await tapPilot(tester, find.byKey(const ValueKey('pilot-begin')));
          expect(app.progress.pilotSessions, isEmpty);
          expect(
            find.byKey(const ValueKey('pilot-save-error')),
            findsOneWidget,
          );
          repository.fail = false;
          await tapPilot(tester, find.byKey(const ValueKey('pilot-begin')));
          for (final (index, task) in lesson.scenarios.indexed) {
            if (index == 3) {
              await tapPilot(tester, find.byKey(const ValueKey('pilot-hint')));
            }
            if (task.requiresReveal) {
              for (var card = 0; card < task.cards.length; card++) {
                await tapPilot(
                  tester,
                  find.byKey(const ValueKey('foundation-deal')),
                );
                if (index == 5 && card == 0) {
                  final saved = app.progress.pilotSessions[id];
                  app = await open(await repository.load());
                  expect(app.progress.pilotSessions[id], saved);
                }
              }
              final scene = tester.widget<FoundationScene>(
                find.byType(FoundationScene),
              );
              expect(scene.showExplanation, index < 2 || index == 3);
              expect(scene.revealed, task.cards.length);
              if (index >= 7) {
                expect(
                  find.byKey(const ValueKey('foundation-revealed-total')),
                  findsNothing,
                );
                expect(find.byKey(const ValueKey('pilot-hint')), findsNothing);
              }
            }
            Future<void> answer(String value) async {
              if (task.usesNumber) {
                final current =
                    app.progress.pilotSessions[id]!['countInput'] as int? ?? 0;
                final delta = int.parse(value) - current;
                for (var i = 0; i < delta.abs(); i++) {
                  await tapPilot(
                    tester,
                    find.byTooltip(
                      delta > 0
                          ? strings.foundationIncrease
                          : strings.foundationDecrease,
                    ),
                  );
                }
                await tapPilot(
                  tester,
                  find.byKey(const ValueKey('foundation-submit')),
                );
              } else if (task.isHandMission) {
                await tapPilot(
                  tester,
                  find.byKey(ValueKey('foundation-answer-$value')),
                );
              } else {
                await tapPilot(
                  tester,
                  find.widgetWithText(
                    FilledButton,
                    actionLabel(strings, PlayerAction.values.byName(value)),
                  ),
                );
              }
            }

            if (index == 2) {
              final wrong = task.usesNumber
                  ? '0'
                  : task.answerKeys.firstWhere((a) => a != task.expected);
              await answer(wrong);
              final saved = app.progress.pilotSessions[id];
              app = await open(await repository.load());
              expect(app.progress.pilotSessions[id], saved);
              await answer(task.expected);
              expect(
                (app.progress.pilotSessions[id]!['answers'] as List).last,
                wrong,
              );
            } else {
              await answer(task.expected);
            }
            if (task.usesActions) {
              await tester.scrollUntilVisible(
                find.byKey(const ValueKey('foundation-action-result')),
                160,
                scrollable: find.byType(Scrollable).first,
              );
              expect(find.byType(FoundationActionResult), findsOneWidget);
            }
            await tapPilot(tester, find.byKey(const ValueKey('pilot-next')));
          }
          expect(app.progress.lessonScores[id], 0.9);
          expect(app.progress.xp, 140);
          expect(app.isLessonMastered(id), isFalse);
          expect(find.byKey(const ValueKey('pilot-checkpoint')), findsNothing);
          final saved = app.progress.pilotSessions[id]!;
          expect(
            (saved['hints'] as List).where((h) => h == true),
            hasLength(1),
          );
          app = await open(await repository.load());
          expect(app.progress.xp, 140);
          expect(find.text(strings.lessonResult(9, 10)), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
        timeout: const Timeout(Duration(seconds: 60)),
      );
    }
  }

  testWidgets(
    'old partial lesson remains reachable; experienced players bypass foundations',
    (tester) async {
      const old = LessonSessionProgress(
        nextExerciseIndex: 2,
        correctAnswers: 1,
      );
      final app = AppState(
        catalog: catalogs['en']!,
        progress: const ProgressSnapshot(
          xp: 700,
          streakDays: 9,
          languageCode: 'en',
          experienceLevel: ExperienceLevel.experienced,
          hasSeenTelemetryConsent: true,
          activeSessions: {'quick-start': old},
          lessonScores: {'card-values': 1},
        ),
        progressRepository: _MemoryRepository(),
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        app.dispose();
      });
      await tester.pumpWidget(BlackjackTrainerApp(appState: app));
      await tester.pumpAndSettle();
      expect(app.isLessonUnlocked('first-strategy'), isTrue);
      expect(app.isLessonCompleted('quick-start'), isFalse);
      final router = GoRouter.of(
        tester.element(find.byType(LearningPathScreen)),
      );
      router.go('/lesson/quick-start');
      await tester.pumpAndSettle();
      await tapPilot(
        tester,
        find.byKey(const ValueKey('foundation-legacy-resume')),
      );
      expect(find.byType(LessonScreen), findsOneWidget);
      expect(
        find.text(catalogs['en']!.lessons.first.exercises[2].prompt),
        findsOneWidget,
      );
      expect(app.progress.xp, 700);
      expect(app.progress.streakDays, 9);
      expect(app.progress.lessonScores['card-values'], 1);
      router.go('/checkpoint/card-values');
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, '/learn');
      router.go('/legacy-lesson/unknown');
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, '/learn');
    },
  );
}

class _MemoryRepository implements ProgressRepository {
  Map<String, Object?> snapshot = {};
  bool fail = false;
  @override
  Future<void> clear() async {
    snapshot = {};
  }

  @override
  Future<ProgressSnapshot> load() async => ProgressSnapshot.fromJson(snapshot);
  @override
  Future<void> save(ProgressSnapshot progress) async {
    if (fail) throw StateError('Simulated storage failure');
    snapshot =
        jsonDecode(jsonEncode(progress.toJson())) as Map<String, Object?>;
  }
}
