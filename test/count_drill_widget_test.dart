import 'package:blackjack_advantage_trainer/app/theme.dart';
import 'package:blackjack_advantage_trainer/core/persistence/progress_repository.dart';
import 'package:blackjack_advantage_trainer/data/content_repository.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:blackjack_advantage_trainer/l10n/app_localizations.dart';
import 'package:blackjack_advantage_trainer/presentation/drill/count_drill_screen.dart';
import 'package:blackjack_advantage_trainer/viewmodels/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('count drill intro can be acknowledged once', (tester) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      tester.view.reset();
    });
    final catalog = await ContentRepository().loadEnglishCatalog();
    final appState = AppState(
      catalog: catalog,
      progress: const ProgressSnapshot(
        experienceLevel: ExperienceLevel.experienced,
      ),
      progressRepository: MemoryProgressRepository(),
    );

    await _pumpDrill(tester, appState);

    expect(find.text('Before your first count'), findsOneWidget);
    expect(find.text('2–6  →  +1'), findsOneWidget);
    expect(find.text('7–9  →  0'), findsOneWidget);
    expect(find.text('10, J, Q, K, A  →  −1'), findsOneWidget);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    expect(appState.hasSeenCountDrillIntro, isTrue);
    expect(find.text('Before your first count'), findsNothing);

    await _pumpDrill(tester, appState);
    expect(find.text('Before your first count'), findsNothing);
  });
}

Future<void> _pumpDrill(WidgetTester tester, AppState appState) async {
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
        home: const CountDrillScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class MemoryProgressRepository implements ProgressRepository {
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
