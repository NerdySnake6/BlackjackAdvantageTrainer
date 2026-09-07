/// Resumable authored lesson flow with first-answer scoring and correction.
library;

import 'lesson_format.dart';
import 'lesson_adaptation.dart';
import 'pilot_lesson.dart';

enum DecisionLessonPhase { theory, decision, coaching, result }

class DecisionLessonSession {
  DecisionLessonSession(this.lesson, {this.attempt = 1, int? adaptiveSeed})
    : adaptiveSeed =
          adaptiveSeed ??
          (attempt - 1) % (AdaptiveExampleGenerator.maxSeed + 1) {
    if (attempt < 1) throw ArgumentError.value(attempt, 'attempt');
    if (this.adaptiveSeed < 0 ||
        this.adaptiveSeed > AdaptiveExampleGenerator.maxSeed) {
      throw ArgumentError.value(this.adaptiveSeed, 'adaptiveSeed');
    }
  }

  factory DecisionLessonSession.restore(
    PilotLesson lesson,
    Map<String, Object?> json,
  ) {
    try {
      return DecisionLessonSession._restore(lesson, json);
    } on TypeError {
      throw const FormatException('Invalid pilot session field type');
    } on ArgumentError {
      throw const FormatException('Invalid pilot session field value');
    }
  }

