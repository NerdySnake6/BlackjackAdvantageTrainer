import 'package:blackjack_advantage_trainer/app/app.dart';
import 'package:blackjack_advantage_trainer/core/persistence/progress_repository.dart';
import 'package:blackjack_advantage_trainer/data/content_repository.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:blackjack_advantage_trainer/viewmodels/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('required portrait and landscape layouts fit', (tester) async {
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      BlackjackTrainerApp(appState: await _createAppState()),
    );
    await tester.pump();

    final portraitCases = <(Size, double)>[
      (const Size(320, 568), 1),
      (const Size(360, 800), 1.3),
      (const Size(430, 932), 1.3),
    ];
    for (final testCase in portraitCases) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = testCase.$1;
      tester.platformDispatcher.textScaleFactorTestValue = testCase.$2;
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Learning path'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    final landscapeCases = <(Size, double)>[
      (const Size(568, 320), 1),
      // Galaxy S20-class landscape height: just above the old 340px compact
      // cutoff, but still too short for the roomy seat-card sizing.
      (const Size(800, 360), 1),
      (const Size(844, 390), 1.3),
      (const Size(915, 412), 1.3),
    ];
    tester.view.physicalSize = landscapeCases.first.$1;
    tester.platformDispatcher.textScaleFactorTestValue =
        landscapeCases.first.$2;
    await tester.pump();
    await tester.tap(find.text('Table'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Deal the first round'), findsOneWidget);
    await tester.tap(find.byTooltip('Configure seats'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Choose Human, Bot, or Empty for each seat. Changes during a round '
        'apply to the next round. Keep at least one Human.',
      ),
      findsOneWidget,
    );
    expect(find.text('Seat 5'), findsWidgets);
    expect(tester.takeException(), isNull);

    expect(find.text('Human'), findsOneWidget);
    await tester.tap(find.text('Bot').first);
    await tester.pumpAndSettle();
    expect(find.text('Empty'), findsOneWidget);
    await tester.tap(find.text('Human').last);
    await tester.pumpAndSettle();
    expect(find.text('Human'), findsNWidgets(2));

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deal the first round'));
    await tester.pump(const Duration(seconds: 5));

    for (final testCase in landscapeCases) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = testCase.$1;
      tester.platformDispatcher.textScaleFactorTestValue = testCase.$2;
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('GUIDED TABLE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}

Future<AppState> _createAppState() async {
  return AppState(
    catalog: await ContentRepository().loadEnglishCatalog(),
    progress: const ProgressSnapshot(
      experienceLevel: ExperienceLevel.beginner,
      hasSeenTelemetryConsent: true,
    ),
    progressRepository: _MemoryProgressRepository(),
  );
}

class _MemoryProgressRepository implements ProgressRepository {
  @override
  Future<void> clear() async {}

  @override
  Future<ProgressSnapshot> load() async => const ProgressSnapshot();

  @override
  Future<void> save(ProgressSnapshot snapshot) async {}
}
