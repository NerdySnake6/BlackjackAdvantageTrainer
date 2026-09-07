import 'package:blackjack_advantage_trainer/data/content_repository.dart';
import 'package:blackjack_advantage_trainer/core/persistence/progress_repository.dart';
import 'package:blackjack_advantage_trainer/domain/learning/decision_lesson.dart';
import 'package:blackjack_advantage_trainer/domain/learning/lesson_performance.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:blackjack_advantage_trainer/l10n/app_localizations.dart';
import 'package:blackjack_advantage_trainer/presentation/learn/pilot_performance_summary.dart';
import 'package:blackjack_advantage_trainer/viewmodels/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CourseCatalog catalog;
  setUpAll(() async => catalog = await ContentRepository().loadCatalog());

  for (final locale in ['en', 'ru']) {
    for (final before in [null, 8, 10]) {
      testWidgets(
        '$locale: practice comparison before=$before is honest at 320px',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(320, 568));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final lesson = catalog.pilotLessons.first;
          final session = DecisionLessonSession(lesson, attempt: 2)..begin();
          for (var i = 0; i < lesson.scenarios.length; i++) {
            final expected = session.current.expected;
            session.answer(
              i == 2
                  ? expected == 'hit'
                        ? 'stand'
                        : 'hit'
                  : expected,
            );
            if (i == 2) session.answer(expected);
            session.next();
          }
          session.recordReward(90);
          final app = AppState(
            catalog: catalog,
            progress: ProgressSnapshot(
              lessonScores: {lesson.id: 1},
              pilotSessions: {lesson.id: session.toJson()},
              previousPilotResults: {
                if (before != null)
                  lesson.id: {
                    ...LessonPerformance.fromSession(session).toJson(),
                    'attempt': 1,
                    'correct': before,
                    'unassisted': before - 1,
                  },
              },
            ),
            progressRepository: _Repository(),
          );
          await tester.pumpWidget(
            ChangeNotifierProvider.value(
              value: app,
              child: MaterialApp(
                locale: Locale(locale),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: MediaQuery(
                  data: const MediaQueryData(
                    textScaler: TextScaler.linear(1.5),
                  ),
                  child: Scaffold(
                    body: SingleChildScrollView(
                      child: PilotPerformanceSummary(lessonId: lesson.id),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final strings = AppLocalizations.of(
            tester.element(find.byType(PilotPerformanceSummary)),
          );
          expect(
            find.text(
              before == null
                  ? strings.pilotPracticeBaseline(9, 9)
                  : strings.pilotPracticeComparison(before, 9, before - 1, 9),
            ),
            findsOneWidget,
          );
          expect(
            find.text(strings.pilotPracticeComparisonNote),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          app.dispose();
        },
      );
    }
  }
}

class _Repository implements ProgressRepository {
  @override
  Future<void> clear() async {}
  @override
  Future<ProgressSnapshot> load() async => const ProgressSnapshot();
  @override
  Future<void> save(ProgressSnapshot snapshot) async {}
}
