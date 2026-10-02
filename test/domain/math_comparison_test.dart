import 'dart:convert';
import 'dart:io';

import 'package:blackjack_advantage_trainer/domain/learning/decision_lesson.dart';
import 'package:blackjack_advantage_trainer/domain/learning/math_comparison.dart';
import 'package:blackjack_advantage_trainer/domain/learning/pilot_lesson.dart';
import 'package:flutter_test/flutter_test.dart';

List<PilotLesson> mathLessons(String locale) =>
    (jsonDecode(
              File(
                'assets/content/$locale/math_lessons.json',
              ).readAsStringSync(),
            )
            as List)
        .map((l) => PilotLesson.fromJson(l as Map<String, Object?>))
        .toList();

(int, int) independentValue(List<int> outcomes, ComparisonMetric metric) =>
    switch (metric) {
      ComparisonMetric.expectedValue => (
        outcomes.reduce((a, b) => a + b),
        outcomes.length,
      ),
      // Var(X) = E[(X-Y)^2]/2 for independent identically distributed X,Y.
      ComparisonMetric.variance => (
        [
          for (final a in outcomes)
            for (final b in outcomes) (a - b) * (a - b),
        ].reduce((a, b) => a + b),
        2 * outcomes.length * outcomes.length,
      ),
      ComparisonMetric.lossChance => (
        outcomes.where((v) => v < 0).length,
        outcomes.length,
      ),
    };

void main() {
  for (final locale in ['en', 'ru']) {
    test(
      '$locale: all comparisons match independent pairwise variance identity',
      () {
        final lessons = mathLessons(locale);
        expect(lessons, hasLength(4));
        for (final lesson in lessons) {
          final seen = lesson.scenarios
              .take(7)
              .map((s) => jsonEncode(s.comparison!.toJson()))
              .toSet();
          expect(
            lesson.scenarios
                .skip(7)
                .any((s) => seen.contains(jsonEncode(s.comparison!.toJson()))),
            isFalse,
          );
          for (final task in lesson.scenarios) {
            final c = task.comparison!;
            final (a, b) = independentValue(c.left.outcomes, c.metric);
            final (d, e) = independentValue(c.right.outcomes, c.metric);
            final difference = a * e - d * b;
            expect(
              task.expected,
              difference == 0
                  ? 'equal'
                  : difference > 0
                  ? 'left'
                  : 'right',
            );
            for (final distribution in [c.left, c.right]) {
              for (final metric in ComparisonMetric.values) {
                final (x, y) = independentValue(distribution.outcomes, metric);
                final (z, w) = distribution.value(metric);
                expect(x * w, z * y);
              }
            }
          }
        }
      },
    );
    test(
      '$locale: samples, first answers, hints and correction survive resume',
      () {
        final translated = mathLessons(locale == 'en' ? 'ru' : 'en');
        for (final entry in mathLessons(locale).indexed) {
          final lesson = entry.$2;
          var session = DecisionLessonSession(lesson)..begin();
          expect(lesson.resumeSignature, translated[entry.$1].resumeSignature);
          for (var i = 0; i < 12; i++) {
            expect(
              () => session.answer(session.current.expected),
              throwsStateError,
            );
            for (var sample = 0; sample < 2; sample++) {
              session.reveal();
              session = DecisionLessonSession.restore(
                translated[entry.$1],
                session.toJson(),
              );
              expect(session.revealed, sample + 1);
            }
            if (i == 3) session.useHint();
            final expected = session.current.expected;
            final first = i == 2
                ? session.current.answerKeys.firstWhere((a) => a != expected)
                : expected;
            session.answer(first);
            session = DecisionLessonSession.restore(lesson, session.toJson());
            if (i == 2) session.answer(expected);
            expect(session.firstAnswer, first);
            session.next();
          }
          expect(session.correctAnswers, 9);
          expect(session.unassistedAnswers, 8);
          expect(session.passed, isTrue);
        }
      },
    );
  }
  test('invalid models and fixed samples fail closed', () {
    expect(() => PointDistribution([]), throwsFormatException);
    expect(() => PointDistribution([101, 0]), throwsFormatException);
    expect(
      () => MathComparison.fromJson({
        'left': [0, 1],
        'right': [0, 1],
        'metric': 'variance',
        'samples': [2, 0],
      }),
      throwsFormatException,
    );
    final raw =
        (jsonDecode(
                      File(
                        'assets/content/en/math_lessons.json',
                      ).readAsStringSync(),
                    )
                    as List)
                .first
            as Map<String, Object?>;
    final original = PilotLesson.fromJson(raw);
    ((raw['scenarios'] as List).first['comparison'] as Map)['left'] = [
      -10,
      0,
      10,
    ];
    expect(
      () => DecisionLessonSession.restore(
        PilotLesson.fromJson(raw),
        DecisionLessonSession(original).toJson(),
      ),
      throwsFormatException,
    );
  });
}
