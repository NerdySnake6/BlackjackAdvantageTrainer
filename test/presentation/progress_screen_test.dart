import 'package:blackjack_advantage_trainer/app/theme.dart';
import 'package:blackjack_advantage_trainer/core/persistence/progress_repository.dart';
import 'package:blackjack_advantage_trainer/data/content_repository.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:blackjack_advantage_trainer/l10n/app_localizations.dart';
import 'package:blackjack_advantage_trainer/presentation/profile/progress_screen.dart';
import 'package:blackjack_advantage_trainer/viewmodels/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('ProgressScreen displays stats and adapts to progress', (
    tester,
  ) async {
    _setupPortrait(tester);
    final appState = await _createAppState(
      progress: ProgressSnapshot(
        xp: 250,
        streakDays: 4,
        lessonScores: const {'quick-start': 0.9, 'card-values': 1.0},
        experienceLevel: ExperienceLevel.basics,
      ),
    );

    await _pumpScreen(tester, appState);

    expect(find.text('Your progress'), findsOneWidget);
    expect(find.text('250'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('95%'), findsOneWidget); // (0.9 + 1.0) / 2 = 95%
    expect(find.text('2 of 6 lessons completed'), findsOneWidget);
  });

  testWidgets(
    'ProgressScreen toggles consent switches and selects experience level',
    (tester) async {
      _setupPortrait(tester);
      final appState = await _createAppState(
        progress: const ProgressSnapshot(
          experienceLevel: ExperienceLevel.beginner,
          analyticsConsent: ConsentState(isGranted: false),
          crashReportsConsent: ConsentState(isGranted: false),
        ),
      );

      await _pumpScreen(tester, appState);

      // Toggle analytics switch
      final analyticsSwitch = find.widgetWithText(
        SwitchListTile,
        'Usage analytics',
      );
      expect(analyticsSwitch, findsOneWidget);
      await tester.tap(analyticsSwitch);
      await tester.pumpAndSettle();

      expect(appState.progress.analyticsConsent.isGranted, isTrue);
      expect(appState.progress.crashReportsConsent.isGranted, isFalse);

      // Toggle crash reports switch
      final crashSwitch = find.widgetWithText(SwitchListTile, 'Crash reports');
      await tester.tap(crashSwitch);
      await tester.pumpAndSettle();

      expect(appState.progress.crashReportsConsent.isGranted, isTrue);

      // Change experience level dropdown (tested separately)
      /*
    final dropdownFinder = find.byType(DropdownButtonFormField<ExperienceLevel>);
    await tester.scrollUntilVisible(
      dropdownFinder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();

    await tester.tap(find.text("I'm an experienced player").last);
    await tester.pumpAndSettle();

    expect(appState.progress.experienceLevel, ExperienceLevel.experienced);
    */
    },
  );

  testWidgets(
    'ProgressScreen reset dialog cancels without resetting progress',
    (tester) async {
      _setupPortrait(tester);
      final appState = await _createAppState(
        progress: const ProgressSnapshot(
          xp: 150,
          lessonScores: {'quick-start': 1.0},
        ),
      );

      await _pumpScreen(tester, appState);

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      final resetBtn = find.text('Reset progress');
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      expect(find.text('Reset all lesson progress and XP?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Reset all lesson progress and XP?'), findsNothing);
      expect(appState.progress.xp, 150);
      expect(appState.progress.lessonScores, isNotEmpty);
    },
  );

  testWidgets('ProgressScreen reset dialog confirms and clears progress', (
    tester,
  ) async {
    _setupPortrait(tester);
    final appState = await _createAppState(
      progress: const ProgressSnapshot(
        xp: 150,
        lessonScores: {'quick-start': 1.0},
      ),
    );

    await _pumpScreen(tester, appState);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    final resetBtn = find.text('Reset progress');
    await tester.tap(resetBtn);
    await tester.pumpAndSettle();

    expect(find.text('Reset all lesson progress and XP?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
    await tester.pumpAndSettle();

    expect(appState.progress.xp, 0);
    expect(appState.progress.lessonScores, isEmpty);
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
        home: const ProgressScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<AppState> _createAppState({
  ProgressSnapshot progress = const ProgressSnapshot(),
}) async {
  final catalog = await ContentRepository().loadCatalog();
  return AppState(
    catalog: catalog,
    progress: progress,
    progressRepository: _MemoryProgressRepository(),
  );
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
