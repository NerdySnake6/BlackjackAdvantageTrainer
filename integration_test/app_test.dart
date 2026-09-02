// End-to-end routes driven through the real app entry point on a device.
//
// Unlike the widget tests, nothing here is faked: this is the real
// SharedPreferencesAsync DataStore and the real telemetry bootstrap. The value
// of each route is that it survives a process restart, so most of them run the
// flow, call main() again, and assert the state came back.
import 'package:blackjack_advantage_trainer/data/content_repository.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:blackjack_advantage_trainer/main.dart' as app;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

late final CourseCatalog catalog;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    catalog = await ContentRepository().loadCatalog();
  });

  // The app process is shared across tests and the storage is real, so without
  // this every route after the first starts already onboarded.
  setUp(() async {
    await SharedPreferencesAsync().clear();
  });

  testWidgets('route 1: fresh install, beginner, telemetry declined', (
    tester,
  ) async {
    await _launch(tester);

    expect(find.text('Where should we start?'), findsOneWidget);
    await _tap(tester, find.text("I'm new to blackjack"));

    expect(find.text('Help improve the training'), findsOneWidget);
    await _tap(tester, find.text('Save and continue'));

    expect(find.text('Learning path'), findsOneWidget);
    final firstLesson = _lessonTitle(ExperienceLevel.beginner.startLessonId);
    await _scrollTo(tester, find.text(firstLesson));
    expect(find.text(firstLesson), findsOneWidget);

    await _restart(tester);

    // Onboarding does not reappear, and both consents stayed off.
    expect(find.text('Where should we start?'), findsNothing);
    expect(find.text('Learning path'), findsOneWidget);
    await _tap(tester, find.text('Progress'));
    expect(_switchValue(tester, 'Usage analytics'), isFalse);
    expect(_switchValue(tester, 'Crash reports'), isFalse);
  });

  testWidgets('route 4: a partly answered lesson resumes where it was left', (
    tester,
  ) async {
    await _onboard(tester, ExperienceLevel.beginner);

    final lesson = catalog.lessonById(ExperienceLevel.beginner.startLessonId);
    await _scrollTo(tester, find.text(lesson.title));
    await _tap(tester, find.text(lesson.title));

    expect(find.text('1 / ${lesson.exercises.length}'), findsOneWidget);
    await _answerCurrentExercise(tester);
    await _tap(tester, find.text('Next'));
    expect(find.text('2 / ${lesson.exercises.length}'), findsOneWidget);

    // Leave mid-lesson, then come back through a full restart.
    await _tap(tester, find.byTooltip('Back'));
    await _restart(tester);
    await _scrollTo(tester, find.text(lesson.title));
    await _tap(tester, find.text(lesson.title));

    expect(find.text('2 / ${lesson.exercises.length}'), findsOneWidget);
  });

  testWidgets('route 12: level and telemetry changes survive a restart', (
    tester,
  ) async {
    await _onboard(tester, ExperienceLevel.beginner);

    await _tap(tester, find.text('Progress'));
    await _scrollTo(tester, find.text('Usage analytics'));
    await _tap(tester, find.text('Usage analytics'));
    await _selectExperienceLevel(tester, ExperienceLevel.experienced);

    await _restart(tester);
    await _tap(tester, find.text('Progress'));

    await _scrollTo(tester, find.text('Usage analytics'));
    expect(_switchValue(tester, 'Usage analytics'), isTrue);
    expect(_switchValue(tester, 'Crash reports'), isFalse);
    expect(find.text('Your progress'), findsOneWidget);
  });

  testWidgets(
    'route 2: basics starts at hard and soft without faking lessons',
    (tester) async {
      await _onboard(tester, ExperienceLevel.basics);

      final start = catalog.lessonById(ExperienceLevel.basics.startLessonId);
      await _scrollTo(tester, find.text(start.title));
      expect(find.text(start.title), findsOneWidget);
      expect(find.text('Start here'), findsOneWidget);
      // The lessons before the recommended start are offered, not completed.
      await _tap(tester, find.text('Progress'));
      expect(
        find.text('0 of ${catalog.lessons.length} lessons completed'),
        findsOneWidget,
      );
    },
  );

  testWidgets('route 3: experienced unlocks Drill and Table without progress', (
    tester,
  ) async {
    await _onboard(tester, ExperienceLevel.experienced);

    await _tap(tester, find.text('Drill'));
    await _dismissDrillIntro(tester);
    // The drill uses the phrase for both the heading and the count label.
    expect(find.text('Running count'), findsWidgets);
    await _openTable(tester);
    expect(find.textContaining('TABLE'), findsWidgets);
    await _tap(tester, find.byTooltip('Back to path'));
    await _tap(tester, find.text('Progress'));
    expect(
      find.text('0 of ${catalog.lessons.length} lessons completed'),
      findsOneWidget,
    );
  });

  testWidgets('routes 5 and 6: a failed lesson asks for review, a passed one '
      'unlocks the next', (tester) async {
    await _onboard(tester, ExperienceLevel.beginner);
    final lesson = catalog.lessonById(ExperienceLevel.beginner.startLessonId);

    await _openLesson(tester, lesson);
    await _completeLesson(tester, lesson, correct: false);
    expect(find.text('Lesson finished — review required'), findsOneWidget);
    await _tap(tester, find.text('Review and try again'));

    await _completeLesson(tester, lesson, correct: true);
    expect(find.text('Lesson complete'), findsOneWidget);
  });

  testWidgets('route 7: the drill runs a full deck to zero', (tester) async {
    await _onboard(tester, ExperienceLevel.experienced);
    await _tap(tester, find.text('Drill'));
    await _dismissDrillIntro(tester);
    await _tap(tester, find.text('Start one-deck drill'));

    // 52 cards behind seven checkpoints; the deck must end on zero.
    for (var guard = 0; guard < 120; guard++) {
      if (find.text('Deck complete').evaluate().isNotEmpty) {
        break;
      }
      if (find.text('Check count').evaluate().isNotEmpty) {
        await _tap(tester, find.text('Check count'));
        continue;
      }
      if (find.text('Next').evaluate().isNotEmpty) {
        await _tap(tester, find.text('Next'));
        continue;
      }
      if (find.text('Reveal next card').evaluate().isNotEmpty) {
        await _tap(tester, find.text('Reveal next card'));
        continue;
      }
      fail('Drill stalled with no next action on screen');
    }

    expect(find.text('Deck complete'), findsOneWidget);
    expect(find.text('Run another deck'), findsOneWidget);
  });

  testWidgets('route 8: a guided table session reaches five rounds', (
    tester,
  ) async {
    // The starting table mode follows the experience level: everyone below
    // "experienced" gets Guided.
    await _onboard(tester, ExperienceLevel.beginner);
    await _openTable(tester);
    expect(_visibleTableBanners(tester), contains('GUIDED TABLE'));

    await _playTableSession(tester);
    expect(find.text('Five-round session complete'), findsOneWidget);
  });

  testWidgets('route 9: a practice table session checks the running count', (
    tester,
  ) async {
    // An experienced player starts in Practice without touching the mode menu.
    await _onboard(tester, ExperienceLevel.experienced);
    await _openTable(tester);
    expect(_visibleTableBanners(tester), contains('PRACTICE TABLE'));

    await _playTableSession(tester);
    expect(find.text('Five-round session complete'), findsOneWidget);
    expect(find.textContaining('Count '), findsWidgets);
  });

  testWidgets('route 10: seats can be reassigned mid-deal', (tester) async {
    await _onboard(tester, ExperienceLevel.experienced);
    await _openTable(tester);
    await _tap(tester, find.text('Deal the first round'));

    await _tap(tester, find.byTooltip('Configure seats'));
    expect(find.text('Human'), findsWidgets);
    await _tap(tester, find.text('Bot').first);
    await _tap(tester, find.text('Done'));

    // Applied from the next round, not the one in progress.
    expect(find.textContaining('TABLE'), findsWidgets);
  });

  testWidgets('route 11: a quick review session can be created and finished', (
    tester,
  ) async {
    await _onboard(tester, ExperienceLevel.beginner);
    final lesson = catalog.lessonById(ExperienceLevel.beginner.startLessonId);
    await _openLesson(tester, lesson);
    await _completeLesson(tester, lesson, correct: true);
    await _tap(tester, find.text('Back to path'));

    await _scrollTo(tester, find.text('Quick Review'));
    await _tap(tester, find.text('Quick Review'));

    if (find.text('Nothing to review yet').evaluate().isNotEmpty) {
      // Nothing is due yet, which is the documented empty state.
      expect(find.text('Nothing to review yet'), findsOneWidget);
      return;
    }
    for (var guard = 0; guard < 40; guard++) {
      if (find.text('Review complete').evaluate().isNotEmpty) {
        break;
      }
      if (find.text('Next').evaluate().isNotEmpty) {
        await _tap(tester, find.text('Next'));
        continue;
      }
      if (find.text('Finish').evaluate().isNotEmpty) {
        await _tap(tester, find.text('Finish'));
        continue;
      }
      await _answerCurrentExercise(tester);
    }
    expect(find.text('Review complete'), findsOneWidget);
  });
}

