/// Deterministic, unscored support between practice and independent blocks.
library;

import '../blackjack_engine/card.dart';
import '../blackjack_engine/game_rules.dart';
import 'lesson_format.dart';
import 'pilot_lesson.dart';

enum AdaptiveFocus {
  hardStand,
  hardHit,
  softDouble,
  softStand,
  softHit,
  softFallback,
  countResult,
  extraCard,
}

class AdaptiveExample {
  AdaptiveExample(List<String> ranks, this.expected, {String? dealer})
    : cards = List.unmodifiable(
        ranks.indexed.map((e) => PilotScenario.cardFromLabel(e.$2, e.$1)),
      ),
      dealer = dealer == null
          ? null
          : PilotScenario.cardFromLabel(dealer, ranks.length);
  final List<PlayingCard> cards;
  final PlayingCard? dealer;
  final String expected;
  bool get isCounting => dealer == null;
  Set<PlayerAction> get actions => {
    PlayerAction.hit,
    PlayerAction.stand,
    if (cards.length == 2) PlayerAction.doubleDown,
  };
  bool accepts(String value) => isCounting
      ? int.tryParse(value) != null && int.parse(value).abs() <= cards.length
      : actions.any((action) => action.name == value);
}

class LessonAdaptation {
  LessonAdaptation._(this.focus, this.example);
  final AdaptiveFocus focus;
  final AdaptiveExample example;
  bool get isChallenge => focus == AdaptiveFocus.extraCard;

  /// Counts observed error categories; a final RC alone cannot reveal its cause.
  static LessonAdaptation? select(
    PilotLesson lesson,
    List<String> answers,
    List<bool> hints,
  ) {
    final practice = lesson.scenarios.indexed
        .where((e) => e.$2.stage == LessonMissionStage.practice)
        .toList();
    if (practice.isEmpty || answers.length <= practice.last.$1) return null;
    if (!const {
      'hard-12',
      'soft-18',
      'hi-lo-cancellation',
    }.contains(lesson.id)) {
      return null;
    }
    final errors = <AdaptiveFocus, int>{};
    var unassisted = 0;
    for (final (index, task) in practice) {
      if (answers[index] == task.expected) {
        if (!hints[index]) unassisted++;
        continue;
      }
      final focus = _category(lesson.id, task);
      errors[focus] = (errors[focus] ?? 0) + 1;
    }
    if (unassisted == practice.length) {
      return LessonAdaptation._(AdaptiveFocus.extraCard, switch (lesson.id) {
        'hard-12' => AdaptiveExample(['3', '4', '5'], 'stand', dealer: '4'),
        'soft-18' => AdaptiveExample(['A', '3', '4'], 'stand', dealer: '6'),
        _ => AdaptiveExample(['2', '9', 'K', '6', 'A'], '0'),
      });
    }
    AdaptiveFocus? repeated;
    var most = 1;
    for (final entry in errors.entries) {
      if (entry.value > most) {
        repeated = entry.key;
        most = entry.value;
      }
    }
    if (repeated == null) return null;
    return LessonAdaptation._(repeated, switch (repeated) {
      AdaptiveFocus.hardStand => AdaptiveExample(
        ['10', '2'],
        'stand',
        dealer: '6',
      ),
      AdaptiveFocus.hardHit => AdaptiveExample(['10', '2'], 'hit', dealer: '3'),
      AdaptiveFocus.softDouble => AdaptiveExample(
        ['A', '7'],
        'doubleDown',
        dealer: '4',
      ),
      AdaptiveFocus.softStand => AdaptiveExample(
        ['A', '7'],
        'stand',
        dealer: '8',
      ),
      AdaptiveFocus.softHit => AdaptiveExample(['A', '7'], 'hit', dealer: '9'),
      AdaptiveFocus.softFallback => AdaptiveExample(
        ['A', '2', '5'],
        'stand',
        dealer: '6',
      ),
      AdaptiveFocus.countResult => AdaptiveExample(['3', 'K'], '0'),
      AdaptiveFocus.extraCard => throw StateError('Challenge handled above'),
    });
  }

  static AdaptiveFocus _category(String id, PilotScenario task) {
    if (task.isCounting) return AdaptiveFocus.countResult;
    if (id == 'hard-12') {
      return task.expected == 'stand'
          ? AdaptiveFocus.hardStand
          : AdaptiveFocus.hardHit;
    }
    if (task.expected == 'doubleDown') return AdaptiveFocus.softDouble;
    if (task.expected == 'hit') return AdaptiveFocus.softHit;
    if (!task.availableActions.contains(PlayerAction.doubleDown) &&
        const {'3', '4', '5', '6'}.contains(task.dealer!.rank.label)) {
      return AdaptiveFocus.softFallback;
    }
    return AdaptiveFocus.softStand;
  }
}
