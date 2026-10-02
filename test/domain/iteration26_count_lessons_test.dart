import 'dart:convert';
import 'dart:io';

import 'package:blackjack_advantage_trainer/domain/learning/decision_lesson.dart';
import 'package:blackjack_advantage_trainer/domain/learning/pilot_lesson.dart';
import 'package:flutter_test/flutter_test.dart';

List<PilotLesson> countLessons(String locale) =>
    (jsonDecode(
              File(
                'assets/content/$locale/count_lessons.json',
              ).readAsStringSync(),
            )
            as List)
        .map((l) => PilotLesson.fromJson(l as Map<String, Object?>))
        .toList();

const tags = {
  'A': -1,
  '2': 1,
  '3': 1,
  '4': 1,
  '5': 1,
  '6': 1,
  '7': 0,
  '8': 0,
  '9': 0,
  '10': -1,
  'J': -1,
  'Q': -1,
  'K': -1,
};

void main() {
  for (final locale in ['en', 'ru']) {
    test('$locale: every tag and chunk matches independent Hi-Lo mapping', () {
      final lessons = countLessons(locale);
      expect(lessons.map((l) => l.id), ['hi-lo-intro', 'hi-lo-chunks']);
      final ranks = lessons.first.scenarios
          .expand((s) => s.cards.map((c) => c.rank.label))
          .toSet();
      expect(ranks, tags.keys.toSet());
      for (final lesson in lessons) {
        for (final task in lesson.scenarios) {
          expect(
            task.expected,
            '${task.cards.fold(0, (sum, c) => sum + tags[c.rank.label]!)}',
          );
          expect(task.chunked, lesson.id == 'hi-lo-chunks');
          if (task.chunked) expect(task.cards.length, inInclusiveRange(3, 5));
        }
        String fingerprint(PilotScenario task) =>
            task.cards.map((c) => c.rank.label).join(',');
        final practice = lesson.scenarios.take(7).map(fingerprint).toSet();
        expect(
          lesson.scenarios
              .skip(7)
              .any((s) => practice.contains(fingerprint(s))),
          isFalse,
        );
      }
    });
    test(
      '$locale: card and chunk revelation persists, scores never rewrite first answers',
      () {
        final translated = countLessons(locale == 'en' ? 'ru' : 'en');
        for (final entry in countLessons(locale).indexed) {
          final lesson = entry.$2;
          expect(lesson.resumeSignature, translated[entry.$1].resumeSignature);
          var session = DecisionLessonSession(lesson)..begin();
          for (var i = 0; i < 12; i++) {
            final task = session.current;
            expect(() => session.answer(task.expected), throwsStateError);
            final steps = task.chunked ? 1 : task.cards.length;
            for (var step = 0; step < steps; step++) {
              session.reveal();
              session = DecisionLessonSession.restore(
                translated[entry.$1],
                session.toJson(),
              );
              expect(
                session.revealed,
                task.chunked ? task.cards.length : step + 1,
              );
            }
            if (i == 3) session.useHint();
            session.answer(i == 2 ? '0' : task.expected);
            if (i == 2) {
              expect(session.corrected, isFalse);
              session = DecisionLessonSession.restore(lesson, session.toJson());
              session.answer(task.expected);
              expect(session.firstAnswer, '0');
            }
            session.next();
          }
          expect(session.correctAnswers, 9);
          expect(session.unassistedAnswers, 8);
        }
      },
    );
  }
  test('chunk layout changes cannot silently reuse an old saved task', () {
    final raw =
        (jsonDecode(
                      File(
                        'assets/content/en/count_lessons.json',
                      ).readAsStringSync(),
                    )
                    as List)
                .last
            as Map<String, Object?>;
    final original = PilotLesson.fromJson(raw);
    final saved = DecisionLessonSession(original).toJson();
    final started = DecisionLessonSession(original)..begin();
    expect(
      () => DecisionLessonSession.restore(original, {
        ...started.toJson(),
        'revealed': 1,
      }),
      throwsFormatException,
    );
    (raw['scenarios'] as List).first['chunked'] = false;
    expect(
      () => DecisionLessonSession.restore(PilotLesson.fromJson(raw), saved),
      throwsFormatException,
    );
  });
}
