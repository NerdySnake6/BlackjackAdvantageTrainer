/// Held-out lesson checks. No hints or feedback are exposed before submission.
library;

import 'dart:convert';

import '../blackjack_engine/card.dart';
import '../blackjack_engine/game_rules.dart';
import 'pilot_lesson.dart';
import 'mastery.dart';

class MasteryTask {
  MasteryTask(this.id, List<String> ranks, this.expected, {String? dealer})
    : cards = List.unmodifiable(
        ranks.indexed.map((r) => PilotScenario.cardFromLabel(r.$2, r.$1)),
      ),
      dealer = dealer == null ? null : PilotScenario.cardFromLabel(dealer, 3);

  final String id;
  final List<PlayingCard> cards;
  final PlayingCard? dealer;
  final String expected;
  bool get isCounting => dealer == null;
  Set<PlayerAction> get actions => cards.length == 2
      ? const {
          PlayerAction.hit,
          PlayerAction.stand,
          PlayerAction.doubleDown,
          PlayerAction.surrender,
        }
      : const {PlayerAction.hit, PlayerAction.stand};
  bool accepts(String value) => isCounting
      ? int.tryParse(value) != null && int.parse(value).abs() <= cards.length
      : actions.any((a) => a.name == value);
}

/// Two disjoint forms per pilot skill; exhausted forms cannot certify repeats.
class MasteryCheckBank {
  static const formCount = 2;
  static const version = 1;
  static const dealerOrder = [
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    'A',
  ];

  static List<MasteryTask> tasks(String lessonId, int form) {
    if (form < 0 || form >= formCount) throw ArgumentError.value(form);
    final prefix = '$lessonId-check-v$version-$form';
    if (lessonId == 'hard-12') {
      return List.unmodifiable([
        for (var i = 0; i < 10; i++)
          MasteryTask(
            '$prefix-$i',
            form == 0 ? ['2', '3', '7'] : ['2', '2', '8'],
            i >= 2 && i <= 4 ? 'stand' : 'hit',
            dealer: dealerOrder[i],
          ),
      ]);
    }
    if (lessonId == 'soft-18') {
      return List.unmodifiable([
        for (var i = 0; i < 10; i++)
          MasteryTask(
            '$prefix-$i',
            form == 0 ? ['A', '2', '2', '3'] : ['A', 'A', 'A', '5'],
            i >= 7 ? 'hit' : 'stand',
            dealer: dealerOrder[i],
          ),
      ]);
    }
    if (lessonId != 'hi-lo-cancellation') throw ArgumentError.value(lessonId);
    const sequences = [
      ['2', 'Q', '3', '7'],
      ['A', '6', 'K', '8'],
      ['4', '5', 'J', '9'],
      ['K', 'A', '3', '7'],
      ['2', '4', '6', 'Q'],
      ['10', 'K', '5', 'A'],
      ['3', 'Q', '8', 'A', '6'],
      ['9', '2', 'K', '7', '4'],
      ['5', 'A', 'J', '8', 'Q'],
      ['6', '3', '2', '9', 'K'],
      ['Q', '4', '8', '2'],
      ['3', 'A', '9', 'K'],
      ['6', 'J', '5', '7'],
      ['10', '2', 'Q', '8'],
      ['5', '3', 'K', '4'],
      ['A', 'J', '6', 'Q'],
      ['7', '4', '10', '2', 'K'],
      ['A', '5', '9', '6', '3'],
      ['Q', '7', 'K', '4', 'J'],
      ['2', '8', '5', '6', 'A'],
    ];
    const answers = [
      1,
      -1,
      1,
      -1,
      2,
      -2,
      0,
      1,
      -2,
      2,
      1,
      -1,
      1,
      -1,
      2,
      -2,
      0,
      2,
      -2,
      2,
    ];
    return List.unmodifiable([
      for (var i = 0; i < 10; i++)
        MasteryTask(
          '$prefix-$i',
          sequences[form * 10 + i],
          '${answers[form * 10 + i]}',
        ),
    ]);
  }
}

class MasteryCheckSession {
  MasteryCheckSession(this.lessonId, {this.form = 0})
    : tasks = MasteryCheckBank.tasks(lessonId, form);

  factory MasteryCheckSession.restore(String id, Map<String, Object?> json) {
    try {
      final session = MasteryCheckSession(id, form: json['form']! as int);
      if (json['signature'] != session.signature) {
        throw const FormatException('Changed check');
      }
      session._answers.addAll((json['answers']! as List).cast<String>());
      session._revealed = json['revealed']! as int;
      session._count = json['count']! as int;
      if (session._answers.length > session.tasks.length ||
          session._revealed < 0 ||
          session._revealed > session.current.cards.length ||
          session._count.abs() > session.current.cards.length ||
          (session.complete &&
              (session._revealed != 0 || session._count != 0)) ||
          (session._revealed < session.current.cards.length &&
              session._count != 0) ||
          (!session.current.isCounting &&
              (session._revealed != 0 || session._count != 0))) {
        throw const FormatException('Invalid check state');
      }
      for (var i = 0; i < session._answers.length; i++) {
        if (!session.tasks[i].accepts(session._answers[i])) {
          throw const FormatException('Invalid check answer');
        }
      }
      return session;
    } on TypeError {
      throw const FormatException('Invalid check field');
    } on ArgumentError {
      throw const FormatException('Invalid check form');
    }
  }

  final String lessonId;
  final int form;
  final List<MasteryTask> tasks;
  final List<String> _answers = [];
  int _revealed = 0;
  int _count = 0;
  int get index => _answers.length;
  bool get complete => index == tasks.length;
  MasteryTask get current => tasks[complete ? tasks.length - 1 : index];
  int get revealed => _revealed;
  int get count => _count;
  List<String> get answers => List.unmodifiable(_answers);
  int get correct =>
      _answers.indexed.where((e) => e.$2 == tasks[e.$1].expected).length;
  double get score => correct / tasks.length;
  // A narrow lesson check is not the 100-decision strategy/whole-deck certificate.
  bool get passed =>
      complete &&
      const MasteryCalculator().checkpointPassed(
        correctAnswers: correct,
        totalAnswers: tasks.length,
      );
  bool get canAnswer =>
      !complete && (!current.isCounting || revealed == current.cards.length);
  String get signature => jsonEncode({
    'version': MasteryCheckBank.version,
    'lesson': lessonId,
    'form': form,
    'tasks': [
      for (final t in tasks)
        [
          t.id,
          t.cards.map((c) => c.rank.label).toList(),
          t.dealer?.rank.label,
          t.expected,
        ],
    ],
  });

  void reveal() {
    if (complete || !current.isCounting || revealed == current.cards.length) {
      throw StateError('No card');
    }
    _revealed++;
  }

  void adjust(int delta) {
    if (!canAnswer || !current.isCounting || delta.abs() != 1) {
      throw StateError('No count input');
    }
    _count = (_count + delta).clamp(
      -current.cards.length,
      current.cards.length,
    );
  }

  void answer(String answer) {
    if (!canAnswer || !current.accepts(answer)) {
      throw StateError('Answer unavailable');
    }
    _answers.add(current.isCounting ? int.parse(answer).toString() : answer);
    _count = 0;
    _revealed = 0;
  }

  Map<String, Object?> toJson() => {
    'signature': signature,
    'form': form,
    'answers': List<String>.of(_answers),
    'revealed': revealed,
    'count': count,
  };
}
