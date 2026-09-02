import 'package:blackjack_advantage_trainer/app/theme.dart';
import 'package:blackjack_advantage_trainer/core/persistence/progress_repository.dart';
import 'package:blackjack_advantage_trainer/data/content_repository.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:blackjack_advantage_trainer/l10n/app_localizations.dart';
import 'package:blackjack_advantage_trainer/presentation/review/quick_review_screen.dart';
import 'package:blackjack_advantage_trainer/viewmodels/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('QuickReviewScreen handles empty state and active review flow', (
    tester,
  ) async {
    _setupPortrait(tester);
    final now = DateTime.utc(2026, 9, 2);
    final catalog = await ContentRepository().loadCatalog();
    final firstExercise = catalog.lessons.first.exercises.first;

    // 1. Verify empty state when no reviews are due
    final emptyAppState = AppState(
      catalog: catalog,
      progress: const ProgressSnapshot(),
      progressRepository: _MemoryProgressRepository(),
      clock: () => now,
    );

    await _pumpScreen(tester, emptyAppState);

    expect(find.text('Quick Review'), findsOneWidget);
    expect(find.text('Nothing to review yet'), findsOneWidget);
    expect(
      find.text(
        'Complete a few lesson exercises, then return for a focused review.',
      ),
      findsOneWidget,
    );
    expect(find.text('Back to path'), findsOneWidget);

    // 2. Verify active review session flow
    final activeAppState = AppState(
      catalog: catalog,
      progress: ProgressSnapshot(
        exerciseReviewStates: {
          firstExercise.id: ExerciseReviewState(nextReviewAt: now),
        },
      ),
      progressRepository: _MemoryProgressRepository(),
      clock: () => now,
    );

    await _pumpScreen(tester, activeAppState);

    expect(find.text(firstExercise.prompt), findsOneWidget);
    expect(find.text('Review 1 of 1'), findsOneWidget);

    // Answer the exercise
    final firstOption = find.byType(OutlinedButton).first;
    await tester.tap(firstOption);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(firstExercise.explanation), findsOneWidget);

    // Proceed to completion
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Review complete'), findsOneWidget);
    expect(find.text('Back to path'), findsOneWidget);
  });
}

void _setupPortrait(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _pumpScreen(WidgetTester tester, AppState appState) async {
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: appState,
      child: MaterialApp(
        key: UniqueKey(),
        theme: buildAppTheme(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const QuickReviewScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

class _MemoryProgressRepository implements ProgressRepository {
  ProgressSnapshot snapshot = const ProgressSnapshot();

  @override
  Future<void> clear() async => snapshot = const ProgressSnapshot();

  @override
  Future<ProgressSnapshot> load() async => snapshot;

  @override
  Future<void> save(ProgressSnapshot snapshot) async {
    this.snapshot = snapshot;
  }
}
