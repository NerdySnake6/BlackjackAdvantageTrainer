import 'package:blackjack_advantage_trainer/app/app.dart';
import 'package:blackjack_advantage_trainer/core/persistence/progress_repository.dart';
import 'package:blackjack_advantage_trainer/data/content_repository.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:blackjack_advantage_trainer/viewmodels/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

late final CourseCatalog _enCatalog;
late final CourseCatalog _ruCatalog;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    _enCatalog = await ContentRepository().loadCatalog(localeCode: 'en');
    _ruCatalog = await ContentRepository().loadCatalog(localeCode: 'ru');
  });

  testWidgets('required portrait and landscape layouts fit in English', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(BlackjackTrainerApp(appState: _createAppState()));
    await tester.pump();

    final portraitCases = <(Size, double)>[
      (const Size(320, 568), 1),
      (const Size(320, 568), 1.3),
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

  testWidgets(
    'required Russian layouts fit without overflow across screen sizes and text scaling',
    (tester) async {
      addTearDown(() {
        tester.view.reset();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      tester.view.devicePixelRatio = 1;

      final appState = _createAppState(isRussian: true);
      await tester.pumpWidget(BlackjackTrainerApp(appState: appState));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final portraitCases = <(Size, double)>[
        (const Size(320, 568), 1),
        (const Size(320, 568), 1.3),
        (const Size(360, 800), 1.3),
        (const Size(430, 932), 1.3),
      ];

      // 1. Check Learning Path across portrait sizes
      for (final testCase in portraitCases) {
        tester.view.physicalSize = testCase.$1;
        tester.platformDispatcher.textScaleFactorTestValue = testCase.$2;
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Путь обучения'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      // 2. Check Drill screen and its intro dialog
      await tester.tap(find.text('Тренажёр'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Перед первым подсчётом'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Dismiss dialog
      await tester.tap(find.text('Понятно'));
      await tester.pumpAndSettle();
      expect(find.text('Начать тренировку (1 колода)'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 3. Check Progress screen on compact 320x568 with text scale 1.3
      tester.view.physicalSize = const Size(320, 568);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      await tester.tap(find.text('Прогресс'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Ваш прогресс'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 4. Check Table in landscape mode across all landscape sizes
      final landscapeCases = <(Size, double)>[
        (const Size(568, 320), 1),
        (const Size(800, 360), 1),
        (const Size(844, 390), 1.3),
        (const Size(915, 412), 1.3),
      ];

      tester.view.physicalSize = landscapeCases.first.$1;
      tester.platformDispatcher.textScaleFactorTestValue =
          landscapeCases.first.$2;
      await tester.pump();

      await tester.tap(find.text('Стол'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Сдать первый раунд'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Configure seats dialog in Russian
      await tester.tap(find.byTooltip('Настройка боксов'));
      await tester.pumpAndSettle();

      expect(find.text('Готово'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Готово'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Сдать первый раунд'));
      await tester.pump(const Duration(seconds: 5));

      for (final testCase in landscapeCases) {
        tester.view.physicalSize = testCase.$1;
        tester.platformDispatcher.textScaleFactorTestValue = testCase.$2;
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('ОБУЧАЮЩИЙ СТОЛ'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );
}

AppState _createAppState({bool isRussian = false}) {
  return AppState(
    catalog: isRussian ? _ruCatalog : _enCatalog,
    progress: ProgressSnapshot(
      experienceLevel: ExperienceLevel.beginner,
      hasSeenTelemetryConsent: true,
      languageCode: isRussian ? 'ru' : null,
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
