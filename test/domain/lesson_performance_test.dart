import 'dart:convert';
import 'dart:io';

import 'package:blackjack_advantage_trainer/domain/learning/decision_lesson.dart';
import 'package:blackjack_advantage_trainer/domain/learning/lesson_performance.dart';
import 'package:blackjack_advantage_trainer/domain/learning/pilot_lesson.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reward adapter preserves XP for every score and first/repeat pass', () {
    const adapter = PilotRewardAdapter();
    for (var correct = 0; correct <= 10; correct++) {
      expect(
        adapter.xp(correct: correct, firstCompletion: false),
        correct * 10,
      );
      expect(
        adapter.xp(correct: correct, firstCompletion: true),
        correct * 10 + (correct >= 8 ? 50 : 0),
      );
    }
    expect(
      () => adapter.xp(correct: -1, firstCompletion: true),
      throwsArgumentError,
    );
    expect(
      () => adapter.xp(correct: 11, firstCompletion: true),
      throwsArgumentError,
    );
  });

  test(
    'performance preserves real counts and compares only matching older attempts',
    () {
      final lesson = PilotLesson.fromJson(
        (jsonDecode(
                      File(
                        'assets/content/en/pilot_lessons.json',
                      ).readAsStringSync(),
                    )
                    as List)
                .first
            as Map<String, Object?>,
      );
      final session = DecisionLessonSession(lesson)..begin();
      expect(() => LessonPerformance.fromSession(session), throwsStateError);
      for (var i = 0; i < lesson.scenarios.length; i++) {
        if (i == 3) session.useHint();
        session.answer(session.current.expected);
        session.next();
      }
      final original = LessonPerformance.fromSession(session);
      final restored = LessonPerformance.fromJson(original.toJson());
      expect(restored.correct, 10);
      expect(restored.unassisted, 9);
      expect(restored.comparableTo(original), isFalse);
      final newer = LessonPerformance.fromJson({
        ...original.toJson(),
        'attempt': 2,
        'correct': 8,
        'unassisted': 7,
      });
      expect(newer.comparableTo(original), isTrue);
      expect(newer.correct - original.correct, -2);
      expect(
        LessonPerformance.fromJson({
          ...newer.toJson(),
          'signature': 'different',
        }).comparableTo(original),
        isFalse,
      );
      for (final patch in <Map<String, Object?>>[
        {'attempt': 0},
        {'signature': ''},
        {'correct': 11},
        {'correct': -1},
        {'unassisted': -1},
        {'unassisted': 11},
      ]) {
        expect(
          () => LessonPerformance.fromJson({...original.toJson(), ...patch}),
          throwsFormatException,
        );
      }
    },
  );
}
