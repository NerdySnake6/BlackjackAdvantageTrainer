import 'dart:convert';

import 'package:blackjack_advantage_trainer/core/persistence/progress_repository.dart';
import 'package:blackjack_advantage_trainer/data/content_repository.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/game_rules.dart';
import 'package:blackjack_advantage_trainer/domain/learning/decision_lesson.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:blackjack_advantage_trainer/l10n/app_localizations.dart';
import 'package:blackjack_advantage_trainer/presentation/learn/adaptive_practice_card.dart';
import 'package:blackjack_advantage_trainer/presentation/learn/pilot_lesson_screen.dart';
import 'package:blackjack_advantage_trainer/presentation/table/table_formatters.dart';
import 'package:blackjack_advantage_trainer/viewmodels/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../support/pilot_adaptation.dart';
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
    for (final lessonId in ['hard-12', 'soft-18', 'hi-lo-cancellation']) {
      for (final help in [true, false]) {
        testWidgets(
          '$locale $lessonId help=$help: extra practice resumes without scoring',
          (tester) async {
            await tester.binding.setSurfaceSize(const Size(320, 568));
            addTearDown(() => tester.binding.setSurfaceSize(null));
            final catalog = catalogs[locale]!;
            final lesson = catalog.pilotLessons.firstWhere(
              (l) => l.id == lessonId,
            );
            final baseSession = boundary(
              lesson,
              errors: help
                  ? lessonId == 'soft-18'
                        ? {2, 5}
                        : lessonId == 'hard-12'
                        ? {3, 4}
                        : {2, 3}
                  : {},
            );
            final session = DecisionLessonSession.restore(lesson, {
              ...baseSession.toJson(),
              'adaptiveSeed': help ? 0 : 37,
            });
            final repository = _Repository(
              ProgressSnapshot(
                xp: 500,
                pilotSessions: {lessonId: session.toJson()},
              ),
            );
            var app = AppState(
              catalog: catalog,
              progress: await repository.load(),
              progressRepository: repository,
            );
            Future<void> mount() async {
              await tester.pumpWidget(
                ChangeNotifierProvider.value(
                  value: app,
                  child: MaterialApp(
                    locale: Locale(locale),
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    supportedLocales: AppLocalizations.supportedLocales,
                    builder: (context, child) => MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(textScaler: const TextScaler.linear(2)),
                      child: child!,
                    ),
                    home: PilotLessonScreen(lessonId: lessonId),
                  ),
                ),
              );
              await tester.pumpAndSettle();
            }

            await mount();
            final strings = AppLocalizations.of(
              tester.element(find.byType(PilotLessonScreen)),
            );
            final panel = find.byType(AdaptivePracticeCard);
            await tester.scrollUntilVisible(
              panel,
              180,
              scrollable: find.byType(Scrollable).first,
            );
            final task = session.adaptation!.example;
            if (task.isCounting) {
              await tapPilot(
                tester,
                find.descendant(
                  of: panel,
                  matching: find.byTooltip(strings.pilotIncrease),
                ),
              );
              repository.fail = true;
              await tapPilot(
                tester,
                find.byKey(const ValueKey('adaptive-answer')),
              );
              expect(
                find.byKey(const ValueKey('pilot-save-error')),
                findsOneWidget,
              );
              expect(
                tester.getSize(find.byType(ListView)).height,
                greaterThan(250),
                reason:
                    'The error banner must leave enough room to retry at 200% text',
              );
              expect(
                app.progress.pilotSessions[lessonId]!['adaptiveAnswer'],
                isNull,
              );
              repository.fail = false;
              await tapPilot(
                tester,
                find.byKey(const ValueKey('adaptive-answer')),
              );
            } else {
              await tapPilot(
                tester,
                find.descendant(
                  of: panel,
                  matching: find.widgetWithText(
                    FilledButton,
                    actionLabel(
                      strings,
                      PlayerAction.values.byName(task.expected),
                    ),
                  ),
                ),
              );
            }
            final saved = app.progress.pilotSessions[lessonId]!;
            expect(saved['adaptiveSeed'], help ? 0 : 37);
            expect(saved['answers'], session.toJson()['answers']);
            expect(
              saved['adaptiveAnswer'],
              task.isCounting ? '1' : task.expected,
            );
            expect(app.progress.xp, 500);
            await tester.pumpWidget(const SizedBox.shrink());
            app.dispose();
            app = AppState(
              catalog: catalog,
              progress: await repository.load(),
              progressRepository: repository,
            );
            await mount();
            await tapPilot(tester, find.byKey(const ValueKey('pilot-next')));
            expect(app.progress.pilotSessions[lessonId]!['index'], 7);
            expect(app.progress.xp, 500);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
            app.dispose();
          },
          timeout: const Timeout(Duration(seconds: 30)),
        );
      }
    }
  }
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
  Future<void> save(ProgressSnapshot snapshot) async {
    if (fail) throw StateError('Storage unavailable');
    this.snapshot = snapshot;
  }
}
