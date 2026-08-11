import 'package:blackjack_advantage_trainer/app/app.dart';
import 'package:blackjack_advantage_trainer/core/persistence/progress_repository.dart';
import 'package:blackjack_advantage_trainer/data/content_repository.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:blackjack_advantage_trainer/viewmodels/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('first launch selects an experience level and adapts the path', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      tester.view.reset();
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    final appState = await _createAppState();

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

    expect(
      find.text('What is the main goal of a blackjack hand?'),
      findsOneWidget,
    );

    await appState.chooseExperienceLevel(ExperienceLevel.experienced);
    await tester.pump();
    expect(appState.progress.experienceLevel, ExperienceLevel.experienced);
    expect(appState.isLessonUnlocked('first-strategy'), isTrue);
    expect(appState.isLessonCompleted('quick-start'), isFalse);
  });
}

Future<AppState> _createAppState() async {
  final catalog = await ContentRepository().loadEnglishCatalog();
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
