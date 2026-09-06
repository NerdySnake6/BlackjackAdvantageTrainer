/// Short, untimed Learn placement check; it recommends practice but never certifies mastery.
library;

enum DiagnosticSkill { strategy, runningCount }

enum DiagnosticRecommendation { strategy, runningCount, combined }

class DiagnosticQuestion {
  const DiagnosticQuestion({
    required this.id,
    required this.skill,
    required this.correctOption,
  });

  final String id;
  final DiagnosticSkill skill;
  final int correctOption;
}

class DiagnosticSession {
  DiagnosticSession()
    : questions = const [
        DiagnosticQuestion(
          id: 'strategy-boundary',
          skill: DiagnosticSkill.strategy,
          correctOption: 1,
        ),
        DiagnosticQuestion(
          id: 'strategy-double',
          skill: DiagnosticSkill.strategy,
          correctOption: 0,
        ),
        DiagnosticQuestion(
          id: 'count-tags',
          skill: DiagnosticSkill.runningCount,
          correctOption: 0,
        ),
        DiagnosticQuestion(
          id: 'count-continuity',
          skill: DiagnosticSkill.runningCount,
          correctOption: 2,
        ),
      ];

  final List<DiagnosticQuestion> questions;
  final List<int?> _answers = [null, null, null, null];

  int get currentIndex => _answers.indexWhere((answer) => answer == null);
  bool get isComplete => currentIndex == -1;
  int? get currentAnswer => isComplete ? null : _answers[currentIndex];
  int get strategyCorrect => _correct(DiagnosticSkill.strategy);
  int get runningCountCorrect => _correct(DiagnosticSkill.runningCount);

  DiagnosticRecommendation get recommendation {
    if (strategyCorrect > 0 && runningCountCorrect > 0) {
      return DiagnosticRecommendation.combined;
    }
    if (runningCountCorrect > 0) return DiagnosticRecommendation.runningCount;
    return DiagnosticRecommendation.strategy;
  }

  void answer(int option) {
    if (isComplete || option < 0 || option > 2) {
      throw StateError('Diagnostic answer unavailable');
    }
    _answers[currentIndex] = option;
  }

  void restart() {
    for (var i = 0; i < _answers.length; i++) {
      _answers[i] = null;
    }
  }

  List<int?> get answers => List.unmodifiable(_answers);

  int _correct(DiagnosticSkill skill) {
    var count = 0;
    for (var i = 0; i < questions.length; i++) {
      if (questions[i].skill == skill &&
          _answers[i] == questions[i].correctOption) {
        count++;
      }
    }
    return count;
  }
}
