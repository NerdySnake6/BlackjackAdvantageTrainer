import 'package:blackjack_advantage_trainer/core/persistence/progress_repository.dart';
import 'package:blackjack_advantage_trainer/data/content_repository.dart';
import 'package:blackjack_advantage_trainer/domain/learning/decision_lesson.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:blackjack_advantage_trainer/l10n/app_localizations.dart';
import 'package:blackjack_advantage_trainer/presentation/learn/glossary_help.dart';
import 'package:blackjack_advantage_trainer/presentation/learn/pilot_lesson_screen.dart';
import 'package:blackjack_advantage_trainer/viewmodels/app_state.dart';
import 'package:blackjack_advantage_trainer/viewmodels/pilot_lesson_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../support/pilot_journey.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final catalogs = <String, CourseCatalog>{};
  setUpAll(() async {
    for (final locale in ['en', 'ru']) {
      catalogs[locale] = await ContentRepository().loadCatalog(
        localeCode: locale,
      );
    }
  });
  for (final locale in ['en', 'ru']) {
    testWidgets(
      '$locale glossary records a hint before opening and stays absent from independent tasks',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 568);
        addTearDown(tester.view.reset);
        final catalog = catalogs[locale]!;
        final lesson = catalog.strategyLessons.first;
        final session = DecisionLessonSession(lesson)..begin();
        for (var i = 0; i < 2; i++) {
          session.answer(session.current.expected);
          session.next();
        }
        final repository = _Repository();
        final app = AppState(
          catalog: catalog,
          progress: ProgressSnapshot(
            pilotSessions: {lesson.id: session.toJson()},
          ),
          progressRepository: repository,
        );
        addTearDown(app.dispose);
        Future<void> mount() async {
          await tester.pumpWidget(
            ChangeNotifierProvider.value(
              value: app,
              child: MaterialApp(
                locale: Locale(locale),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(2)),
                  child: child!,
                ),
                home: PilotLessonScreen(lessonId: lesson.id),
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        await mount();
        var vm = tester
            .element(find.byType(Scaffold))
            .read<PilotLessonViewModel>();
        final strings = AppLocalizations.of(
          tester.element(find.byType(Scaffold)),
        );
        await tapPilot(tester, find.byKey(const ValueKey('lesson-glossary')));
        await tapPilot(tester, find.text(strings.glossaryTitle));
        repository.fail = true;
        await tapPilot(tester, find.byKey(const ValueKey('term-hit')));
        expect(find.byType(AlertDialog), findsNothing);
        expect(vm.session.hintUsed, isFalse);
        repository.fail = false;
        await tapPilot(tester, find.byKey(const ValueKey('term-hit')));
        expect(find.text(catalog.glossary['hit']!), findsOneWidget);
        expect(vm.session.hintUsed, isTrue);
        expect(vm.session.firstAnswer, isNull);
        await tapPilot(
          tester,
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text(strings.done),
          ),
        );
        await tapPilot(
          tester,
          find.byKey(const ValueKey('lesson-glossary-close')),
        );
        for (var i = 0; i < 5; i++) {
          await vm.answer(vm.session.current.expected);
          await vm.next();
        }
        await tester.pumpAndSettle();
        vm = tester.element(find.byType(Scaffold)).read<PilotLessonViewModel>();
        expect(vm.session.isIndependent, isTrue);
        expect(find.byType(GlossaryHelp), findsNothing);
        expect(app.progress.masteryChecks, isEmpty);
      },
    );
  }
}

class _Repository implements ProgressRepository {
  bool fail = false;
  @override
  Future<void> clear() async {}
  @override
  Future<ProgressSnapshot> load() async => const ProgressSnapshot();
  @override
  Future<void> save(ProgressSnapshot snapshot) async {
    if (fail) throw StateError('storage unavailable');
  }
}
