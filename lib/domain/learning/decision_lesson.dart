/// Resumable fixed pilot flow with first-answer scoring and explicit correction.
library;

import 'pilot_lesson.dart';

enum DecisionLessonPhase { theory, decision, coaching, result }

class DecisionLessonSession {
  DecisionLessonSession(this.lesson, {this.attempt = 1});

  factory DecisionLessonSession.restore(
    PilotLesson lesson,
    Map<String, Object?> json,
  ) {
    final session = DecisionLessonSession(
      lesson,
      attempt: json['attempt']! as int,
    );
    if (json['schema'] != 1 ||
        json['lessonId'] != lesson.id ||
        json['version'] != lesson.version ||
        (json['order']! as List).join('|') !=
            lesson.scenarios.map((item) => item.id).join('|')) {
      throw const FormatException('Incompatible pilot session');
    }
    session._phase = DecisionLessonPhase.values.byName(
      json['phase']! as String,
    );
    session._index = json['index']! as int;
    session._revealed = json['revealed']! as int;
    session._countInput = json['countInput'] as int?;
    session._hint = json['hint']! as bool;
    session._corrected = json['corrected']! as bool;
    session._answers.addAll((json['answers']! as List).cast<String>());
    session._hints.addAll((json['hints']! as List).cast<bool>());
    session._awardedXp = json['awardedXp'] as int?;
    session._validate();
    return session;
  }

  final PilotLesson lesson;
  final int attempt;
  DecisionLessonPhase _phase = DecisionLessonPhase.theory;
  int _index = 0;
  int _revealed = 0;
  int? _countInput;
  bool _hint = false;
  bool _corrected = false;
  final List<String> _answers = [];
  final List<bool> _hints = [];
  int? _awardedXp;

  DecisionLessonPhase get phase => _phase;
  int get index => _index;
  int get revealed => _revealed;
  int get countInput => _countInput ?? current.initialCount;
  bool get hintUsed => _hint;
  bool get corrected => _corrected;
  int? get awardedXp => _awardedXp;
  PilotScenario get current => lesson.scenarios[_index];
  bool get isWarmup => _index < 2;
  bool get isIndependent => _index >= 7;
  String? get firstAnswer => _answers.length > _index ? _answers[_index] : null;
  bool get canAnswer =>
      (_phase == DecisionLessonPhase.decision ||
          (_phase == DecisionLessonPhase.coaching && !_corrected)) &&
      (!current.isCounting || _revealed == current.cards.length);
  int get correctAnswers => [
    for (var i = 2; i < _answers.length; i++)
      if (_answers[i] == lesson.scenarios[i].expected) i,
  ].length;
  int get unassistedAnswers => [
    for (var i = 2; i < _answers.length; i++)
      if (_answers[i] == lesson.scenarios[i].expected && !_hints[i]) i,
  ].length;
  int get evaluatedAnswers => (_answers.length - 2).clamp(0, 10);
  double get score =>
      evaluatedAnswers == 0 ? 0 : correctAnswers / evaluatedAnswers;
  int get stars => correctAnswers < 8
      ? 0
      : correctAnswers == 8
      ? 1
      : correctAnswers == 10 && unassistedAnswers == 10
      ? 3
      : 2;

  void begin() {
    if (_phase != DecisionLessonPhase.theory) {
      throw StateError('Theory has already been completed');
    }
    _phase = DecisionLessonPhase.decision;
  }

  void reveal() {
    if (_phase != DecisionLessonPhase.decision ||
        !current.isCounting ||
        _revealed == current.cards.length) {
      throw StateError('No card to reveal');
    }
    _revealed++;
  }

  void useHint() {
    if (_phase != DecisionLessonPhase.decision || isIndependent) {
      throw StateError('Hints are unavailable');
    }
    _hint = true;
  }

  void answer(String answer) {
    if (!canAnswer || !current.accepts(answer)) {
      throw StateError('Answer unavailable');
    }
    if (_phase == DecisionLessonPhase.decision) {
      _answers.add(answer);
      _hints.add(_hint);
    }
    _corrected = answer == current.expected;
    _phase = DecisionLessonPhase.coaching;
  }

  void adjustCount(int delta) {
    if (!canAnswer || !current.isCounting || delta.abs() != 1) {
      throw StateError('Count input unavailable');
    }
    _countInput = (countInput + delta).clamp(
      current.initialCount - current.cards.length,
      current.initialCount + current.cards.length,
    );
  }

  void next() {
    if (_phase != DecisionLessonPhase.coaching || !_corrected) {
      throw StateError('Correct this task before continuing');
    }
    if (_index == lesson.scenarios.length - 1) {
      _phase = DecisionLessonPhase.result;
    } else {
      _index++;
      _phase = DecisionLessonPhase.decision;
      _revealed = 0;
      _countInput = null;
      _hint = false;
      _corrected = false;
    }
  }

  void recordReward(int xp) {
    if (_phase != DecisionLessonPhase.result || _awardedXp != null || xp < 0) {
      throw StateError('Reward unavailable');
    }
    _awardedXp = xp;
  }

  Map<String, Object?> toJson() => {
    'schema': 1,
    'lessonId': lesson.id,
    'version': lesson.version,
    'order': lesson.scenarios.map((item) => item.id).toList(),
    'attempt': attempt,
    'phase': _phase.name,
    'index': _index,
    'revealed': _revealed,
    'countInput': _countInput,
    'hint': _hint,
    'corrected': _corrected,
    'answers': List<String>.of(_answers),
    'hints': List<bool>.of(_hints),
    'awardedXp': _awardedXp,
  };

  void _validate() {
    final answered =
        _phase == DecisionLessonPhase.coaching ||
        _phase == DecisionLessonPhase.result;
    if (attempt < 1 ||
        _index < 0 ||
        _index >= lesson.scenarios.length ||
        _answers.length != _index + (answered ? 1 : 0) ||
        _hints.length != _answers.length ||
        _revealed < 0 ||
        _revealed > current.cards.length ||
        (!current.isCounting && _revealed != 0) ||
        (_countInput != null &&
            (!current.isCounting ||
                _revealed != current.cards.length ||
                (_countInput! - current.initialCount).abs() >
                    current.cards.length)) ||
        (answered && current.isCounting && _revealed != current.cards.length) ||
        (_phase == DecisionLessonPhase.theory &&
            (_index != 0 || _revealed != 0 || _hint)) ||
        (!answered && _corrected) ||
        (_phase == DecisionLessonPhase.result &&
            (_index != 11 || !_corrected)) ||
        (_awardedXp != null &&
            (_phase != DecisionLessonPhase.result || _awardedXp! < 0)) ||
        (isIndependent && _hint)) {
      throw const FormatException('Invalid pilot session state');
    }
    for (var i = 0; i < _answers.length; i++) {
      if (!lesson.scenarios[i].accepts(_answers[i]) || (i >= 7 && _hints[i])) {
        throw const FormatException('Invalid pilot answer');
      }
    }
  }
}