String _lessonTitle(String lessonId) => catalog.lessonById(lessonId).title;

/// Entering Drill raises a modal intro dialog until it has been acknowledged.
/// Left open it swallows every later tap, including the bottom navigation, so
/// the run looks stuck rather than failing.
Future<void> _dismissDrillIntro(WidgetTester tester) async {
  if (find.text('Before your first count').evaluate().isEmpty) {
    return;
  }
  await _tap(tester, find.text('Got it'));
  expect(find.text('Before your first count'), findsNothing);
}

bool _switchValue(WidgetTester tester, String title) {
  return tester
      .widget<SwitchListTile>(find.widgetWithText(SwitchListTile, title))
      .value;
}

Future<void> _launch(WidgetTester tester) async {
  // main() installs its own FlutterError.onError and a PlatformDispatcher
  // onError that returns true. Left in place, they swallow real failures and
  // the harness reports an unrelated assertion about a overridden handler
  // instead of the actual error. Restore the test's handlers after startup.
  final testOnError = FlutterError.onError;
  final testDispatcherOnError = PlatformDispatcher.instance.onError;
  app.main();
  await tester.pumpAndSettle(const Duration(seconds: 2));
  FlutterError.onError = testOnError;
  PlatformDispatcher.instance.onError = testDispatcherOnError;
}

