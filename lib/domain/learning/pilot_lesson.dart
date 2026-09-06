/// Content-driven lessons on the two supported scenes, not a course generator.
library;

import 'dart:convert';

import '../blackjack_engine/card.dart';
import '../blackjack_engine/game_rules.dart';
import 'lesson_format.dart';

class PilotScenario {
  PilotScenario.fromJson(Map<String, Object?> json)
    : id = json['id']! as String,
      kind = LessonMissionKind.values.byName(json['kind']! as String),
      stage = LessonMissionStage.values.byName(json['stage']! as String),
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
      coaching = LessonCoaching.fromJson(
        json['coaching']! as Map<String, Object?>,
      ) {
    if (cards.isEmpty ||
        isCounting != (dealer == null) ||
        (isCounting && availableActions.isNotEmpty) ||
        !accepts(expected)) {
      throw FormatException('Invalid pilot scenario: $id');
    }
  }

  final String id;
  final LessonMissionKind kind;
  final LessonMissionStage stage;
  final List<PlayingCard> cards;
  final PlayingCard? dealer;
  final Set<PlayerAction> availableActions;
  final int initialCount;
  final String expected;
  final LessonCoaching coaching;

  String get explanation => coaching.explanation;
  String get contrast => coaching.contrast;
  Map<String, String> get mistakes => coaching.mistakes;

  bool get isCounting => kind == LessonMissionKind.runningCount;
  bool get isEvaluated => stage != LessonMissionStage.introduction;
  bool get allowsHint => stage != LessonMissionStage.independent;

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
    : schemaVersion = json['schemaVersion']! as int,
      id = json['id']! as String,
      skillId = json['skillId']! as String,
      version = json['version']! as int,
      profileId = json['profileId']! as String,
      title = json['title']! as String,
      subtitle = json['subtitle']! as String,
      theoryBlock = LessonTheory.fromJson(
        json['theory']! as Map<String, Object?>,
      ),
      scoring = LessonScoring.fromJson(
        json['scoring']! as Map<String, Object?>,
      ),
      scenarios = List.unmodifiable(
        (json['scenarios']! as List<Object?>).map(
          (item) => PilotScenario.fromJson(item! as Map<String, Object?>),
        ),
      ) {
    if (schemaVersion != 1 ||
        version < 1 ||
        introductionCount < 2 ||
        introductionCount > 4 ||
        scenarios.where((s) => s.stage == LessonMissionStage.practice).length !=
            5 ||
        scenarios
                .where((s) => s.stage == LessonMissionStage.independent)
                .length !=
            5 ||
        scenarios.map((item) => item.id).toSet().length != scenarios.length ||
        !List.generate(
          scenarios.length - 1,
          (i) => scenarios[i].stage.index <= scenarios[i + 1].stage.index,
        ).every((v) => v)) {
      throw FormatException('Invalid pilot lesson: $id');
    }
  }

  final String id;
  final int schemaVersion;
  final String skillId;
  final int version;
  final String profileId;
  final String title;
  final String subtitle;
  final LessonTheory theoryBlock;
  final LessonScoring scoring;
  final List<PilotScenario> scenarios;

  String get theory => theoryBlock.text;
  int get introductionCount => scenarios.where((s) => !s.isEvaluated).length;
  int get evaluatedCount => scenarios.where((s) => s.isEvaluated).length;

  /// Locale-independent identity for resume and translation parity checks.
  String get resumeSignature => jsonEncode({
    'id': id,
    'skill': skillId,
    'schema': schemaVersion,
    'version': version,
    'profile': profileId,
    'theory': theoryBlock.id,
    'policy': scoring.policyId,
    'pass': scoring.passCorrect,
    'stars': scoring.starCorrect,
    'unassisted': scoring.topStarRequiresUnassisted,
    'tasks': [
      for (final task in scenarios)
        {
          'id': task.id,
          'kind': task.kind.name,
          'stage': task.stage.name,
          'cards': task.cards.map((c) => c.rank.label).toList(),
          'dealer': task.dealer?.rank.label,
          'actions': task.availableActions.map((a) => a.name).toList()..sort(),
          'initialCount': task.initialCount,
          'expected': task.expected,
          'mistakes': task.mistakes.keys.toList()..sort(),
        },
    ],
  });
}
