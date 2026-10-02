/// Saved three-deck Hi-Lo evidence with intermediate checks and active time.
library;

import 'dart:math';

import '../blackjack_engine/card.dart';

class CountCertificationSession {
  CountCertificationSession({required this.seed, this.attempt = 1})
    : orders = List.unmodifiable([
        for (var i = 0; i < 3; i++)
          List<int>.unmodifiable(
            List<int>.generate(52, (j) => j)..shuffle(Random(seed + i)),
          ),
      ]) {
    if (seed < 0 || seed > 0x7fffffff || attempt < 1) {
      throw ArgumentError('Invalid counting attempt');
    }
  }

  CountCertificationSession._(this.seed, this.attempt, this.orders);

  factory CountCertificationSession.restore(Map<String, Object?> json) {
    try {
      if (json['version'] != 1) {
        throw const FormatException('Unknown count check');
      }
      final session =
          CountCertificationSession._(
              json['seed']! as int,
              json['attempt']! as int,
              List.unmodifiable(
                (json['orders']! as List).map(
                  (o) => List<int>.unmodifiable((o as List).cast<int>()),
                ),
              ),
            )
            .._level = json['level']! as int
            .._revealed = json['revealed']! as int
            .._input = json['input']! as int
            .._elapsedMs = json['elapsedMs']! as int
            .._started = json['started']! as bool
            .._failed = json['failed']! as bool;
      session._answers.addAll((json['answers']! as List).cast<int>());
      for (final record in json['completed']! as List) {
        final data = (record as Map).cast<String, Object?>();
        session._completed.add((
          List<int>.unmodifiable((data['answers'] as List).cast<int>()),
          data['elapsedMs'] as int,
        ));
      }
      session._validate();
      return session;
    } on TypeError {
      throw const FormatException('Invalid count field');
    } on RangeError {
      throw const FormatException('Invalid count range');
    }
  }

  static const limits = [60, 45, 30];
  static const checkpoints = [8, 16, 24, 32, 40, 48, 52];
  final int seed;
  final int attempt;
  final List<List<int>> orders;
  final List<(List<int>, int)> _completed = [];
  final List<int> _answers = [];
  int _level = 0;
  int _revealed = 0;
  int _input = 0;
  int _elapsedMs = 0;
  bool _started = false;
  bool _failed = false;

  int get level => _level;
  int get revealed => _revealed;
  int get input => _input;
  int get elapsedMs => _elapsedMs;
  bool get started => _started;
  bool get failed => _failed;
  bool get passed => level == 3;
  bool get active => started && !failed && !passed;
  int get limitSeconds => limits[level.clamp(0, 2)];
  bool get needsAnswer => active && checkpoints[_answers.length] == revealed;
  List<int> get answers => List.unmodifiable(_answers);
  List<PlayingCard> get cards =>
      List.unmodifiable([for (final id in orders[level.clamp(0, 2)]) card(id)]);
  static PlayingCard card(int id) => PlayingCard(
    deckIndex: 0,
    rank: CardRank.values[id % 13],
    suit: CardSuit.values[id ~/ 13],
  );
  int _expected(int level, int exposed) =>
      orders[level].take(exposed).fold(0, (sum, id) => sum + card(id).hiLoTag);

  void begin() {
    if (started || failed || passed) throw StateError('Count deck unavailable');
    _started = true;
  }

  void addTime(int milliseconds) {
    if (milliseconds < 0) throw ArgumentError.value(milliseconds);
    if (!active) return;
    _elapsedMs += milliseconds;
    if (_elapsedMs > limitSeconds * 1000) {
      _failed = true;
      _input = 0;
    }
  }

  void reveal() {
    if (!active || needsAnswer) throw StateError('No card available');
    _revealed++;
  }

  void adjust(int delta) {
    if (!needsAnswer || delta.abs() != 1) throw StateError('No count input');
    _input = (_input + delta).clamp(-20, 20);
  }

  void answer() {
    if (!needsAnswer) throw StateError('No checkpoint');
    _answers.add(input);
    if (input != _expected(level, revealed)) {
      _failed = true;
    } else if (revealed == 52) {
      _completed.add((List<int>.unmodifiable(_answers), elapsedMs));
      _level++;
      _revealed = 0;
      _elapsedMs = 0;
      _started = false;
      _answers.clear();
    }
    _input = 0;
  }

  Map<String, Object?> toJson() => {
    'version': 1,
    'seed': seed,
    'attempt': attempt,
    'orders': orders,
    'level': level,
    'revealed': revealed,
    'input': input,
    'elapsedMs': elapsedMs,
    'started': started,
    'failed': failed,
    'answers': List<int>.of(_answers),
    'completed': [
      for (final (answers, time) in _completed)
        {'answers': answers, 'elapsedMs': time},
    ],
  };

  void _validate() {
    if (seed < 0 ||
        seed > 0x7fffffff ||
        attempt < 1 ||
        orders.length != 3 ||
        level < 0 ||
        level > 3 ||
        revealed < 0 ||
        revealed > 52 ||
        input.abs() > 20 ||
        elapsedMs < 0 ||
        _completed.length != level ||
        _answers.length > 7) {
      throw const FormatException('Invalid count check state');
    }
    for (final order in orders) {
      if (order.length != 52 ||
          order.toSet().length != 52 ||
          order.any((id) => id < 0 || id >= 52)) {
        throw const FormatException('Count deck must contain every card once');
      }
    }
    if (orders.map((o) => o.join(',')).toSet().length != 3) {
      throw const FormatException('Repeated count deck');
    }
    for (var stage = 0; stage < level; stage++) {
      final (answers, time) = _completed[stage];
      if (answers.length != 7 ||
          time < 0 ||
          time > limits[stage] * 1000 ||
          answers.indexed.any(
            (e) => e.$2 != _expected(stage, checkpoints[e.$1]),
          )) {
        throw const FormatException('Invalid completed count evidence');
      }
    }
    final wrong =
        _answers.isNotEmpty &&
        _answers.last !=
            _expected(level.clamp(0, 2), checkpoints[_answers.length - 1]);
    if (_answers.indexed.any(
          (e) =>
              checkpoints[e.$1] > revealed ||
              (e.$1 != _answers.length - 1 &&
                  e.$2 != _expected(level.clamp(0, 2), checkpoints[e.$1])),
        ) ||
        failed != (wrong || elapsedMs > limitSeconds * 1000) ||
        ((!started || passed) &&
            (revealed != 0 ||
                input != 0 ||
                elapsedMs != 0 ||
                _answers.isNotEmpty)) ||
        (active &&
            (_answers.length == 7 ||
                revealed > checkpoints[_answers.length])) ||
        (input != 0 && !needsAnswer)) {
      throw const FormatException('Invalid count checkpoint history');
    }
  }
}