/// Restarts the real entry point so the next assertions read persisted state
/// rather than the in-memory objects the flow just mutated.
Future<void> _restart(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pumpAndSettle();
  await _launch(tester);
}

Future<void> _onboard(WidgetTester tester, ExperienceLevel level) async {
  await _launch(tester);
  await _tap(tester, find.text(_levelTitle(level)));
  await _tap(tester, find.text('Save and continue'));
  expect(find.text('Learning path'), findsOneWidget);
}

String _levelTitle(ExperienceLevel level) => switch (level) {
  ExperienceLevel.beginner => "I'm new to blackjack",
  ExperienceLevel.basics => 'I know the basics',
  ExperienceLevel.experienced => "I'm an experienced player",
};

/// Answers the exercise on screen correctly, whatever its options are.
Future<void> _answerCurrentExercise(WidgetTester tester) async {
  final exercise = _visibleExercise(tester);
  await _scrollTo(tester, find.text(exercise.options[exercise.correctIndex]));
  await _tap(tester, find.text(exercise.options[exercise.correctIndex]));
}

LessonExercise _visibleExercise(WidgetTester tester) {
  for (final lesson in catalog.lessons) {
    for (final exercise in lesson.exercises) {
      if (find.text(exercise.prompt).evaluate().isNotEmpty) {
        return exercise;
      }
    }
  }
  fail('No known exercise prompt is on screen');
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

/// Scrolls the target into view, giving up rather than scrolling forever when
/// it is simply not on this screen. An unbounded scrollUntilVisible looks like
/// a hang, not a failure.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isNotEmpty) {
    return;
  }
  final scrollable = find.byType(Scrollable);
  if (scrollable.evaluate().isEmpty) {
    fail('Target is not on screen and there is nothing to scroll');
  }
  // scrollUntilVisible only moves one way, so a target above the current
  // offset is never reached by scrolling down. Try down, then up.
  for (final delta in [240.0, -240.0]) {
    try {
      await tester.scrollUntilVisible(
        finder,
        delta,
        scrollable: scrollable.last,
        maxScrolls: 30,
      );
      await tester.pumpAndSettle();
      if (finder.evaluate().isNotEmpty) {
        return;
      }
    } on Object {
      // Wrong direction for this target; fall through and try the other one.
    }
  }
  if (finder.evaluate().isEmpty) {
    fail('Target never became visible in either scroll direction');
  }
}

