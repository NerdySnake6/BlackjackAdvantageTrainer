import 'dart:convert';

import 'package:blackjack_advantage_trainer/app/app.dart';
import 'package:blackjack_advantage_trainer/core/persistence/progress_repository.dart';
import 'package:blackjack_advantage_trainer/data/content_repository.dart';
import 'package:blackjack_advantage_trainer/domain/learning/decision_lesson.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:blackjack_advantage_trainer/l10n/app_localizations.dart';
import 'package:blackjack_advantage_trainer/presentation/learn/pilot_lesson_screen.dart';
import 'package:blackjack_advantage_trainer/viewmodels/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
      '$locale: corrected answer is acknowledged without changing the first answer',
      (tester) async {
        final lesson = catalogs[locale]!.pilotLessons.first;
        final session = DecisionLessonSession(lesson)..begin();
        session.answer('hit');
        final (app, _) = await _openPilot(
          tester,
          catalogs[locale]!,
          lesson.id,
          saved: session.toJson(),
        );
        final strings = AppLocalizations.of(
          tester.element(find.byType(PilotLessonScreen)),
        );
        await tester.scrollUntilVisible(
          find.text(strings.incorrectAnswer),
          120,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(strings.incorrectAnswer), findsOneWidget);
        await tapPilot(
          tester,
          find.widgetWithText(FilledButton, strings.stand),
        );
        final corrected = find.text(
          locale == 'ru' ? 'Исправлено' : 'Corrected',
        );
        await tester.scrollUntilVisible(
          corrected,
          120,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(corrected.hitTestable(), findsOneWidget);
        expect(find.text(strings.incorrectAnswer), findsNothing);
        final next = find.byKey(const ValueKey('pilot-next'));
        await tester.scrollUntilVisible(
          next,
          120,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.widget<FilledButton>(next).onPressed, isNotNull);
        expect(
          (app.progress.pilotSessions[lesson.id]!['answers'] as List).first,
          'hit',
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '$locale: save failure remains visible at the bottom of long theory',
      (tester) async {
        final (app, repository) = await _openPilot(
          tester,
          catalogs[locale]!,
          'hard-12',
        );
        repository.fail = true;
        await tapPilot(tester, find.byKey(const ValueKey('pilot-begin')));
        expect(
          find.byKey(const ValueKey('pilot-save-error')).hitTestable(),
          findsOneWidget,
        );
        final bannerScroll = tester.state<ScrollableState>(
          find.descendant(
            of: find.byKey(const ValueKey('pilot-save-error')),
            matching: find.byType(Scrollable),
          ),
        );
        bannerScroll.position.jumpTo(bannerScroll.position.maxScrollExtent);
        await tester.pumpAndSettle();
        expect(bannerScroll.position.extentAfter, 0);
        expect(app.progress.pilotSessions, isEmpty);
        repository.fail = false;
        await tapPilot(tester, find.byKey(const ValueKey('pilot-begin')));
        expect(find.byKey(const ValueKey('pilot-save-error')), findsNothing);
        expect(app.progress.pilotSessions['hard-12']!['phase'], 'decision');
      },
    );

    testWidgets(
      '$locale: count input waits for the last card and disables bounds',
      (tester) async {
        final lesson = catalogs[locale]!.pilotLessons.last;
        final session = DecisionLessonSession(lesson)..begin();
        final (app, _) = await _openPilot(
          tester,
          catalogs[locale]!,
          lesson.id,
          saved: session.toJson(),
        );
        final strings = AppLocalizations.of(
          tester.element(find.byType(PilotLessonScreen)),
        );
        final increase = find.byWidgetPredicate(
          (widget) =>
              widget is IconButton && widget.tooltip == strings.pilotIncrease,
        );
        final decrease = find.byWidgetPredicate(
          (widget) =>
              widget is IconButton && widget.tooltip == strings.pilotDecrease,
        );
        await tester.scrollUntilVisible(
          increase,
          120,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.widget<IconButton>(increase).onPressed, isNull);
        expect(tester.widget<IconButton>(decrease).onPressed, isNull);
        expect(find.text(strings.pilotRevealBeforeCount), findsOneWidget);
        for (var i = 0; i < session.current.cards.length; i++) {
          await tapPilot(
            tester,
            find.widgetWithText(FilledButton, strings.nextCard),
          );
        }
        expect(find.text(strings.adjustCountInstruction), findsOneWidget);
        for (var i = 0; i < session.current.cards.length; i++) {
          await tapPilot(tester, increase);
        }
        expect(tester.widget<IconButton>(increase).onPressed, isNull);
        expect(app.progress.pilotSessions[lesson.id]!['countInput'], 2);
        for (var i = 0; i < session.current.cards.length * 2; i++) {
          await tapPilot(tester, decrease);
        }
        expect(tester.widget<IconButton>(decrease).onPressed, isNull);
        expect(app.progress.pilotSessions[lesson.id]!['countInput'], -2);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'all three $locale lessons work at 320px with large text and resume',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 568);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        final repository = _Repository(
          ProgressSnapshot(
            experienceLevel: ExperienceLevel.basics,
            hasSeenTelemetryConsent: true,
            languageCode: locale,
          ),
        );
        AppState? app;
        Future<AppState> reload() async {
          await tester.pumpWidget(const SizedBox());
          app?.dispose();
          app = AppState(
            catalog: catalogs[locale]!,
            progress: await repository.load(),
            progressRepository: repository,
          );
          await tester.pumpWidget(BlackjackTrainerApp(appState: app!));
          await tester.pumpAndSettle();
          return app!;
        }

        addTearDown(() async {
          await tester.pumpWidget(const SizedBox());
          app?.dispose();
          tester.view.reset();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });
        await reload();
        for (final lesson in catalogs[locale]!.pilotLessons) {
          await runPilotJourney(tester, app!, lesson, reloadApp: reload);
        }
        expect(app!.progress.xp, 420);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Future<(AppState, _Repository)> _openPilot(
  WidgetTester tester,
  CourseCatalog catalog,
  String id, {
  Map<String, Object?>? saved,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 568);
  tester.platformDispatcher.textScaleFactorTestValue = 2;
  final repository = _Repository(
    ProgressSnapshot(
      experienceLevel: ExperienceLevel.basics,
      hasSeenTelemetryConsent: true,
      languageCode: catalog.locale,
      pilotSessions: {id: ?saved},
    ),
  );
  final app = AppState(
    catalog: catalog,
    progress: repository.snapshot,
    progressRepository: repository,
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    app.dispose();
    tester.view.reset();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
  await tester.pumpWidget(BlackjackTrainerApp(appState: app));
  await tester.pumpAndSettle();
  await tapPilot(tester, find.byKey(ValueKey('pilot-$id')));
  return (app, repository);
}

class _Repository implements ProgressRepository {
  _Repository(this.snapshot);
  ProgressSnapshot snapshot;
  bool fail = false;
  @override
  Future<void> clear() async => snapshot = const ProgressSnapshot();
  @override
  Future<ProgressSnapshot> load() async => ProgressSnapshot.fromJson(
    jsonDecode(jsonEncode(snapshot.toJson())) as Map<String, Object?>,
  );
  @override
  Future<void> save(ProgressSnapshot snapshot) async {
    if (fail) throw StateError('Test storage failure');
    this.snapshot = snapshot;
  }
}
