/// Learn-only repeatable review; evidence is separate from mastery and XP.
library;

import 'pilot_lesson.dart';
import 'lesson_format.dart';

class LearnReviewSchedule {
  const LearnReviewSchedule({
    required this.dueAt,
    this.step = 0,
    this.runs = 0,
  });
  factory LearnReviewSchedule.fromJson(Map<String, Object?> json) {
    try {
      final schedule = LearnReviewSchedule(
        dueAt: DateTime.parse(json['dueAt']! as String),
        step: json['step']! as int,
        runs: json['runs']! as int,
      );
      if (schedule.step < 0 || schedule.step > 4 || schedule.runs < 0) {
        throw const FormatException('Invalid Learn review schedule');
      }
      return schedule;
    } on TypeError {
      throw const FormatException('Invalid Learn review field');
    }
  }
  static const intervals = [1, 3, 7, 14, 30];
  final DateTime dueAt;
  final int step;
  final int runs;
  LearnReviewSchedule answered({required bool correct, required DateTime now}) {
    final next = correct ? (step + 1).clamp(0, 4) : 0;
    return LearnReviewSchedule(
      dueAt: now.add(Duration(days: intervals[next])),
      step: next,
      runs: runs + 1,
    );
  }

  Map<String, Object?> toJson() => {
    'dueAt': dueAt.toIso8601String(),
    'step': step,
    'runs': runs,
  };
}

class LearnReviewSession {
  LearnReviewSession(this.lesson, {this.attempt = 0})
    : task = lesson.scenarios
          .where((s) => s.stage == LessonMissionStage.independent)
          .toList()[attempt % 5] {
    if (attempt < 0) throw ArgumentError.value(attempt);
  }
  factory LearnReviewSession.restore(
    PilotLesson lesson,
    Map<String, Object?> json,
  ) {
    try {
      final session = LearnReviewSession(
        lesson,
        attempt: json['attempt']! as int,
      );
      if (json['signature'] != lesson.resumeSignature ||
          json['task'] != session.task.id) {
        throw const FormatException('Changed Learn review');
      }
      session._revealed = json['revealed']! as int;
      session._input = json['input']! as int;
      session._answer = json['answer'] as String?;
      if (session.revealed < 0 ||
          session.revealed > session.task.revealLimit ||
          (!session.task.requiresReveal && session.revealed != 0) ||
          (session.task.chunked &&
              session.revealed != 0 &&
              session.revealed != session.task.cards.length) ||
          session.input < session.task.minimumInput ||
          session.input > session.task.maximumInput ||
          (!session.task.usesNumber &&
              session.input != session.task.initialCount) ||
          (session.revealed < session.task.revealLimit &&
              session.input != session.task.initialCount) ||
          (session.complete &&
              (!session.task.accepts(session.answer!) ||
                  (session.task.requiresReveal &&
                      session.revealed != session.task.revealLimit)))) {
        throw const FormatException('Invalid Learn review state');
      }
      return session;
    } on TypeError {
      throw const FormatException('Invalid Learn review field');
    } on ArgumentError {
      throw const FormatException('Invalid Learn review attempt');
    }
  }
  final PilotLesson lesson;
  final PilotScenario task;
  final int attempt;
  int _revealed = 0;
  late int _input = task.initialCount;
  String? _answer;
  int get revealed => _revealed;
  int get input => _input;
  String? get answer => _answer;
  bool get complete => _answer != null;
  bool get correct => answer == task.expected;
  bool get canAnswer =>
      !complete && (!task.requiresReveal || revealed == task.revealLimit);
  void reveal() {
    if (complete || !task.requiresReveal || revealed == task.revealLimit) {
      throw StateError('No review card');
    }
    _revealed += task.chunked ? task.cards.length : 1;
  }

  void adjust(int delta) {
    if (!canAnswer || !task.usesNumber || delta.abs() != 1) {
      throw StateError('No review input');
    }
    _input = (_input + delta).clamp(task.minimumInput, task.maximumInput);
  }

  void submit(String value) {
    if (!canAnswer || !task.accepts(value)) {
      throw StateError('No review answer');
    }
    _answer = value;
  }

  Map<String, Object?> toJson() => {
    'signature': lesson.resumeSignature,
    'task': task.id,
    'attempt': attempt,
    'revealed': revealed,
    'input': input,
    'answer': answer,
  };
}
