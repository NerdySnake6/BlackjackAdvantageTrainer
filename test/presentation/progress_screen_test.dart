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
  testWidgets(
    'ProgressScreen displays stats, toggles consent, and handles reset flow',
    (tester) async {
      _setupPortrait(tester);
      final appState = await _createAppState(
        progress: ProgressSnapshot(
          xp: 250,
          streakDays: 4,
          lessonScores: const {'quick-start': 0.9, 'card-values': 1.0},
          experienceLevel: ExperienceLevel.basics,
          analyticsConsent: const ConsentState(isGranted: false),
          crashReportsConsent: const ConsentState(isGranted: false),
        ),
      );

      await _pumpScreen(tester, appState);

      // 1. Verify stats & header
      expect(find.text('Your progress'), findsOneWidget);
      expect(find.text('250'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('95%'), findsOneWidget);
      expect(find.text('2 of 6 lessons completed'), findsOneWidget);

      // 2. Toggle privacy switches
      final analyticsSwitch = find.widgetWithText(
        SwitchListTile,
        'Usage analytics',
      );
      expect(analyticsSwitch, findsOneWidget);
      await tester.tap(analyticsSwitch);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(appState.progress.analyticsConsent.isGranted, isTrue);

      final crashSwitch = find.widgetWithText(SwitchListTile, 'Crash reports');
      expect(crashSwitch, findsOneWidget);
      await tester.tap(crashSwitch);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(appState.progress.crashReportsConsent.isGranted, isTrue);

      // 3. Scroll to reset button and test cancel
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final resetBtn = find.text('Reset progress');
      await tester.tap(resetBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Reset all lesson progress and XP?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Reset all lesson progress and XP?'), findsNothing);
      expect(appState.progress.xp, 250);

      // 4. Confirm reset clears progress
      await tester.tap(resetBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(appState.progress.xp, 0);
      expect(appState.progress.lessonScores, isEmpty);
    },
  );
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
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
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