  static DecisionLessonSession _restore(
    PilotLesson lesson,
    Map<String, Object?> json,
  ) {
    final session = DecisionLessonSession(
      lesson,
      attempt: json['attempt']! as int,
      adaptiveSeed: json['adaptiveSeed'] as int? ?? 0,
    );
    final order = json['order']! as List;
    if ((json['adaptiveGeneratorVersion'] != null &&
            json['adaptiveGeneratorVersion'] !=
                AdaptiveExampleGenerator.version) ||
        json['schema'] is! int ||
        (json['schema'] != 1 && json['schema'] != 2) ||
        (json['schema'] == 2 &&
            json['contentSignature'] != lesson.resumeSignature) ||
        json['lessonId'] != lesson.id ||
        json['version'] != lesson.version ||
        order.length != lesson.scenarios.length ||
        !order.indexed.every(
          (entry) => entry.$2 == lesson.scenarios[entry.$1].id,
        )) {
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
    session._adaptiveAnswer = json['adaptiveAnswer'] as String?;
    session._adaptiveCount = json['adaptiveCount'] as int? ?? 0;
    session._validate();
    return session;
  }

  final PilotLesson lesson;
  final int attempt;
  final int adaptiveSeed;
  DecisionLessonPhase _phase = DecisionLessonPhase.theory;
  int _index = 0;
  int _revealed = 0;
  int? _countInput;
  bool _hint = false;
  bool _corrected = false;
  final List<String> _answers = [];
  final List<bool> _hints = [];
  int? _awardedXp;
  String? _adaptiveAnswer;
  int _adaptiveCount = 0;

  LessonAdaptation? get adaptation =>
      LessonAdaptation.select(lesson, _answers, _hints, seed: adaptiveSeed);
  String? get adaptiveAnswer => _adaptiveAnswer;
  int get adaptiveCount => _adaptiveCount;
  bool get isAdaptiveBoundary =>
      _phase == DecisionLessonPhase.coaching &&
      _corrected &&
      current.stage == LessonMissionStage.practice &&
      !isLastTask &&
      lesson.scenarios[_index + 1].stage == LessonMissionStage.independent;

  void answerAdaptive(String answer) {
    final plan = adaptation;
    if (!isAdaptiveBoundary ||
        plan == null ||
        _adaptiveAnswer != null ||
        !plan.example.accepts(answer)) {
      throw StateError('Adaptive answer unavailable');
    }
    _adaptiveAnswer = plan.example.isCounting
        ? int.parse(answer).toString()
        : answer;
  }

  void adjustAdaptiveCount(int delta) {
    final plan = adaptation;
    if (!isAdaptiveBoundary ||
        plan == null ||
        !plan.example.isCounting ||
        _adaptiveAnswer != null ||
        delta.abs() != 1) {
      throw StateError('Adaptive count input unavailable');
    }
    _adaptiveCount = (_adaptiveCount + delta).clamp(
      -plan.example.cards.length,
      plan.example.cards.length,
    );
  }

  DecisionLessonPhase get phase => _phase;
  int get index => _index;
  int get revealed => _revealed;
  int get countInput => _countInput ?? current.initialCount;
  bool get hintUsed => _hint;
  bool get corrected => _corrected;
  int? get awardedXp => _awardedXp;
  PilotScenario get current => lesson.scenarios[_index];
  bool get isWarmup => !current.isEvaluated;
  bool get isIndependent => !current.allowsHint;
  bool get isLastTask => _index == lesson.scenarios.length - 1;
  int get taskNumber =>
      isWarmup ? _index + 1 : _index + 1 - lesson.introductionCount;
  int get taskCount =>
      isWarmup ? lesson.introductionCount : lesson.evaluatedCount;
  String? get firstAnswer => _answers.length > _index ? _answers[_index] : null;
  bool get canAnswer =>
      (_phase == DecisionLessonPhase.decision ||
          (_phase == DecisionLessonPhase.coaching && !_corrected)) &&
      (!current.requiresReveal || _revealed == current.cards.length);
  int get correctAnswers => [
    for (var i = 0; i < _answers.length; i++)
      if (lesson.scenarios[i].isEvaluated &&
          _answers[i] == lesson.scenarios[i].expected)
        i,
  ].length;
  int get unassistedAnswers => [
    for (var i = 0; i < _answers.length; i++)
      if (lesson.scenarios[i].isEvaluated &&
          _answers[i] == lesson.scenarios[i].expected &&
          !_hints[i])
        i,
  ].length;
  int get evaluatedAnswers =>
      lesson.scenarios.take(_answers.length).where((s) => s.isEvaluated).length;
  int get independentAnswers => lesson.scenarios
      .take(_answers.length)
      .where((s) => s.stage == LessonMissionStage.independent)
      .length;
  int get independentCorrectAnswers => [
    for (var i = 0; i < _answers.length; i++)
      if (lesson.scenarios[i].stage == LessonMissionStage.independent &&
          _answers[i] == lesson.scenarios[i].expected)
        i,
  ].length;
  double get score =>
      evaluatedAnswers == 0 ? 0 : correctAnswers / evaluatedAnswers;
  bool get passed => lesson.scoring.passes(correctAnswers);
  int get stars => lesson.scoring.stars(
    correct: correctAnswers,
    unassisted: unassistedAnswers,
  );

  void begin() {
    if (_phase != DecisionLessonPhase.theory) {
      throw StateError('Theory has already been completed');
    }
    _phase = DecisionLessonPhase.decision;
  }

  void reveal() {
    if (_phase != DecisionLessonPhase.decision ||
        !current.requiresReveal ||
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
    if (!canAnswer || !current.usesNumber || delta.abs() != 1) {
      throw StateError('Count input unavailable');
    }
    _countInput = (countInput + delta).clamp(
      current.minimumInput,
      current.maximumInput,
    );
  }

  void next() {
    if (_phase != DecisionLessonPhase.coaching || !_corrected) {
      throw StateError('Correct this task before continuing');
    }
    if (isLastTask) {
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
    'schema': 2,
    'contentSignature': lesson.resumeSignature,
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
    'adaptiveAnswer': _adaptiveAnswer,
    'adaptiveCount': _adaptiveCount,
    'adaptiveSeed': adaptiveSeed,
    'adaptiveGeneratorVersion': AdaptiveExampleGenerator.version,
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
        (!current.requiresReveal && _revealed != 0) ||
        (_countInput != null &&
            (!current.usesNumber ||
                _revealed != current.cards.length ||
                _countInput! < current.minimumInput ||
                _countInput! > current.maximumInput)) ||
        (answered &&
            current.requiresReveal &&
            _revealed != current.cards.length) ||
        (_phase == DecisionLessonPhase.theory &&
            (_index != 0 || _revealed != 0 || _hint)) ||
        (!answered && _corrected) ||
        (answered &&
            (_hint != _hints[_index] ||
                (firstAnswer == current.expected && !_corrected))) ||
        (_phase == DecisionLessonPhase.result &&
            (!isLastTask || !_corrected)) ||
        (_awardedXp != null &&
            (_phase != DecisionLessonPhase.result || _awardedXp! < 0)) ||
        (isIndependent && _hint)) {
      throw const FormatException('Invalid pilot session state');
    }
    for (var i = 0; i < _answers.length; i++) {
      if (!lesson.scenarios[i].accepts(_answers[i]) ||
          (!lesson.scenarios[i].allowsHint && _hints[i])) {
        throw const FormatException('Invalid pilot answer');
      }
    }
    final plan = adaptation;
    if ((_adaptiveAnswer != null &&
            (plan == null || !plan.example.accepts(_adaptiveAnswer!))) ||
        (_adaptiveCount != 0 &&
            (plan == null ||
                !plan.example.isCounting ||
                _adaptiveCount.abs() > plan.example.cards.length))) {
      throw const FormatException('Invalid adaptive practice state');
    }
  }
}
