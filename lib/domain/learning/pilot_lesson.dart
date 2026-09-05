/// Fixed, authored scenarios for the three pilot lessons, not a course generator.
library;

import '../blackjack_engine/card.dart';
import '../blackjack_engine/game_rules.dart';

class PilotScenario {
  PilotScenario.fromJson(Map<String, Object?> json)
    : id = json['id']! as String,
      cards = List.unmodifiable(
        (json['cards']! as List<Object?>).indexed.map(
          (entry) => cardFromLabel(entry.$2! as String, entry.$1),
        ),
      ),
      dealer = json['dealer'] == null
          ? null
          : cardFromLabel(
              json['dealer']! as String,
              (json['cards']! as List).length,
            ),
      availableActions = Set.unmodifiable(
        (json['actions'] as List<Object?>? ?? []).map(
          (value) => PlayerAction.values.byName(value! as String),
        ),
      ),
      initialCount = json['initialCount'] as int? ?? 0,
      expected = json['expected']! as String,
      explanation = json['explanation']! as String,
      contrast = json['contrast']! as String,
      mistakes = Map<String, String>.unmodifiable(
        Map<String, String>.from(json['mistakes']! as Map),
      ) {
    if (cards.isEmpty || !accepts(expected)) {
      throw FormatException('Invalid pilot scenario: $id');
    }
  }

  final String id;
  final List<PlayingCard> cards;
  final PlayingCard? dealer;
  final Set<PlayerAction> availableActions;
  final int initialCount;
  final String expected;
  final String explanation;
  final String contrast;
  final Map<String, String> mistakes;

  bool get isCounting => dealer == null;

  bool accepts(String answer) => isCounting
      ? int.tryParse(answer) != null
      : availableActions.any((action) => action.name == answer);

  String feedback(String answer) => answer == expected
      ? explanation
      : '${mistakes[isCounting ? 'count' : answer]}\n\n$explanation';

  int countAfter(int revealed) =>
      initialCount +
      cards.take(revealed).fold(0, (sum, card) => sum + card.hiLoTag);

  static PlayingCard cardFromLabel(String label, int index) => PlayingCard(
    deckIndex: index ~/ CardSuit.values.length,
    suit: CardSuit.values[index % CardSuit.values.length],
    rank: CardRank.values.firstWhere((rank) => rank.label == label),
  );
}

class PilotLesson {
  PilotLesson.fromJson(Map<String, Object?> json)
    : id = json['id']! as String,
      skillId = json['skillId']! as String,
      version = json['version']! as int,
      title = json['title']! as String,
      subtitle = json['subtitle']! as String,
      theory = json['theory']! as String,
      scenarios = List.unmodifiable(
        (json['scenarios']! as List<Object?>).map(
          (item) => PilotScenario.fromJson(item! as Map<String, Object?>),
        ),
      ) {
    // Two unscored introductions, five practice tasks, five transfer tasks.
    if (version < 1 ||
        scenarios.length != 12 ||
        scenarios.map((item) => item.id).toSet().length != 12) {
      throw FormatException('Invalid pilot lesson: $id');
    }
  }

  final String id;
  final String skillId;
  final int version;
  final String title;
  final String subtitle;
  final String theory;
  final List<PilotScenario> scenarios;
}