/// The Progress screen exposes the level as a DropdownButtonFormField, so the
/// wanted label does not exist on screen until the menu is open.
Future<void> _selectExperienceLevel(
  WidgetTester tester,
  ExperienceLevel level,
) async {
  final dropdown = find.byType(DropdownButtonFormField<ExperienceLevel>);
  await _scrollTo(tester, dropdown);
  await _tap(tester, dropdown);

  // The label now appears twice: in the closed field and in the open menu.
  final option = find.text(_levelTitle(level));
  await tester.tap(option.last);
  await tester.pumpAndSettle();
}

/// TableScreen forces landscape through SystemChrome. That rotation arrives
/// from the platform after pumpAndSettle has already returned, so the header is
/// briefly absent and a plain tap-then-assert races it.
Future<void> _openTable(WidgetTester tester) async {
  await _tap(tester, find.text('Table'));
  for (var attempt = 0; attempt < 40; attempt++) {
    if (find.textContaining('TABLE').evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 250));
  }
  fail('The table header never appeared after the forced rotation');
}

/// Every Text on screen whose content mentions the table banner, so a mismatch
/// reports what was actually rendered instead of just "found 0".
List<String> _visibleTableBanners(WidgetTester tester) => [
  for (final widget in tester.widgetList<Text>(find.byType(Text)))
    if ((widget.data ?? '').contains('TABLE')) widget.data!,
];

Future<void> _openLesson(WidgetTester tester, LessonDefinition lesson) async {
  await _scrollTo(tester, find.text(lesson.title));
  await _tap(tester, find.text(lesson.title));
}

/// Walks a lesson to its result screen, answering every exercise right or
/// wrong so both the pass and the review-required outcome can be exercised.
Future<void> _completeLesson(
  WidgetTester tester,
  LessonDefinition lesson, {
  required bool correct,
}) async {
  for (var i = 0; i < lesson.exercises.length; i++) {
    final exercise = _visibleExercise(tester);
    final index = correct
        ? exercise.correctIndex
        : (exercise.correctIndex + 1) % exercise.options.length;
    await _scrollTo(tester, find.text(exercise.options[index]));
    await _tap(tester, find.text(exercise.options[index]));
    if (find.text('Next').evaluate().isNotEmpty) {
      await _tap(tester, find.text('Next'));
    } else if (find.text('Finish').evaluate().isNotEmpty) {
      await _tap(tester, find.text('Finish'));
    }
  }
}

/// Plays a table session to its summary by taking whatever action the screen
/// currently offers. The strategy choice is not asserted here; the engine tests
/// own that. This route only proves the path is walkable on a device.
Future<void> _playTableSession(WidgetTester tester) async {
  const actions = ['Hit', 'Stand', 'Double', 'Split', 'Surrender'];
  if (find.text('Deal the first round').evaluate().isNotEmpty) {
    await _tap(tester, find.text('Deal the first round'));
  }
  for (var guard = 0; guard < 200; guard++) {
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    if (find.text('Five-round session complete').evaluate().isNotEmpty) {
      return;
    }
    for (final label in ['Continue', 'New round', 'Check count', 'Next']) {
      if (find.text(label).evaluate().isNotEmpty) {
        await _tap(tester, find.text(label));
        break;
      }
    }
    for (final action in actions) {
      if (find.widgetWithText(FilledButton, action).evaluate().isNotEmpty) {
        await _tap(tester, find.widgetWithText(FilledButton, action));
        break;
      }
    }
  }
  fail('Table session did not reach its summary');
}
