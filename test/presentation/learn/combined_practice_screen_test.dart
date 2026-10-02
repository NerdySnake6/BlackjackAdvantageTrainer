import 'dart:convert';

import 'package:blackjack_advantage_trainer/app/router.dart';
import 'package:blackjack_advantage_trainer/app/theme.dart';
import 'package:blackjack_advantage_trainer/core/persistence/progress_repository.dart';
import 'package:blackjack_advantage_trainer/data/content_repository.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:blackjack_advantage_trainer/l10n/app_localizations.dart';
import 'package:blackjack_advantage_trainer/viewmodels/app_state.dart';
import 'package:blackjack_advantage_trainer/viewmodels/combined_practice_view_model.dart';
import 'package:blackjack_advantage_trainer/presentation/learn/mastery_check_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
      '$locale joint practice at 320px/200%, failed save, resume and immutable first answers',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 568);
        final repository = _Repository(
          const ProgressSnapshot(
            experienceLevel: ExperienceLevel.experienced,
            hasSeenTelemetryConsent: true,
            xp: 150,
            streakDays: 2,
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
            clock: () => DateTime(2026, 10, 2),
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
        await tapPilot(tester, find.byKey(const ValueKey('study-combined')));
        CombinedPracticeViewModel vm() => tester
            .element(find.byType(Scaffold).last)
            .read<CombinedPracticeViewModel>();
        await tapPilot(tester, find.byKey(const ValueKey('combined-begin')));
        for (var i = 0; i < 10; i++) {
          while (vm().session.revealed < vm().session.cards.length) {
            await tapPilot(
              tester,
              find.byKey(const ValueKey('combined-reveal')),
            );
            if (i == 0 && vm().session.revealed == 1) {
              final snapshot = vm().session.toJson();
              await mount(path: '/combined-practice');
              expect(vm().session.toJson(), snapshot);
            }
          }
          final s = vm().session;
          final value = i == 0
              ? s.task.availableActions
                    .firstWhere((a) => a.name != s.task.expected)
                    .name
              : s.task.expected;
          if (i == 0) {
            repository.fail = true;
            await tapPilot(
              tester,
              find.byKey(ValueKey('combined-action-$value')),
            );
            expect(vm().saveFailed, isTrue);
            expect(vm().session.decision, isNull);
            repository.fail = false;
          }
          await tapPilot(
            tester,
            find.byKey(ValueKey('combined-action-$value')),
          );
          if (i == 0) {
            final snapshot = vm().session.toJson();
            await mount(path: '/combined-practice');
            expect(vm().session.toJson(), snapshot);
          }
          final target = vm().session.expectedCount(i) + (i == 1 ? 1 : 0);
          while (vm().session.input != target) {
            await tapPilot(
              tester,
              find.byKey(
                ValueKey(
                  vm().session.input < target
                      ? 'combined-plus'
                      : 'combined-minus',
                ),
              ),
            );
          }
          await tapPilot(tester, find.byKey(const ValueKey('combined-answer')));
          if (i < 9) {
            expect(vm().session.feedback, isTrue);
            final snapshot = vm().session.toJson();
            if (i == 1) {
              await mount(path: '/combined-practice');
              expect(vm().session.toJson(), snapshot);
            }
            await tapPilot(tester, find.byKey(const ValueKey('combined-next')));
          }
        }
        expect(vm().session.strategyCorrect, 9);
        expect(vm().session.countCorrect, 9);
        expect(vm().session.bothCorrect, 8);
        expect(app!.progress.xp, 150);
        expect(app!.progress.streakDays, 2);
        expect(app!.progress.masteryChecks, isEmpty);
        expect(app!.progress.lessonScores, isEmpty);
        expect(app!.progress.exerciseReviewStates, isEmpty);
        final saved = app!.progress.toJson();
        await app!.saveCombinedPractice(vm().session);
        expect(app!.progress.toJson(), saved);
        await mount(path: '/combined-practice');
        expect(vm().session.complete, isTrue);
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('combined-result')),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.byKey(const ValueKey('combined-result')), findsOneWidget);
        await tapPilot(tester, find.byKey(const ValueKey('combined-repeat')));
        expect(vm().session.attempt, 2);
        expect(vm().session.started, isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final locale in ['en', 'ru']) {
    testWidgets(
      '$locale explicit checkpoint preserves old bank and result key',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 568);
        final repository = _Repository(
          const ProgressSnapshot(
            experienceLevel: ExperienceLevel.experienced,
            hasSeenTelemetryConsent: true,
            lessonScores: {'mixed-basic-strategy': 0.8},
          ),
        );
        final app = AppState(
          catalog: catalogs[locale]!,
          progress: repository.snapshot,
          progressRepository: repository,
        );
        final router = createRouter(appState: app);
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox());
          router.dispose();
          app.dispose();
          tester.view.reset();
        });
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: app,
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
        await tapPilot(
          tester,
          find.byKey(const ValueKey('basic-strategy-checkpoint')),
        );
        expect(find.byType(MasteryCheckScreen), findsOneWidget);
        expect(app.progress.lessonScores, {'mixed-basic-strategy': 0.8});
        expect(app.progress.masteryChecks, isEmpty);
        router.go('/lesson/basic-strategy-checkpoint');
        await tester.pumpAndSettle();
        expect(find.byType(MasteryCheckScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'active time excludes background and feedback; unfinished prior week resumes; corrupt restart is isolated',
    (tester) async {
      var now = DateTime(2026, 10, 2);
      final repository = _Repository(const ProgressSnapshot(xp: 100));
      final app = AppState(
        catalog: catalogs['en']!,
        progress: repository.snapshot,
        progressRepository: repository,
        clock: () => now,
      );
      final watch = _Watch();
      var vm = CombinedPracticeViewModel(app, stopwatch: watch);
      await vm.restart(timed: true);
      await vm.begin();
      watch.advance(1000);
      await vm.pause();
      expect(vm.session.elapsedMs, 1000);
      watch.advance(90000);
      vm.resume();
      watch.advance(2000);
      await vm.reveal();
      expect(vm.session.elapsedMs, 3000);
      vm.dispose();
      now = DateTime(2026, 10, 5);
      vm = CombinedPracticeViewModel(app, stopwatch: watch);
      expect(vm.session.week, '2026-09-28');
      final old = vm.session.toJson();
      repository.fail = true;
      await vm.reveal();
      expect(vm.session.toJson(), old);
      repository.fail = false;
      vm.dispose();
      app.dispose();
      final broken = AppState(
        catalog: catalogs['en']!,
        progress: const ProgressSnapshot(
          xp: 100,
          combinedPracticeSessions: {
            '2026-10-05': {'signature': 'bad'},
          },
        ),
        progressRepository: repository,
        clock: () => now,
      );
      vm = CombinedPracticeViewModel(broken);
      expect(vm.incompatible, isTrue);
      await vm.restart();
      expect(vm.incompatible, isFalse);
      expect(broken.progress.xp, 100);
      vm.dispose();
      broken.dispose();
    },
  );
}

class _Watch implements Stopwatch {
  int _elapsed = 0;
  bool _running = false;
  void advance(int ms) {
    if (_running) _elapsed += ms;
  }

  @override
  int get elapsedMilliseconds => _elapsed;
  @override
  void start() {
    _running = true;
  }

  @override
  void stop() {
    _running = false;
  }

  @override
  void reset() {
    _elapsed = 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Repository implements ProgressRepository {
  _Repository(this.snapshot);
  ProgressSnapshot snapshot;
  bool fail = false;
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
    if (fail) throw StateError('storage unavailable');
    snapshot = value;
  }
}
