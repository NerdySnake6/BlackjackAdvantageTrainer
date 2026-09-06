import 'package:blackjack_advantage_trainer/domain/learning/diagnostic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('diagnostic is four untimed questions and recommends a skill', () {
    final session = DiagnosticSession();
    expect(session.questions, hasLength(4));
    expect(session.isComplete, isFalse);
    expect(session.currentIndex, 0);
    session.answer(0);
    expect(session.currentIndex, 1);
    session.answer(0);
    session.answer(0);
    session.answer(2);
    expect(session.isComplete, isTrue);
    expect(session.strategyCorrect, 2);
    expect(session.runningCountCorrect, 2);
    expect(session.recommendation, DiagnosticRecommendation.combined);
    expect(session.answers, [0, 0, 0, 2]);
    expect(() => session.answer(0), throwsStateError);
  });

  test(
    'recommendation separates strategy and counting gaps without certification',
    () {
      final strategyOnly = DiagnosticSession()
        ..answer(0)
        ..answer(0)
        ..answer(1)
        ..answer(1);
      expect(strategyOnly.recommendation, DiagnosticRecommendation.strategy);
      expect(strategyOnly.strategyCorrect, 2);
      expect(strategyOnly.runningCountCorrect, 0);

      final countOnly = DiagnosticSession()
        ..answer(1)
        ..answer(1)
        ..answer(0)
        ..answer(2);
      expect(countOnly.recommendation, DiagnosticRecommendation.runningCount);
      expect(countOnly.strategyCorrect, 0);
      expect(countOnly.runningCountCorrect, 2);
      expect(DiagnosticSession().answers, [null, null, null, null]);
    },
  );

  test('invalid options and restart are handled explicitly', () {
    final session = DiagnosticSession();
    expect(() => session.answer(-1), throwsStateError);
    expect(() => session.answer(3), throwsStateError);
    session.answer(1);
    session.restart();
    expect(session.currentIndex, 0);
    expect(session.answers, [null, null, null, null]);
    expect(() => session.answers[0] = 1, throwsUnsupportedError);
  });
}
