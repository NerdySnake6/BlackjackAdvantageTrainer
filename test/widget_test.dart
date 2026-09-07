import 'package:blackjack_advantage_trainer/app/app.dart';
import 'package:blackjack_advantage_trainer/core/persistence/progress_repository.dart';
import 'package:blackjack_advantage_trainer/data/content_repository.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:blackjack_advantage_trainer/viewmodels/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CourseCatalog catalog;
  // Load assets outside the separate fake-async zone of each widget test.
  setUpAll(() async => catalog = await ContentRepository().loadCatalog());

  testWidgets('first launch selects an experience level and adapts the path', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      tester.view.reset();
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    final appState = _createAppState(catalog);
    addTearDown(appState.dispose);

    await tester.pumpWidget(BlackjackTrainerApp(appState: appState));
    await tester.pumpAndSettle();

    expect(find.text('Where should we start?'), findsOneWidget);
    expect(find.text("I'm new to blackjack"), findsOneWidget);
    expect(find.text('I know the basics'), findsOneWidget);
    expect(find.text("I'm an experienced player"), findsOneWidget);
    await tester.tap(find.text("I'm new to blackjack"));
    await tester.pumpAndSettle();

    expect(find.text('Help improve the training'), findsOneWidget);
    await tester.ensureVisible(find.text('Save and continue'));
    await tester.tap(find.text('Save and continue'));
    await tester.pumpAndSettle();

    expect(find.text('Learning path'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Your first hand'),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Your first hand'), findsOneWidget);
    expect(appState.progress.experienceLevel, ExperienceLevel.beginner);
    await Scrollable.ensureVisible(
      tester.element(find.text('Your first hand')),
      alignment: 0.3,
      duration: Duration.zero,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Your first hand'));
    await tester.pumpAndSettle();

    expect(find.text(catalog.foundationLessons.first.theory), findsOneWidget);

    await appState.chooseExperienceLevel(ExperienceLevel.experienced);
    await tester.pump();
    expect(appState.progress.experienceLevel, ExperienceLevel.experienced);
    expect(appState.isLessonUnlocked('first-strategy'), isTrue);
    expect(appState.isLessonCompleted('quick-start'), isFalse);
  });

  testWidgets(
    'Learn diagnostic is untimed, recommends a focus, and does not certify',
    (tester) async {
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        tester.view.reset();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      final appState = AppState(
        catalog: catalog,
        progress: const ProgressSnapshot(
          experienceLevel: ExperienceLevel.basics,
          hasSeenTelemetryConsent: true,
        ),
        progressRepository: _MemoryProgressRepository(),
      );
      addTearDown(appState.dispose);
      await tester.pumpWidget(BlackjackTrainerApp(appState: appState));
      await tester.pumpAndSettle();

      expect(find.text('Quick skill check'), findsOneWidget);
      expect(
        find.text(
          'Four untimed questions suggest where to practise next. This is not a certificate.',
        ),
        findsOneWidget,
      );
      Future<void> bringIntoView(Finder finder) async {
        await Scrollable.ensureVisible(
          tester.element(finder),
          alignment: 0.2,
          duration: Duration.zero,
        );
        await tester.pump();
        expect(finder.hitTestable(), findsOneWidget);
      }

      final start = find.text('Start check');
      await bringIntoView(start);
      await tester.tap(start);
      await tester.pump();
      expect(find.text('Question 1 of 4'), findsOneWidget);
      Future<void> answer(String text) async {
        final option = find.text(text);
        await bringIntoView(option);
        await tester.tap(option);
        await tester.pump();
      }

      await answer('The dealer up-card and your hand');
      await answer('On a two-card hand when the rules allow it');
      await answer('+1');
      await answer('When the shoe is shuffled');
      await tester.pump();
      expect(find.text('Suggested next focus'), findsOneWidget);
      expect(
        find.text('Alternate basic strategy with running-count practice.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'This check only suggests a starting point. It does not unlock lessons or certify mastery.',
        ),
        findsOneWidget,
      );
      final runAgain = find.text('Run again');
      await bringIntoView(runAgain);
      await tester.tap(runAgain);
      await tester.pump();
      expect(find.text('Question 1 of 4'), findsOneWidget);
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}

AppState _createAppState(CourseCatalog catalog) {
  return AppState(
    catalog: catalog,
    progress: const ProgressSnapshot(),
    progressRepository: _MemoryProgressRepository(),
  );
}

class _MemoryProgressRepository implements ProgressRepository {
  ProgressSnapshot snapshot = const ProgressSnapshot();

  @override
  Future<void> clear() async {
    snapshot = const ProgressSnapshot();
  }

  @override
  Future<ProgressSnapshot> load() async => snapshot;

  @override
  Future<void> save(ProgressSnapshot snapshot) async {
    this.snapshot = snapshot;
  }
}
