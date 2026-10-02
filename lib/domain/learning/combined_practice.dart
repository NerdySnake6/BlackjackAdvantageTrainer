/// Repeatable weekly strategy/count practice using authored decision scenarios.
library;

import 'dart:convert';
import 'dart:math';

import '../blackjack_engine/card.dart';
import 'models.dart';
import 'pilot_lesson.dart';

class CombinedPracticeSession {
  CombinedPracticeSession(
    CourseCatalog catalog, {
    required this.week,
    this.attempt = 1,
    this.timed = false,
  }) : tasks = _select(catalog, week) {
    if (attempt < 1) throw ArgumentError.value(attempt);
  }

  static String weekOf(DateTime date) {
    final day = DateTime.utc(date.year, date.month, date.day);
    return day
        .subtract(Duration(days: day.weekday - 1))
        .toIso8601String()
        .substring(0, 10);
  }

  static List<PilotScenario> _select(CourseCatalog catalog, String week) {
    final date = DateTime.tryParse(week);
    if (date == null || weekOf(date) != week) throw ArgumentError.value(week);
    final random = Random(
      DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
          Duration.millisecondsPerDay,
    );
    final lessons = catalog.strategyLessons.toList()..shuffle(random);
    final selected = <PilotScenario>[];
    for (final lesson in lessons) {
      final choices = lesson.scenarios.where((s) => s.usesActions).toList()
        ..shuffle(random);
      selected.add(choices.first);
    }
    final extra =
        catalog.pilotLessons
            .expand((l) => l.scenarios)
            .where((s) => s.usesActions)
            .toList()
          ..shuffle(random);
    selected.add(extra.first);
    return List.unmodifiable(selected);
  }

  factory CombinedPracticeSession.restore(
    CourseCatalog catalog,
    Map<String, Object?> data,
  ) {
    try {
      final session = CombinedPracticeSession(
        catalog,
        week: data['week']! as String,
        attempt: data['attempt']! as int,
        timed: data['timed']! as bool,
      );
      if (data['signature'] != session.signature) {
        throw const FormatException('Changed practice');
      }
      session._revealed = data['revealed']! as int;
      session._input = data['input']! as int;
      session._decision = data['decision'] as String?;
      session._elapsedMs = data['elapsedMs']! as int;
      session._started = data['started']! as bool;
      session._feedback = data['feedback']! as bool;
      session._decisions.addAll((data['decisions']! as List).cast<String>());
      session._counts.addAll((data['counts']! as List).cast<int>());
      session._validate();
      return session;
    } on TypeError {
      throw const FormatException('Invalid practice field');
    } on ArgumentError {
      throw const FormatException('Invalid practice value');
    }
  }

  final String week;
  final int attempt;
  final bool timed;
  final List<PilotScenario> tasks;
  final List<String> _decisions = [];
  final List<int> _counts = [];
  int _revealed = 0;
  int _input = 0;
  int _elapsedMs = 0;
  String? _decision;
  bool _started = false;
  bool _feedback = false;
  int get index => _counts.length;
  bool get complete => index == tasks.length;
  bool get feedback => _feedback;
  bool get started => _started;
  bool get active => started && !complete && !feedback;
  PilotScenario get task =>
      tasks[complete
          ? tasks.length - 1
          : feedback
          ? index - 1
          : index];
  List<PlayingCard> get cards =>
      List.unmodifiable([...task.cards, task.dealer!]);
  int get revealed => _revealed;
  int get input => _input;
  String? get decision => _decision;
  int get elapsedMs => _elapsedMs;
  List<String> get decisions => List.unmodifiable(_decisions);
  List<int> get counts => List.unmodifiable(_counts);
  int expectedCount(int step) => tasks
      .take(step + 1)
      .fold(
        0,
        (sum, t) =>
            sum +
            [...t.cards, t.dealer!].fold(0, (n, card) => n + card.hiLoTag),
      );
  int get strategyCorrect =>
      _decisions.indexed.where((e) => e.$2 == tasks[e.$1].expected).length;
  int get countCorrect =>
      _counts.indexed.where((e) => e.$2 == expectedCount(e.$1)).length;
  int get bothCorrect => _counts.indexed
      .where(
        (e) =>
            e.$2 == expectedCount(e.$1) &&
            _decisions[e.$1] == tasks[e.$1].expected,
      )
      .length;
  int get bound => tasks.expand((t) => [...t.cards, t.dealer!]).length;
  String get signature => jsonEncode({
    'version': 1,
    'week': week,
    'tasks': [
      for (final t in tasks)
        [
          t.id,
          t.cards.map((c) => c.rank.label).toList(),
          t.dealer!.rank.label,
          t.expected,
          t.availableActions.map((a) => a.name).toList()..sort(),
          t.afterSplit,
        ],
    ],
  });
  void begin() {
    if (started) throw StateError('Already started');
    _started = true;
  }

  void reveal() {
    if (!active || decision != null || revealed == cards.length) {
      throw StateError('No card');
    }
    _revealed++;
  }

  void choose(String value) {
    if (!active ||
        revealed != cards.length ||
        decision != null ||
        !task.availableActions.any((a) => a.name == value)) {
      throw StateError('No decision');
    }
    _decision = value;
  }

  void adjust(int delta) {
    if (!active || decision == null || delta.abs() != 1) {
      throw StateError('No count input');
    }
    _input = (_input + delta).clamp(-bound, bound);
  }

  void answer() {
    if (!active || decision == null) throw StateError('No answer');
    _decisions.add(decision!);
    _counts.add(input);
    // Feedback keeps the just-answered scene until the learner continues.
    _revealed = 0;
    _feedback = !complete;
    if (complete) _decision = null;
  }

  void next() {
    if (!feedback || complete) throw StateError('No next task');
    _feedback = false;
    _decision = null;
    _input = expectedCount(index - 1);
  }

  void addTime(int milliseconds) {
    if (milliseconds < 0) throw ArgumentError.value(milliseconds);
    if (timed && active) _elapsedMs += milliseconds;
  }

  void _validate() {
    if (_counts.length != _decisions.length ||
        index > tasks.length ||
        revealed < 0 ||
        revealed > cards.length ||
        input.abs() > bound ||
        elapsedMs < 0 ||
        (!timed && elapsedMs != 0) ||
        (!started &&
            (index != 0 ||
                revealed != 0 ||
                decision != null ||
                input != 0 ||
                elapsedMs != 0)) ||
        (complete && (feedback || decision != null || revealed != 0)) ||
        (feedback &&
            (index == 0 || decision != _decisions.last || revealed != 0)) ||
        (!feedback &&
            decision != null &&
            (revealed != cards.length ||
                !task.availableActions.any((a) => a.name == decision)))) {
      throw const FormatException('Invalid practice state');
    }
    for (final e in _decisions.indexed) {
      if (!tasks[e.$1].availableActions.any((a) => a.name == e.$2) ||
          _counts[e.$1].abs() > bound) {
        throw const FormatException('Invalid practice answer');
      }
    }
  }

  Map<String, Object?> toJson() => {
    'signature': signature,
    'week': week,
    'attempt': attempt,
    'timed': timed,
    'started': started,
    'feedback': feedback,
    'revealed': revealed,
    'input': input,
    'decision': decision,
    'elapsedMs': elapsedMs,
    'decisions': List<String>.of(_decisions),
    'counts': List<int>.of(_counts),
  };
}
