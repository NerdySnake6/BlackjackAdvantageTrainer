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
      ? {
          PlayerAction.hit,
          PlayerAction.stand,
          PlayerAction.doubleDown,
          PlayerAction.surrender,
          if (cards[0].rank.blackjackValue == cards[1].rank.blackjackValue)
            PlayerAction.split,
        }
      : const {PlayerAction.hit, PlayerAction.stand};
  bool accepts(String value) => isCounting
      ? int.tryParse(value) != null && int.parse(value).abs() <= cards.length
      : actions.any((a) => a.name == value);
}

/// Two disjoint forms per supported skill; exhausted forms cannot certify repeats.
class MasteryCheckBank {
  static bool supports(String lessonId) => const {
    'hard-12',
    'soft-18',
    'hi-lo-cancellation',
    'mixed-basic-strategy',
  }.contains(lessonId);

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
    if (lessonId == 'mixed-basic-strategy') {
      return List.unmodifiable([
        for (final entry in _strategyCheckpointForms[form].indexed)
          MasteryTask(
            '$prefix-${entry.$1}',
            entry.$2.$1,
            entry.$2.$3,
            dealer: entry.$2.$2,
          ),
      ]);
    }
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
      (lessonId == 'mixed-basic-strategy'
          ? correct == 100
          : const MasteryCalculator().checkpointPassed(
              correctAnswers: correct,
              totalAnswers: tasks.length,
            ));
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

const _strategyCheckpointForms = <List<(List<String>, String, String)>>[
  [
    (['2', '2', '5', '7'], '7', 'hit'),
    (['6', '6'], 'A', 'hit'),
    (['2', '7', '7'], '2', 'stand'),
    (['4', '8'], '7', 'hit'),
    (['5', '9'], '2', 'stand'),
    (['A', '2', '4', '5'], '3', 'hit'),
    (['2', '2', '3'], '3', 'hit'),
    (['A', 'A'], 'A', 'split'),
    (['A', '8', '9'], '6', 'stand'),
    (['5', '10'], '10', 'surrender'),
    (['7', '7'], '9', 'hit'),
    (['A', 'A', 'A'], '5', 'hit'),
    (['A', 'A', '2', '6'], '9', 'stand'),
    (['A', 'A', '5'], '3', 'hit'),
    (['A', '9', '9'], '7', 'stand'),
    (['A', 'A', 'A', '6'], '7', 'stand'),
    (['10', '10'], '3', 'stand'),
    (['A', 'A', '6'], '6', 'stand'),
    (['4', '4', '6', '6'], '3', 'stand'),
    (['A', '2'], 'A', 'hit'),
    (['5', '5'], '7', 'doubleDown'),
    (['A', '5', '10'], '8', 'hit'),
    (['A', 'A', '6', '6'], '4', 'stand'),
    (['2', '2', '3', '4'], '4', 'hit'),
    (['A', '4', '6', '9'], '3', 'stand'),
    (['2', '2', '4'], '2', 'hit'),
    (['2', '4', '4', '5'], '4', 'stand'),
    (['A', '2'], '6', 'doubleDown'),
    (['3', '4', '4', '8'], '9', 'stand'),
    (['A', '2'], '2', 'hit'),
    (['A', 'A', '3', '8'], 'A', 'hit'),
    (['A', 'A', 'A'], '4', 'hit'),
    (['A', 'A', 'A', '3'], '7', 'hit'),
    (['A', 'A', 'A', '4'], '4', 'hit'),
    (['2', '3'], '4', 'hit'),
    (['2', '3', '6', '6'], '5', 'stand'),
    (['A', 'A', '6', '9'], '2', 'stand'),
    (['A', '7', '7'], '6', 'stand'),
    (['A', 'A', '2', '8'], '9', 'hit'),
    (['A', '2', '5'], '4', 'stand'),
    (['A', '3'], '5', 'doubleDown'),
    (['7', '7'], '5', 'split'),
    (['A', '4'], '6', 'doubleDown'),
    (['A', 'A'], '5', 'split'),
    (['2', '6'], '2', 'hit'),
    (['3', '3'], '5', 'split'),
    (['A', '4', '4'], '9', 'stand'),
    (['9', '9'], '4', 'split'),
    (['8', '8'], '3', 'split'),
    (['A', 'A', '2', '8'], '6', 'stand'),
    (['A', '9'], '3', 'stand'),
    (['A', '4'], '5', 'doubleDown'),
    (['8', '8'], '7', 'split'),
    (['3', '3', '3'], '9', 'hit'),
    (['2', '5'], '6', 'hit'),
    (['2', '3', '7', '7'], '8', 'stand'),
    (['6', '6'], '3', 'split'),
    (['7', '8'], '10', 'surrender'),
    (['2', '5', '6'], '10', 'hit'),
    (['7', '10'], '6', 'stand'),
    (['A', 'A', '2'], '7', 'hit'),
    (['A', '2', '6', '6'], '5', 'stand'),
    (['2', '2', '5', '5'], '3', 'stand'),
    (['2', '2', '3', '3'], '7', 'hit'),
    (['10', '10'], '5', 'stand'),
    (['A', 'A'], '4', 'split'),
    (['A', '2', '5'], '7', 'stand'),
    (['3', '3', '5'], '6', 'hit'),
    (['3', '4', '4', '4'], '4', 'stand'),
    (['4', '4'], '9', 'hit'),
    (['2', '4'], '9', 'hit'),
    (['A', 'A'], '8', 'split'),
    (['2', '3', '5', '9'], '4', 'stand'),
    (['A', 'A', '6'], '10', 'hit'),
    (['9', '9'], 'A', 'stand'),
    (['A', 'A', 'A', '6'], '6', 'stand'),
    (['A', 'A', '3'], '4', 'hit'),
    (['3', '3', '9'], '8', 'hit'),
    (['A', '3'], '8', 'hit'),
    (['6', '10'], 'A', 'surrender'),
    (['2', '4'], '3', 'hit'),
    (['A', '3', '3'], '5', 'hit'),
    (['3', '6', '6'], '2', 'stand'),
    (['2', '4', '4'], '4', 'hit'),
    (['4', '4'], '7', 'hit'),
    (['5', '5'], '2', 'doubleDown'),
    (['3', '5', '5', '5'], 'A', 'stand'),
    (['A', '3', '4'], '8', 'stand'),
    (['3', '3'], '7', 'split'),
    (['A', 'A', '4'], '4', 'hit'),
    (['A', '3', '8'], '5', 'stand'),
    (['A', '4', '8'], '2', 'stand'),
    (['A', '3', '3', '10'], '9', 'stand'),
    (['A', '2'], '9', 'hit'),
    (['A', '2', '4', '6'], '6', 'stand'),
    (['2', '3'], '9', 'hit'),
    (['2', '2', '8', '8'], '7', 'stand'),
    (['7', '10'], '3', 'stand'),
    (['4', '5'], '9', 'hit'),
    (['A', 'A'], '3', 'split'),
  ],
  [
    (['A', 'A'], '2', 'split'),
    (['A', 'A', '2', '4'], '5', 'stand'),
    (['A', '3'], '2', 'hit'),
    (['3', '3', '4', '5'], '9', 'hit'),
    (['A', 'A', '3', '3'], '7', 'stand'),
    (['3', '3'], '9', 'hit'),
    (['2', '2', '2'], '10', 'hit'),
    (['A', '3', '4', '8'], '10', 'hit'),
    (['A', 'A', 'A'], '7', 'hit'),
    (['A', '4', '4'], '7', 'stand'),
    (['A', '4', '10'], '3', 'stand'),
    (['2', '2', '4', '4'], '10', 'hit'),
    (['10', '10'], '9', 'stand'),
    (['2', '2', '4'], '7', 'hit'),
    (['A', '4', '4', '4'], '9', 'hit'),
    (['5', '6', '6'], '6', 'stand'),
    (['4', '5', '8'], '2', 'stand'),
    (['5', '5', '10'], '2', 'stand'),
    (['3', '3', '9'], '6', 'stand'),
    (['5', '5'], 'A', 'hit'),
    (['7', '7'], '2', 'split'),
    (['A', '6'], '4', 'doubleDown'),
    (['A', 'A', 'A', 'A'], '10', 'hit'),
    (['4', '5'], '5', 'doubleDown'),
    (['2', '3'], '6', 'hit'),
    (['A', 'A', '3', '9'], 'A', 'hit'),
    (['A', 'A', '3', '3'], '6', 'stand'),
    (['A', '5', '6', '6'], '2', 'stand'),
    (['A', '2'], '7', 'hit'),
    (['9', '9'], '2', 'split'),
    (['A', '3', '8'], 'A', 'hit'),
    (['2', '3'], '2', 'hit'),
    (['2', '3', '5', '5'], '3', 'stand'),
    (['A', '4', '5', '9'], '10', 'stand'),
    (['4', '4'], '10', 'hit'),
    (['3', '4'], '5', 'hit'),
    (['A', 'A', '4', '4'], '3', 'stand'),
    (['7', '7'], '4', 'split'),
    (['A', '2', '2'], '5', 'hit'),
    (['4', '6', '6'], '2', 'stand'),
    (['2', '3', '3', '7'], '10', 'hit'),
    (['A', '3', '4'], '7', 'stand'),
    (['2', '5'], '8', 'hit'),
    (['2', '3', '9'], '8', 'hit'),
    (['3', '5', '5'], '9', 'hit'),
    (['3', '4', '4', '7'], '8', 'stand'),
    (['2', '3', '3', '5'], '9', 'hit'),
    (['3', '3', '4', '10'], '9', 'stand'),
    (['2', '2', '6'], '7', 'hit'),
    (['3', '8', '8'], '5', 'stand'),
    (['5', '5'], '6', 'doubleDown'),
    (['3', '3', '7', '7'], '4', 'stand'),
    (['A', 'A', '7', '10'], '5', 'stand'),
    (['6', '6'], '4', 'split'),
    (['A', '3', '4'], '2', 'stand'),
    (['A', 'A'], '9', 'split'),
    (['3', '3', '8'], '5', 'stand'),
    (['A', 'A', 'A'], 'A', 'hit'),
    (['3', '3', '4'], '8', 'hit'),
    (['3', '4', '6', '7'], '2', 'stand'),
    (['A', '5'], '4', 'doubleDown'),
    (['2', '6'], '3', 'hit'),
    (['A', 'A', '4'], '6', 'hit'),
    (['A', '6', '6'], '2', 'stand'),
    (['A', 'A', 'A'], '2', 'hit'),
    (['3', '3'], '2', 'split'),
    (['A', '4'], '10', 'hit'),
    (['9', '9'], '3', 'split'),
    (['A', '6', '9'], '7', 'hit'),
    (['A', 'A', '2', '4'], '6', 'stand'),
    (['A', 'A', '4', '7'], '6', 'stand'),
    (['3', '3'], 'A', 'hit'),
    (['6', '6'], '5', 'split'),
    (['2', '6'], '7', 'hit'),
    (['A', '3', '4', '5'], '8', 'hit'),
    (['A', '2'], '8', 'hit'),
    (['A', '5'], '5', 'doubleDown'),
    (['3', '3'], '6', 'split'),
    (['3', '8'], '5', 'doubleDown'),
    (['2', '2', '2'], '6', 'hit'),
    (['3', '4', '4', '7'], '4', 'stand'),
    (['2', '2', '6', '8'], '6', 'stand'),
    (['A', '2', '2', '2'], '2', 'hit'),
    (['5', '7'], '7', 'hit'),
    (['4', '7'], '5', 'doubleDown'),
    (['7', '9'], '9', 'surrender'),
    (['A', 'A', '3', '4'], '4', 'stand'),
    (['A', 'A', '5', '8'], '5', 'stand'),
    (['8', '8'], '8', 'split'),
    (['4', '5', '9'], 'A', 'stand'),
    (['A', '2', '4'], '4', 'hit'),
    (['8', '8'], '2', 'split'),
    (['A', '5'], '10', 'hit'),
    (['A', '2', '7', '7'], 'A', 'stand'),
    (['10', '10'], '10', 'stand'),
    (['A', '2', '7'], '6', 'stand'),
    (['2', '2', '5'], '7', 'hit'),
    (['A', 'A', '5', '9'], '6', 'stand'),
    (['3', '3'], '4', 'split'),
    (['4', '4'], '8', 'hit'),
  ],
];
