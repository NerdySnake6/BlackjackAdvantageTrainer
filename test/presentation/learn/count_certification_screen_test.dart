import 'dart:convert';

import 'package:blackjack_advantage_trainer/app/router.dart';
import 'package:blackjack_advantage_trainer/app/theme.dart';
import 'package:blackjack_advantage_trainer/core/persistence/progress_repository.dart';
import 'package:blackjack_advantage_trainer/data/content_repository.dart';
import 'package:blackjack_advantage_trainer/domain/learning/count_certification.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:blackjack_advantage_trainer/l10n/app_localizations.dart';
import 'package:blackjack_advantage_trainer/viewmodels/app_state.dart';
import 'package:blackjack_advantage_trainer/presentation/learn/count_certification_screen.dart';
import 'package:blackjack_advantage_trainer/viewmodels/count_certification_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/iteration26_count_lessons_test.dart' show tags;
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
      '$locale: full decks work at 320px/200%, resume and award no XP',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 568);
        final repository = _Repository(
          ProgressSnapshot(
            languageCode: locale,
            hasSeenTelemetryConsent: true,
            experienceLevel: ExperienceLevel.experienced,
            xp: 150,
            lessonScores: const {'running-count-speed': 0.8},
            masteryChecks: {
              'running-count-speed': CountCertificationSession(
                seed: 27,
              ).toJson(),
            },
          ),
        );
        AppState? app;
        GoRouter? router;
        Future<void> mount() async {
          await tester.pumpWidget(const SizedBox());
          router?.dispose();
          app?.dispose();
          app = AppState(
            catalog: catalogs[locale]!,
            progress: await repository.load(),
            progressRepository: repository,
          );
          router = createRouter(appState: app!)..go('/count-certification');
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
        final strings = AppLocalizations.of(
          tester.element(find.byType(CountCertificationScreen)),
        );
        for (var level = 0; level < 3; level++) {
          await tapPilot(
            tester,
            find.byKey(const ValueKey('count-cert-begin')),
          );
          for (var card = 0; card < 52; card++) {
            await tapPilot(
              tester,
              find.byKey(const ValueKey('count-cert-reveal')),
            );
            var saved = CountCertificationSession.restore(
              repository.snapshot.masteryChecks['running-count-speed']!,
            );
            if (card == 8 && level == 0) {
              final before = saved.toJson();
              await mount();
              saved = CountCertificationSession.restore(
                repository.snapshot.masteryChecks['running-count-speed']!,
              );
              expect(saved.revealed, before['revealed']);
              expect(saved.orders, before['orders']);
            }
            if (saved.needsAnswer) {
              final expected = saved.cards
                  .take(card + 1)
                  .fold<int>(0, (sum, c) => sum + tags[c.rank.label]!);
              for (var step = 0; step < expected.abs(); step++) {
                await tapPilot(
                  tester,
                  find.byKey(
                    ValueKey(
                      expected > 0 ? 'count-cert-plus' : 'count-cert-minus',
                    ),
                  ),
                );
              }
              await tapPilot(
                tester,
                find.byKey(const ValueKey('count-cert-answer')),
              );
            }
            expect(
              find.byKey(const ValueKey('count-cert-failed')),
              findsNothing,
            );
          }
        }
        expect(find.text(strings.countCertificationPassed), findsOneWidget);
        expect(app!.isLessonMastered('running-count-speed'), isTrue);
        expect(app!.progress.xp, 150);
        expect(app!.progress.lessonScores['running-count-speed'], 0.8);
        expect(tester.takeException(), isNull);
      },
      timeout: const Timeout(Duration(seconds: 90)),
    );
  }
  testWidgets(
    'storage failure keeps old evidence; background freezes active time',
    (tester) async {
      final repository = _Repository(
        ProgressSnapshot(
          languageCode: 'en',
          hasSeenTelemetryConsent: true,
          experienceLevel: ExperienceLevel.experienced,
          lessonScores: const {'running-count-speed': 0.8},
        ),
      );
      final app = AppState(
        catalog: catalogs['en']!,
        progress: repository.snapshot,
        progressRepository: repository,
      );
      final stopwatch = _Stopwatch();
      final vm = CountCertificationViewModel(app, stopwatch: stopwatch);
      await vm.begin();
      stopwatch.advance(1200);
      await vm.tick();
      expect(vm.session.elapsedMs, 1200);
      repository.fail = true;
      await vm.reveal();
      expect(vm.saveFailed, isTrue);
      expect(vm.session.revealed, 0);
      repository.fail = false;
      await vm.reveal();
      expect(vm.session.revealed, 1);
      vm.didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pump();
      final elapsed = vm.session.elapsedMs;
      stopwatch.advance(90000);
      await tester.pump(const Duration(seconds: 90));
      await vm.tick();
      expect(vm.session.elapsedMs, elapsed);
      expect(vm.session.failed, isFalse);
      vm.didChangeAppLifecycleState(AppLifecycleState.resumed);
      stopwatch.advance(500);
      await vm.pause();
      expect(vm.session.elapsedMs, elapsed + 500);
      expect(app.progress.xp, 0);
      vm.dispose();
      app.dispose();
    },
  );
  testWidgets(
    'invalid saved evidence stays isolated and can restart without reward',
    (tester) async {
      final repository = _Repository(
        ProgressSnapshot(
          lessonScores: const {'running-count-speed': 0.8},
          xp: 150,
          masteryChecks: const {
            'running-count-speed': {'version': 0},
          },
        ),
      );
      final app = AppState(
        catalog: catalogs['en']!,
        progress: repository.snapshot,
        progressRepository: repository,
      );
      final vm = CountCertificationViewModel(app);
      expect(vm.incompatible, isTrue);
      expect(app.isLessonMastered('running-count-speed'), isFalse);
      await vm.restart();
      expect(vm.incompatible, isFalse);
      expect(vm.session.attempt, 2);
      expect(vm.session.level, 0);
      expect(app.progress.xp, 150);
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

class _Stopwatch implements Stopwatch {
  int _milliseconds = 0;
  bool _running = false;
  void advance(int milliseconds) {
    if (_running) _milliseconds += milliseconds;
  }

  @override
  void start() => _running = true;
  @override
  void stop() => _running = false;
  @override
  void reset() => _milliseconds = 0;
  @override
  bool get isRunning => _running;
  @override
  int get elapsedMilliseconds => _milliseconds;
  @override
  int get elapsedMicroseconds => _milliseconds * 1000;
  @override
  int get elapsedTicks => _milliseconds;
  @override
  int get frequency => 1000;
  @override
  Duration get elapsed => Duration(milliseconds: _milliseconds);
}
