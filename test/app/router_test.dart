import 'package:blackjack_advantage_trainer/app/router.dart';
import 'package:blackjack_advantage_trainer/app/theme.dart';
import 'package:blackjack_advantage_trainer/core/persistence/progress_repository.dart';
import 'package:blackjack_advantage_trainer/data/content_repository.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:blackjack_advantage_trainer/l10n/app_localizations.dart';
import 'package:blackjack_advantage_trainer/viewmodels/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// rootBundle.loadString does not resolve inside a second testWidgets body in
// the same file, so the catalog is loaded once here and shared.
late final CourseCatalog catalog;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    catalog = await ContentRepository().loadCatalog();
  });

  testWidgets('a fresh install lands on onboarding', (tester) async {
    final router = await _pumpRouter(tester, const ProgressSnapshot());

    expect(router.state.matchedLocation, '/onboarding');
  });

  testWidgets('an experience level without consent lands on the consent step', (
    tester,
  ) async {
    final router = await _pumpRouter(
      tester,
      const ProgressSnapshot(experienceLevel: ExperienceLevel.beginner),
    );

    expect(router.state.matchedLocation, '/telemetry-consent');
  });

  testWidgets('finished onboarding lands on the learning path', (tester) async {
    final router = await _pumpRouter(tester, _onboarded);

    expect(router.state.matchedLocation, '/learn');
  });

  testWidgets('finished onboarding cannot go back to onboarding', (
    tester,
  ) async {
    final router = await _pumpRouter(tester, _onboarded);

    router.go('/onboarding');
    await tester.pumpAndSettle();

    expect(router.state.matchedLocation, '/learn');
  });

  testWidgets('an unknown lesson id redirects to the learning path', (
    tester,
  ) async {
    final router = await _pumpRouter(tester, _onboarded);

    router.go('/lesson/no-such-lesson');
    await tester.pumpAndSettle();

    expect(router.state.matchedLocation, '/learn');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a known lesson id opens the lesson', (tester) async {
    final router = await _pumpRouter(tester, _onboarded);

    router.go('/lesson/${ExperienceLevel.beginner.startLessonId}');
    await tester.pumpAndSettle();

    expect(
      router.state.matchedLocation,
      '/lesson/${ExperienceLevel.beginner.startLessonId}',
    );
    expect(tester.takeException(), isNull);
  });
}

const _onboarded = ProgressSnapshot(
  experienceLevel: ExperienceLevel.beginner,
  hasSeenTelemetryConsent: true,
);

Future<GoRouter> _pumpRouter(
  WidgetTester tester,
  ProgressSnapshot progress,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(430, 932);

  final appState = AppState(
    catalog: catalog,
    progress: progress,
    progressRepository: _MemoryProgressRepository(),
  );
  final router = createRouter(appState: appState);
  // Disposing the router while the tree still holds it hangs the next test,
  // so unmount first. Same order as widget_test.dart.
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    tester.view.reset();
  });

  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: appState,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

class _MemoryProgressRepository implements ProgressRepository {
  @override
  Future<void> clear() async {}

  @override
  Future<ProgressSnapshot> load() async => const ProgressSnapshot();

  @override
  Future<void> save(ProgressSnapshot snapshot) async {}
}
