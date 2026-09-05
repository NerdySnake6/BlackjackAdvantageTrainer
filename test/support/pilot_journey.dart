import 'package:blackjack_advantage_trainer/domain/blackjack_engine/game_rules.dart';
import 'package:blackjack_advantage_trainer/domain/learning/pilot_lesson.dart';
import 'package:blackjack_advantage_trainer/l10n/app_localizations.dart';
import 'package:blackjack_advantage_trainer/presentation/drill/cancellation_scene.dart';
import 'package:blackjack_advantage_trainer/presentation/learn/decision_scene.dart';
import 'package:blackjack_advantage_trainer/presentation/learn/pilot_lesson_screen.dart';
import 'package:blackjack_advantage_trainer/presentation/table/table_formatters.dart';
import 'package:blackjack_advantage_trainer/viewmodels/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> tapPilot(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    final scrollable = find.byType(Scrollable).first;
    tester.state<ScrollableState>(scrollable).position.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(finder, 180, scrollable: scrollable);
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

/// Exercises only visible controls, including one corrected first-answer error.
Future<void> runPilotJourney(
  WidgetTester tester,
  AppState app,
  PilotLesson lesson, {
  Future<AppState> Function()? reloadApp,
}) async {
  await tapPilot(tester, find.byKey(ValueKey('pilot-${lesson.id}')));
  final strings = AppLocalizations.of(
    tester.element(find.byType(PilotLessonScreen)),
  );
  await tapPilot(tester, find.byKey(const ValueKey('pilot-begin')));
  for (var index = 0; index < 12; index++) {
    final task = lesson.scenarios[index];
    if (index == 3) {
      await tapPilot(tester, find.byKey(const ValueKey('pilot-hint')));
    }
    if (task.isCounting) {
      for (var card = 0; card < task.cards.length; card++) {
        await tapPilot(
          tester,
          find.widgetWithText(FilledButton, strings.nextCard),
        );
      }
      final scene = tester.widget<CancellationScene>(
        find.byType(CancellationScene),
      );
      expect(scene.showExplanation, index < 2 || index == 3);
      expect(scene.revealedCount, task.cards.length);
    } else {
      final scene = tester.widget<DecisionScene>(find.byType(DecisionScene));
      expect(
        scene.availableActions.contains(PlayerAction.doubleDown),
        task.cards.length == 2,
      );
    }

    Future<void> answer(String value) async {
      if (task.isCounting) {
        final saved = app.progress.pilotSessions[lesson.id]!;
        final entered = saved['countInput'] as int? ?? task.initialCount;
        final delta = int.parse(value) - entered;
        for (var step = 0; step < delta.abs(); step++) {
          await tapPilot(
            tester,
            find.byTooltip(
              delta > 0 ? strings.pilotIncrease : strings.pilotDecrease,
            ),
          );
        }
        await tapPilot(
          tester,
          find.byKey(const ValueKey('pilot-count-answer')),
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
      final wrong = task.isCounting
          ? (int.parse(task.expected) + 1).toString()
          : task.availableActions
                .firstWhere((action) => action.name != task.expected)
                .name;
      await answer(wrong);
      expect(
        (app.progress.pilotSessions[lesson.id]!['answers'] as List).last,
        wrong,
      );
      if (reloadApp != null) {
        final snapshot = app.progress.pilotSessions[lesson.id];
        app = await reloadApp();
        await tapPilot(tester, find.byKey(ValueKey('pilot-${lesson.id}')));
        expect(app.progress.pilotSessions[lesson.id], snapshot);
      }
      await answer(task.expected);
      expect(
        (app.progress.pilotSessions[lesson.id]!['answers'] as List).last,
        wrong,
      );
    } else {
      await answer(task.expected);
    }
    await tapPilot(tester, find.byKey(const ValueKey('pilot-next')));
  }
  expect(find.text(strings.lessonResult(9, 10)), findsOneWidget);
  expect(find.text(strings.pilotUnassisted(8)), findsOneWidget);
  expect(find.text(strings.pilotReward(140)), findsOneWidget);
  final xp = app.progress.xp;
  await tapPilot(tester, find.widgetWithText(FilledButton, strings.backToPath));
  await tapPilot(tester, find.byKey(ValueKey('pilot-${lesson.id}')));
  expect(find.text(strings.lessonResult(9, 10)), findsOneWidget);
  expect(app.progress.xp, xp);
  await tapPilot(tester, find.widgetWithText(FilledButton, strings.backToPath));
}
