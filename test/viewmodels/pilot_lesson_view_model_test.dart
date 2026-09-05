import 'dart:async';

import 'package:blackjack_advantage_trainer/data/content_repository.dart';
import 'package:blackjack_advantage_trainer/data/local_progress_repository.dart';
import 'package:blackjack_advantage_trainer/domain/learning/decision_lesson.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:blackjack_advantage_trainer/viewmodels/app_state.dart';
import 'package:blackjack_advantage_trainer/viewmodels/pilot_lesson_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CourseCatalog catalog;
  setUpAll(() async => catalog = await ContentRepository().loadCatalog());

  test(
    'every saved interaction survives storage reload; rewards apply once',
    () async {
      final storage = _Storage();
      final repository = LocalProgressRepository.withStorage(storage);
      final original = ProgressSnapshot(
        xp: 320,
        streakDays: 4,
        languageCode: 'ru',
        lastActivityDate: DateTime(2026, 9, 4),
        experienceLevel: ExperienceLevel.experienced,
        hasSeenTelemetryConsent: true,
        analyticsConsent: const ConsentState(isGranted: true, policyVersion: 1),
        lessonScores: const {'quick-start': 0.9},
        activeSessions: const {
          'hard-and-soft': LessonSessionProgress(
            nextExerciseIndex: 2,
            correctAnswers: 1,
          ),
        },
      );
      await repository.save(original);
      AppState? app;
      PilotLessonViewModel? vm;
      Future<void> reload(String id) async {
        final before = vm?.session.toJson();
        vm?.dispose();
        app?.dispose();
        app = AppState(
          catalog: catalog,
          progress: await repository.load(),
          progressRepository: repository,
          clock: () => DateTime(2026, 9, 5),
        );
        vm = PilotLessonViewModel(
          appState: app!,
          lesson: catalog.pilotLessons.firstWhere((lesson) => lesson.id == id),
        );
        if (before != null && before['lessonId'] == id) {
          expect(vm!.session.toJson(), before);
        }
      }

      var expectedXp = original.xp;
      for (final lesson in catalog.pilotLessons) {
        await reload(lesson.id);
        await vm!.begin();
        await reload(lesson.id);
        for (var index = 0; index < 12; index++) {
          if (index == 3) {
            await vm!.hint();
            await reload(lesson.id);
          }
          while (vm!.session.current.isCounting &&
              vm!.session.revealed < vm!.session.current.cards.length) {
            await vm!.reveal();
            await reload(lesson.id);
          }
          final task = vm!.session.current;
          final wrong = task.isCounting
              ? (int.parse(task.expected) + 1).toString()
              : task.availableActions
                    .firstWhere((action) => action.name != task.expected)
                    .name;
          await vm!.answer(index == 2 ? wrong : task.expected);
          await reload(lesson.id);
          expect(vm!.session.current.id, task.id);
          if (index == 2) {
            await vm!.answer(task.expected);
            await reload(lesson.id);
            expect(vm!.session.firstAnswer, wrong);
          }
          await vm!.next();
          await reload(lesson.id);
        }
        expect(vm!.session.phase, DecisionLessonPhase.result);
        expectedXp += 140;
        expect(app!.progress.xp, expectedXp);
        expect(app!.progress.streakDays, 5);
        expect(app!.progress.lessonScores[lesson.id], 0.9);
        await app!.savePilotSession(vm!.session);
        await reload(lesson.id);
        expect(app!.progress.xp, expectedXp);
      }
      final saved = await repository.load();
      expect(
        saved.activeSessions['hard-and-soft']!.toJson(),
        original.activeSessions['hard-and-soft']!.toJson(),
      );
      expect(saved.lessonScores['quick-start'], 0.9);
      expect(saved.languageCode, 'ru');
      expect(saved.experienceLevel, original.experienceLevel);
      expect(
        saved.analyticsConsent.toJson(),
        original.analyticsConsent.toJson(),
      );
      expect(app!.reviewExercises(), isEmpty);
      final oldAttempt = vm!.session;
      await vm!.restart();
      expect(vm!.session.attempt, 2);
      expect(vm!.session.phase, DecisionLessonPhase.theory);
      expect(() => app!.savePilotSession(oldAttempt), throwsStateError);
      expect(app!.progress.xp, expectedXp);
      vm!.dispose();
      app!.dispose();
    },
  );

  test(
    'failed save can retry; fast taps do not duplicate transitions',
    () async {
      final storage = _Storage();
      final app = AppState(
        catalog: catalog,
        progress: const ProgressSnapshot(),
        progressRepository: LocalProgressRepository.withStorage(storage),
      );
      final vm = PilotLessonViewModel(
        appState: app,
        lesson: catalog.pilotLessons.last,
      );
      storage.fail = true;
      await vm.begin();
      expect(vm.saveFailed, isTrue);
      expect(vm.session.phase, DecisionLessonPhase.theory);
      expect(app.progress.pilotSessions, isEmpty);
      storage.fail = false;
      await vm.begin();
      storage.pending = Completer<void>();
      final first = vm.reveal();
      await vm.reveal();
      expect(vm.busy, isTrue);
      storage.pending!.complete();
      await first;
      storage.pending = null;
      expect(vm.session.revealed, 1);
      await vm.reveal();
      await vm.adjustCount(1);
      expect(vm.session.countInput, 1);
      vm.dispose();
      app.dispose();
    },
  );

  test(
    'failed final reward write rolls back and retry grants XP exactly once',
    () async {
      final storage = _Storage();
      final app = AppState(
        catalog: catalog,
        progress: const ProgressSnapshot(),
        progressRepository: LocalProgressRepository.withStorage(storage),
      );
      final vm = PilotLessonViewModel(
        appState: app,
        lesson: catalog.pilotLessons.first,
      );
      await vm.begin();
      for (var i = 0; i < 12; i++) {
        await vm.answer(vm.session.current.expected);
        if (i < 11) await vm.next();
      }
      storage.fail = true;
      await vm.next();
      expect(vm.saveFailed, isTrue);
      expect(vm.session.phase, DecisionLessonPhase.coaching);
      expect(app.progress.xp, 0);
      storage.fail = false;
      await vm.next();
      expect(app.progress.xp, 150);
      expect(vm.session.awardedXp, 150);
      await app.savePilotSession(vm.session);
      expect(app.progress.xp, 150);
      await vm.restart();
      await vm.begin();
      for (var i = 0; i < 12; i++) {
        await vm.answer(vm.session.current.expected);
        await vm.next();
      }
      expect(app.progress.xp, 250); // No second first-completion bonus.
      vm.dispose();
      app.dispose();
    },
  );

  test(
    'incompatible lesson offers explicit isolated restart, not a global reset',
    () async {
      final lesson = catalog.pilotLessons.first;
      final bad = {...DecisionLessonSession(lesson).toJson(), 'version': 99};
      final app = AppState(
        catalog: catalog,
        progress: ProgressSnapshot(xp: 999, pilotSessions: {lesson.id: bad}),
        progressRepository: LocalProgressRepository.withStorage(_Storage()),
      );
      final vm = PilotLessonViewModel(appState: app, lesson: lesson);
      expect(vm.incompatibleSave, isTrue);
      await vm.begin();
      expect(app.progress.pilotSessions[lesson.id], bad);
      await vm.restart();
      expect(vm.incompatibleSave, isFalse);
      expect(app.progress.xp, 999);
      expect(vm.session.attempt, 2);
      vm.dispose();
      app.dispose();
    },
  );
}

class _Storage implements ProgressStorage {
  final values = <String, String>{};
  bool fail = false;
  Completer<void>? pending;

  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> remove(String key) async => values.remove(key);
  @override
  Future<void> setString(String key, String value) async {
    if (fail) throw StateError('test storage unavailable');
    await pending?.future;
    values[key] = value;
  }
}
