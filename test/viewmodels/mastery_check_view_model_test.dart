import 'dart:async';

import 'package:blackjack_advantage_trainer/data/content_repository.dart';
import 'package:blackjack_advantage_trainer/data/local_progress_repository.dart';
import 'package:blackjack_advantage_trainer/domain/learning/mastery_check.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:blackjack_advantage_trainer/viewmodels/app_state.dart';
import 'package:blackjack_advantage_trainer/viewmodels/mastery_check_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CourseCatalog catalog;
  setUpAll(() async => catalog = await ContentRepository().loadCatalog());

  test(
    'fresh checks persist every answer, do not award XP, cannot be replayed',
    () async {
      final storage = _Storage();
      final repository = LocalProgressRepository.withStorage(storage);
      final original = ProgressSnapshot(
        xp: 500,
        streakDays: 5,
        languageCode: 'ru',
        lessonScores: {
          for (final lesson in catalog.pilotLessons) lesson.id: 0.8,
        },
      );
      await repository.save(original);
      var app = AppState(
        catalog: catalog,
        progress: original,
        progressRepository: repository,
      );
      for (final lesson in catalog.pilotLessons) {
        var vm = MasteryCheckViewModel(appState: app, lessonId: lesson.id);
        expect(app.isLessonMastered(lesson.id), isFalse);
        await vm.begin();
        for (var form = 0; form < 2; form++) {
          for (var index = 0; index < 10; index++) {
            while (vm.session.current.isCounting && !vm.session.canAnswer) {
              await vm.reveal();
            }
            if (vm.session.current.isCounting) {
              await vm.adjustCount(1);
              expect(vm.session.count, 1);
            }
            final task = vm.session.current;
            final answer = form == 0
                ? task.isCounting
                      ? '3'
                      : task.expected == 'hit'
                      ? 'stand'
                      : 'hit'
                : task.expected;
            await vm.answer(answer);
            final saved = vm.session.toJson();
            vm.dispose();
            app.dispose();
            app = AppState(
              catalog: catalog,
              progress: await repository.load(),
              progressRepository: repository,
            );
            vm = MasteryCheckViewModel(appState: app, lessonId: lesson.id);
            expect(vm.session.toJson(), saved);
            expect(vm.saveFailed, isFalse);
          }
          final writes = storage.writes;
          await app.saveMasteryCheck(vm.session);
          expect(storage.writes, writes);
          if (form == 0) {
            expect(app.isLessonMastered(lesson.id), isFalse);
            expect(vm.hasNextForm, isTrue);
            await vm.nextForm();
          }
        }
        expect(app.isLessonMastered(lesson.id), isTrue);
        expect(vm.hasNextForm, isFalse);
        await vm.nextForm();
        expect(vm.session.form, 1);
        await expectLater(
          app.saveMasteryCheck(MasteryCheckSession(lesson.id)),
          throwsStateError,
        );
        vm.dispose();
      }
      final finalJson = Map<String, Object?>.of(app.progress.toJson())
        ..remove('masteryChecks');
      final originalJson = Map<String, Object?>.of(original.toJson())
        ..remove('masteryChecks');
      expect(finalJson, originalJson);
      app.dispose();
    },
  );

  test(
    'failed writes and duplicate taps cannot advance or award mastery',
    () async {
      final storage = _Storage();
      final app = AppState(
        catalog: catalog,
        progress: const ProgressSnapshot(lessonScores: {'hard-12': 1}),
        progressRepository: LocalProgressRepository.withStorage(storage),
      );
      final vm = MasteryCheckViewModel(appState: app, lessonId: 'hard-12');
      addTearDown(app.dispose);
      addTearDown(vm.dispose);
      await vm.answer('hit');
      expect(vm.started, isFalse);
      storage.fail = true;
      await vm.begin();
      expect(vm.saveFailed, isTrue);
      expect(vm.started, isFalse);
      expect(app.progress.masteryChecks, isEmpty);
      storage.fail = false;
      await vm.begin();
      storage.pending = Completer<void>();
      final first = vm.answer(vm.session.current.expected);
      await vm.answer('stand');
      expect(vm.busy, isTrue);
      storage.pending!.complete();
      await first;
      storage.pending = null;
      expect(vm.session.index, 1);
      for (var i = 1; i < 9; i++) {
        await vm.answer(vm.session.current.expected);
      }
      storage.fail = true;
      await vm.answer(vm.session.current.expected);
      expect(vm.session.index, 9);
      expect(app.isLessonMastered('hard-12'), isFalse);
      storage.fail = false;
      await vm.answer(vm.session.current.expected);
      expect(app.isLessonMastered('hard-12'), isTrue);
      expect(vm.hasNextForm, isFalse);
      await expectLater(
        app.saveMasteryCheck(MasteryCheckSession('hard-12', form: 1)),
        throwsStateError,
      );
    },
  );

  test(
    'invalid save is preserved, incomplete lessons and state rewinds are rejected',
    () async {
      final app = AppState(
        catalog: catalog,
        progress: const ProgressSnapshot(
          xp: 99,
          lessonScores: {'hard-12': 1, 'soft-18': 1},
          masteryChecks: {
            'hard-12': {'signature': 'old'},
          },
        ),
        progressRepository: LocalProgressRepository.withStorage(_Storage()),
      );
      addTearDown(app.dispose);
      final vm = MasteryCheckViewModel(appState: app, lessonId: 'hard-12');
      addTearDown(vm.dispose);
      expect(vm.incompatibleSave, isTrue);
      expect(app.isLessonMastered('hard-12'), isFalse);
      await vm.begin();
      expect(app.progress.masteryChecks['hard-12'], {'signature': 'old'});
      await expectLater(
        app.saveMasteryCheck(MasteryCheckSession('hi-lo-cancellation')),
        throwsStateError,
      );
      final session = MasteryCheckSession('soft-18');
      session.answer('stand');
      await expectLater(app.saveMasteryCheck(session), throwsStateError);
      await app.saveMasteryCheck(MasteryCheckSession('soft-18'));
      await app.saveMasteryCheck(session);
      await expectLater(
        app.saveMasteryCheck(MasteryCheckSession('soft-18')),
        throwsStateError,
      );
      await expectLater(
        app.saveMasteryCheck(MasteryCheckSession('soft-18')..answer('hit')),
        throwsStateError,
      );
      await expectLater(
        app.saveMasteryCheck(MasteryCheckSession('soft-18', form: 1)),
        throwsStateError,
      );
      expect(app.progress.xp, 99);
    },
  );
}

class _Storage implements ProgressStorage {
  final values = <String, String>{};
  bool fail = false;
  int writes = 0;
  Completer<void>? pending;
  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> remove(String key) async => values.remove(key);
  @override
  Future<void> setString(String key, String value) async {
    if (fail) throw StateError('Storage unavailable');
    await pending?.future;
    values[key] = value;
    writes++;
  }
}
