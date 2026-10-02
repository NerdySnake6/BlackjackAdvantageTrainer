import 'package:blackjack_advantage_trainer/data/content_repository.dart';
import 'package:blackjack_advantage_trainer/domain/learning/combined_practice.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/strategy_reference.dart';

int tag(String rank) => const ['2', '3', '4', '5', '6'].contains(rank)
    ? 1
    : const ['7', '8', '9'].contains(rank)
    ? 0
    : -1;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CourseCatalog en;
  late CourseCatalog ru;
  setUpAll(() async {
    en = await ContentRepository().loadCatalog();
    ru = await ContentRepository().loadCatalog(localeCode: 'ru');
  });
  test(
    'local calendar Monday key works across year and timezone boundaries',
    () {
      expect(
        CombinedPracticeSession.weekOf(DateTime(2026, 10, 4, 23)),
        '2026-09-28',
      );
      expect(
        CombinedPracticeSession.weekOf(DateTime(2026, 10, 5)),
        '2026-10-05',
      );
      expect(
        CombinedPracticeSession.weekOf(DateTime.utc(2027, 1, 1)),
        '2026-12-28',
      );
      expect(
        () => CombinedPracticeSession(en, week: '2026-10-02'),
        throwsArgumentError,
      );
    },
  );
  test(
    '52 weekly forms are locale-independent, repeatable and reference-correct',
    () {
      final forms = <String>{};
      for (var week = 0; week < 52; week++) {
        final key = CombinedPracticeSession.weekOf(
          DateTime(2026, 1, 5).add(Duration(days: week * 7)),
        );
        final s = CombinedPracticeSession(en, week: key);
        expect(s.tasks, hasLength(10));
        expect(s.tasks.map((t) => t.id).toSet(), hasLength(10));
        expect(CombinedPracticeSession(ru, week: key).signature, s.signature);
        expect(
          CombinedPracticeSession(en, week: key, attempt: 2).signature,
          s.signature,
        );
        var rc = 0;
        for (final e in s.tasks.indexed) {
          final t = e.$2;
          expect(
            t.expected,
            referenceStrategy(
              t.cards.map((c) => c.rank.label).toList(),
              t.dealer!.rank.label,
              t.availableActions,
            ),
            reason: t.id,
          );
          rc += [
            ...t.cards,
            t.dealer!,
          ].fold(0, (n, c) => n + tag(c.rank.label));
          expect(s.expectedCount(e.$1), rc);
        }
        forms.add(s.tasks.map((t) => t.id).join('/'));
      }
      expect(forms.length, greaterThan(40));
    },
  );
  test(
    'first answers, cumulative RC correction, feedback timing and every resume phase',
    () {
      var s = CombinedPracticeSession(en, week: '2026-09-28', timed: true);
      void reload() {
        final data = s.toJson();
        s = CombinedPracticeSession.restore(ru, data);
        expect(s.toJson(), data);
      }

      expect(() => s.answer(), throwsStateError);
      s.begin();
      reload();
      for (var i = 0; i < 10; i++) {
        expect(() => s.choose(s.task.expected), throwsStateError);
        while (s.revealed < s.cards.length) {
          s.reveal();
          reload();
        }
        s.choose(
          i == 0
              ? s.task.availableActions
                    .firstWhere((a) => a.name != s.task.expected)
                    .name
              : s.task.expected,
        );
        reload();
        expect(s.feedback, isFalse);
        expect(() => s.choose(s.task.expected), throwsStateError);
        final expected = s.expectedCount(i);
        final target = expected + (i == 1 ? 1 : 0);
        while (s.input != target) {
          s.adjust(s.input < target ? 1 : -1);
        }
        reload();
        s.addTime(1000);
        s.answer();
        reload();
        final elapsed = s.elapsedMs;
        s.addTime(90000);
        expect(s.elapsedMs, elapsed);
        if (!s.complete) {
          expect(s.feedback, isTrue);
          expect(() => s.answer(), throwsStateError);
          s.next();
          reload();
          expect(s.input, expected);
        }
      }
      expect(s.strategyCorrect, 9);
      expect(s.countCorrect, 9);
      expect(s.bothCorrect, 8);
      expect(s.elapsedMs, 10000);
      expect(() => s.next(), throwsStateError);
    },
  );
  test(
    'invalid snapshots cannot manufacture a result and old progress stays compatible',
    () {
      final s = CombinedPracticeSession(en, week: '2026-09-28');
      for (final change in <Map<String, Object?>>[
        {'signature': 'changed'},
        {'attempt': 0},
        {'revealed': -1},
        {'input': 999},
        {'elapsedMs': -1},
        {'elapsedMs': 1},
        {'feedback': true},
        {
          'decisions': ['stand'],
        },
        {
          'counts': [0],
        },
        {'started': false, 'revealed': 1},
        {'decision': 'split'},
        {'week': 'bad'},
      ]) {
        expect(
          () => CombinedPracticeSession.restore(en, {...s.toJson(), ...change}),
          throwsFormatException,
        );
      }
      expect(
        ProgressSnapshot.fromJson({'xp': 123}).combinedPracticeSessions,
        isEmpty,
      );
      final saved = ProgressSnapshot(
        xp: 123,
        combinedPracticeSessions: {s.week: s.toJson()},
      );
      expect(
        ProgressSnapshot.fromJson(saved.toJson()).toJson(),
        saved.toJson(),
      );
    },
  );
}
