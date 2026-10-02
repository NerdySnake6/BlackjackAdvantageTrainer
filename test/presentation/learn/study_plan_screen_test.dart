import 'dart:convert';

import 'package:blackjack_advantage_trainer/app/router.dart';
import 'package:blackjack_advantage_trainer/app/theme.dart';
import 'package:blackjack_advantage_trainer/core/persistence/progress_repository.dart';
import 'package:blackjack_advantage_trainer/data/content_repository.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/game_rules.dart';
import 'package:blackjack_advantage_trainer/domain/learning/learn_review.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:blackjack_advantage_trainer/l10n/app_localizations.dart';
import 'package:blackjack_advantage_trainer/presentation/learn/foundation_scene.dart';
import 'package:blackjack_advantage_trainer/presentation/table/table_formatters.dart';
import 'package:blackjack_advantage_trainer/viewmodels/app_state.dart';
import 'package:blackjack_advantage_trainer/viewmodels/learn_review_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../support/pilot_journey.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final catalogs = <String, CourseCatalog>{};
  final now = DateTime.utc(2026, 10, 2);
  setUpAll(() async {
    for (final locale in ['en', 'ru']) {
      catalogs[locale] = await ContentRepository().loadCatalog(
        localeCode: locale,
      );
    }
  });
  for (final locale in ['en', 'ru']) {
    testWidgets(
      '$locale: one due review at 320px/200%, all scenes, reload, no XP or mastery',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 568);
        final repository = _Repository(
          ProgressSnapshot(
            languageCode: locale,
            hasSeenTelemetryConsent: true,
            experienceLevel: ExperienceLevel.experienced,
            xp: 500,
            streakDays: 3,
            lessonScores: const {
              'first-strategy': 0.9,
              'hi-lo-chunks': 0.9,
              'expected-value': 0.9,
              'hard-and-soft': 0.9,
            },
            learnReviews: {
              for (final id in [
                'first-strategy',
                'hi-lo-chunks',
                'expected-value',
                'hard-and-soft',
              ])
                id: LearnReviewSchedule(
                  dueAt: now.subtract(const Duration(days: 1)),
                ).toJson(),
            },
          ),
        );
        AppState? app;
        GoRouter? router;
        Future<void> mount({String path = '/learn'}) async {
          await tester.pumpWidget(const SizedBox());
          router?.dispose();
          app?.dispose();
          app = AppState(
            catalog: catalogs[locale]!,
            progress: await repository.load(),
            progressRepository: repository,
            clock: () => now,
          );
          router = createRouter(appState: app!)..go(path);
          await tester.pumpWidget(
            ChangeNotifierProvider.value(
              value: app!,
              child: MaterialApp.router(
                routerConfig: router,
                theme: buildAppTheme(),
                locale: Locale(locale),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(2)),
                  child: child!,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        addTearDown(() async {
          await tester.pumpWidget(const SizedBox());
          router?.dispose();
          app?.dispose();
          tester.view.reset();
        });
        await mount();
        for (var iteration = 0; iteration < 4; iteration++) {
          await tapPilot(tester, find.byKey(const ValueKey('study-review')));
          var element = tester.element(find.byType(Scaffold).last);
          var vm = element.read<LearnReviewViewModel>();
          final strings = AppLocalizations.of(element);
          final task = vm.session.task;
          if (task.requiresReveal) {
            while (vm.session.revealed < task.revealLimit) {
              if (task.isMathComparison) {
                await tapPilot(
                  tester,
                  find.byKey(ValueKey('math-reveal-${vm.session.revealed}')),
                );
              } else if (task.isHandMission) {
                await tapPilot(
                  tester,
                  find.byKey(const ValueKey('foundation-deal')),
                );
              } else {
                await tapPilot(
                  tester,
                  find.widgetWithText(
                    FilledButton,
                    task.chunked ? strings.revealChunk : strings.nextCard,
                  ),
                );
              }
              if (vm.session.revealed == 1) {
                final before = vm.session.toJson();
                await mount(path: '/learn-review/${vm.lesson.id}');
                element = tester.element(find.byType(Scaffold).last);
                vm = element.read<LearnReviewViewModel>();
                expect(vm.session.toJson(), before);
              }
            }
          }
          if (task.isMathComparison) {
            await tapPilot(
              tester,
              find.byKey(ValueKey('math-answer-${task.expected}')),
            );
          } else if (task.isCounting) {
            final delta = int.parse(task.expected) - vm.session.input;
            for (var step = 0; step < delta.abs(); step++) {
              await tapPilot(
                tester,
                find.byKey(
                  ValueKey(
                    delta > 0 ? 'learn-review-plus' : 'learn-review-minus',
                  ),
                ),
              );
            }
            await tapPilot(
              tester,
              find.byKey(const ValueKey('learn-review-answer')),
            );
          } else if (task.isHandMission) {
            await tapPilot(
              tester,
              find.widgetWithText(
                FilledButton,
                foundationAnswerLabel(strings, task.expected),
              ),
            );
          } else {
            await tapPilot(
              tester,
              find.widgetWithText(
                FilledButton,
                actionLabel(strings, PlayerAction.values.byName(task.expected)),
              ),
            );
          }
          expect(vm.session.correct, isTrue);
          expect(app!.progress.xp, 500);
          expect(app!.progress.streakDays, 3);
          expect(app!.progress.masteryChecks, isEmpty);
          expect(app!.progress.exerciseReviewStates, isEmpty);
          final due = LearnReviewSchedule.fromJson(
            app!.progress.learnReviews[vm.lesson.id]!,
          );
          expect(due.dueAt, now.add(const Duration(days: 3)));
          await tapPilot(
            tester,
            find.widgetWithText(TextButton, strings.backToPath),
          );
        }
        expect(app!.studyPlan.reviewLesson, isNull);
        expect(app!.studyPlan.nextLesson!.id, 'dealer-upcard');
        expect(tester.takeException(), isNull);
      },
    );
  }
  test(
    'corrupt review restarts in isolation and persists its new attempt',
    () async {
      final lesson = catalogs['en']!.strategyLessons.first;
      final repository = _Repository(
        const ProgressSnapshot(
          xp: 100,
          lessonScores: {'first-strategy': 0.8},
          learnReviewSessions: {
            'first-strategy': {'attempt': 'broken'},
          },
          learnReviews: {
            'first-strategy': {'dueAt': 'broken'},
          },
        ),
      );
      final app = AppState(
        catalog: catalogs['en']!,
        progress: repository.snapshot,
        progressRepository: repository,
        clock: () => now,
      );
      var vm = LearnReviewViewModel(appState: app, lesson: lesson);
      expect(vm.incompatible, isTrue);
      await vm.restart();
      expect(vm.incompatible, isFalse);
      expect(vm.session.attempt, 1);
      vm.dispose();
      vm = LearnReviewViewModel(appState: app, lesson: lesson);
      expect(vm.session.attempt, 1);
      final wrong = vm.session.task.answerKeys.firstWhere(
        (value) => value != vm.session.task.expected,
      );
      await vm.answer(wrong);
      final schedule = LearnReviewSchedule.fromJson(
        app.progress.learnReviews[lesson.id]!,
      );
      expect(schedule.runs, 2);
      expect(schedule.dueAt, now.add(const Duration(days: 1)));
      expect(app.progress.xp, 100);
      expect(app.progress.lessonScores, {'first-strategy': 0.8});
      vm.dispose();
      vm = LearnReviewViewModel(appState: app, lesson: lesson);
      expect(vm.session.attempt, 2);
      expect(vm.session.complete, isFalse);
      vm.dispose();
      app.dispose();
    },
  );
  testWidgets(
    'failed review save leaves answer/schedule untouched and repeat write is idempotent',
    (tester) async {
      final lesson = catalogs['en']!.strategyLessons.first;
      final repository = _Repository(
        const ProgressSnapshot(lessonScores: {'first-strategy': 0.8}, xp: 100),
      );
      final app = AppState(
        catalog: catalogs['en']!,
        progress: repository.snapshot,
        progressRepository: repository,
        clock: () => now,
      );
      final vm = LearnReviewViewModel(appState: app, lesson: lesson);
      repository.fail = true;
      await vm.answer(vm.session.task.expected);
      expect(vm.saveFailed, isTrue);
      expect(vm.session.answer, isNull);
      expect(app.progress.learnReviews, isEmpty);
      repository.fail = false;
      await vm.answer(vm.session.task.expected);
      final snapshot = app.progress.toJson();
      await app.saveLearnReview(vm.session);
      expect(app.progress.toJson(), snapshot);
      expect(vm.session.complete, isTrue);
      expect(app.progress.xp, 100);
      vm.dispose();
      app.dispose();
    },
  );
}

class _Repository implements ProgressRepository {
  _Repository(this.snapshot);
  ProgressSnapshot snapshot;
  bool fail = false;
  @override
  Future<void> clear() async => snapshot = const ProgressSnapshot();
  @override
  Future<ProgressSnapshot> load() async => ProgressSnapshot.fromJson(
    jsonDecode(jsonEncode(snapshot.toJson())) as Map<String, Object?>,
  );
  @override
  Future<void> save(ProgressSnapshot value) async {
    if (fail) throw StateError('storage unavailable');
    snapshot = value;
  }
}
