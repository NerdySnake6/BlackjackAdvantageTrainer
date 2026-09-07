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
    List<bool> hints, {
    int seed = 0,
  }) {
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
      return LessonAdaptation._(
        AdaptiveFocus.extraCard,
        AdaptiveExampleGenerator.generate(
          lesson.id,
          AdaptiveFocus.extraCard,
          seed,
        ),
      );
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
    return LessonAdaptation._(
      repeated,
      AdaptiveExampleGenerator.generate(lesson.id, repeated, seed),
    );
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

/// Finite practice variants, not novel-exam evidence. Seed 0 preserves v18 saves.
class AdaptiveExampleGenerator {
  static const version = 1;
  static const maxSeed = 0x7fffffff;
  static const _dealers = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'A'];
  static const _lows = ['2', '3', '4', '5', '6'];
  static const _highs = ['10', 'J', 'Q', 'K', 'A'];
  static const _neutrals = ['7', '8', '9'];

  static AdaptiveExample generate(
    String lessonId,
    AdaptiveFocus focus,
    int seed,
  ) {
    final valid = switch (lessonId) {
      'hard-12' => const {
        AdaptiveFocus.hardStand,
        AdaptiveFocus.hardHit,
        AdaptiveFocus.extraCard,
      },
      'soft-18' => const {
        AdaptiveFocus.softDouble,
        AdaptiveFocus.softStand,
        AdaptiveFocus.softHit,
        AdaptiveFocus.softFallback,
        AdaptiveFocus.extraCard,
      },
      'hi-lo-cancellation' => const {
        AdaptiveFocus.countResult,
        AdaptiveFocus.extraCard,
      },
      _ => <AdaptiveFocus>{},
    };
    if (seed < 0 || seed > maxSeed || !valid.contains(focus)) {
      throw ArgumentError('Unsupported practice variant');
    }
    if (seed == 0) return _original(lessonId, focus);
    final n = seed - 1;
    if (lessonId == 'hi-lo-cancellation') {
      final low = _lows[n % _lows.length];
      final high = _highs[(n ~/ 5) % _highs.length];
      if (focus == AdaptiveFocus.countResult) {
        return AdaptiveExample([low, high], '0');
      }
      // Two fixed neutral positions separate this practice family from check v1.
      final pattern = (n ~/ 5) % 4;
      final first = pattern.isEven ? low : high;
      final middle = pattern < 2 ? (pattern == 0 ? high : low) : first;
      final last = pattern.isEven ? _lows[(n + 1) % 5] : _highs[(n + 1) % 5];
      return AdaptiveExample(
        [first, _neutrals[n % 3], middle, _neutrals[(n + 1) % 3], last],
        switch (pattern) {
          0 => '1',
          1 => '-1',
          2 => '3',
          _ => '-3',
        },
      );
    }
    if (lessonId == 'hard-12') {
      final dealers = focus == AdaptiveFocus.hardStand
          ? const ['4', '5', '6']
          : focus == AdaptiveFocus.hardHit
          ? const ['2', '3', '7', '8', '9', '10', 'A']
          : _dealers;
      final dealer = dealers[n % dealers.length];
      const pairs = [
        ['10', '2'],
        ['9', '3'],
        ['8', '4'],
        ['7', '5'],
      ];
      // Excludes both held-out check compositions (2+3+7 and 2+2+8).
      const triples = [
        ['2', '4', '6'],
        ['2', '5', '5'],
        ['3', '3', '6'],
        ['3', '4', '5'],
        ['4', '4', '4'],
      ];
      final cards = focus == AdaptiveFocus.extraCard
          ? triples[(n ~/ dealers.length) % triples.length]
          : pairs[(n ~/ dealers.length) % pairs.length];
      return AdaptiveExample(
        cards,
        const {'4', '5', '6'}.contains(dealer) ? 'stand' : 'hit',
        dealer: dealer,
      );
    }
    final dealers = switch (focus) {
      AdaptiveFocus.softDouble ||
      AdaptiveFocus.softFallback => const ['3', '4', '5', '6'],
      AdaptiveFocus.softStand => const ['2', '7', '8'],
      AdaptiveFocus.softHit => const ['10', 'A', '9'],
      _ => _dealers,
    };
    final dealer = dealers[n % dealers.length];
    final multiple =
        focus == AdaptiveFocus.softFallback || focus == AdaptiveFocus.extraCard;
    const softTriples = [
      ['A', 'A', '6'],
      ['A', '2', '5'],
      ['A', '3', '4'],
    ];
    final cards = multiple
        ? softTriples[(n ~/ dealers.length) % softTriples.length]
        : const ['A', '7'];
    final expected = const {'9', '10', 'A'}.contains(dealer)
        ? 'hit'
        : !multiple && const {'3', '4', '5', '6'}.contains(dealer)
        ? 'doubleDown'
        : 'stand';
    return AdaptiveExample(cards, expected, dealer: dealer);
  }

  static AdaptiveExample _original(String id, AdaptiveFocus focus) {
    if (focus == AdaptiveFocus.extraCard) {
      return switch (id) {
        'hard-12' => AdaptiveExample(['3', '4', '5'], 'stand', dealer: '4'),
        'soft-18' => AdaptiveExample(['A', '3', '4'], 'stand', dealer: '6'),
        _ => AdaptiveExample(['2', '9', 'K', '6', 'A'], '0'),
      };
    }
    return switch (focus) {
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
    };
  }
}
