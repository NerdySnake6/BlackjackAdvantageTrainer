import 'dart:convert';

import 'package:blackjack_advantage_trainer/app/router.dart';
import 'package:blackjack_advantage_trainer/app/theme.dart';
import 'package:blackjack_advantage_trainer/core/persistence/progress_repository.dart';
import 'package:blackjack_advantage_trainer/data/content_repository.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/game_rules.dart';
import 'package:blackjack_advantage_trainer/domain/learning/mastery_check.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:blackjack_advantage_trainer/l10n/app_localizations.dart';
import 'package:blackjack_advantage_trainer/presentation/learn/mastery_check_screen.dart';
import 'package:blackjack_advantage_trainer/presentation/table/table_formatters.dart';
import 'package:blackjack_advantage_trainer/viewmodels/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    for (final id in ['hard-12', 'soft-18', 'hi-lo-cancellation']) {
      testWidgets(
        '$locale $id: new check works at 320px, resumes and records first answers',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(320, 568));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final repository = _Repository(
            ProgressSnapshot(
              languageCode: locale,
              lessonScores: {id: 0.8},
              xp: 150,
              experienceLevel: ExperienceLevel.beginner,
              hasSeenTelemetryConsent: true,
            ),
          );
          var app = AppState(
            catalog: catalogs[locale]!,
            progress: await repository.load(),
            progressRepository: repository,
          );
          var router = createRouter(appState: app)..go('/checkpoint/$id');
          Future<void> mount() async {
            await tester.pumpWidget(
              ChangeNotifierProvider.value(
                value: app,
                child: MaterialApp.router(
                  routerConfig: router,
                  theme: buildAppTheme(),
                  locale: Locale(locale),
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: const TextScaler.linear(1.5)),
                    child: child!,
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
          }

          await mount();
          final strings = AppLocalizations.of(
            tester.element(find.byType(MasteryCheckScreen)),
          );
          await tapPilot(tester, find.byKey(const ValueKey('check-begin')));
          final tasks = MasteryCheckBank.tasks(id, 0);
          for (var i = 0; i < 10; i++) {
            expect(find.text('${i + 1}/10'), findsOneWidget);
            expect(find.byKey(const ValueKey('pilot-hint')), findsNothing);
            expect(find.byKey(const ValueKey('check-result')), findsNothing);
            final task = tasks[i];
            if (task.isCounting) {
              for (final _ in task.cards) {
                await tapPilot(tester, find.text(strings.nextCard));
              }
              final count = i == 0 ? 0 : int.parse(task.expected);
              for (var step = 0; step < count.abs(); step++) {
                await tapPilot(
                  tester,
                  find.byTooltip(
                    count > 0 ? strings.pilotIncrease : strings.pilotDecrease,
                  ),
                );
              }
              await tapPilot(
                tester,
                find.byKey(const ValueKey('check-answer')),
              );
            } else {
              final answer = i == 0
                  ? task.expected == 'hit'
                        ? 'stand'
                        : 'hit'
                  : task.expected;
              await tapPilot(
                tester,
                find.widgetWithText(
                  FilledButton,
                  actionLabel(strings, PlayerAction.values.byName(answer)),
                ),
              );
            }
            if (i == 3) {
              await tester.pumpWidget(const SizedBox.shrink());
              router.dispose();
              app.dispose();
              app = AppState(
                catalog: catalogs[locale]!,
                progress: await repository.load(),
                progressRepository: repository,
              );
              router = createRouter(appState: app)..go('/checkpoint/$id');
              await mount();
            }
          }
          expect(find.text(strings.pilotMasteryStatus(90)), findsOneWidget);
          expect(find.text(strings.pilotMastered), findsOneWidget);
          expect(app.isLessonMastered(id), isTrue);
          expect(app.progress.xp, 150);
          expect(app.progress.lessonScores[id], 0.8);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          router.dispose();
          app.dispose();
        },
        timeout: const Timeout(Duration(seconds: 30)),
      );
    }
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
