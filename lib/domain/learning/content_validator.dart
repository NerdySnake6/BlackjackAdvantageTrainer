/// Fail-closed validation of bundled learning packages, without platform APIs.
library;

import '../blackjack_engine/game_rules.dart';
import 'lesson_format.dart';
import 'models.dart';

class ContentValidator {
  const ContentValidator();

  CourseCatalog parse({
    required Map<String, Object?> catalog,
    required Object? pilotLessons,
    Object? foundationLessons,
    Object? strategyLessons,
    required Map<String, Object?> manifest,
    required Map<String, Object?> glossary,
  }) {
    try {
      _require(
        pilotLessons is List && pilotLessons.isNotEmpty,
        'pilotLessons: expected nonempty list',
      );
      final parsed = CourseCatalog.fromJson({
        ...catalog,
        'pilotLessons': pilotLessons,
        'foundationLessons': foundationLessons,
        'strategyLessons': strategyLessons,
      });
      validate(parsed, manifest: manifest, glossary: glossary);
      return parsed;
    } on TypeError {
      throw const FormatException(
        'Content package: missing field or invalid JSON type',
      );
    } on ArgumentError {
      throw const FormatException(
        'Content package: unknown mission kind, stage or action',
      );
    } on StateError {
      throw const FormatException('Content package: unknown card rank');
    }
  }

  void validate(
    CourseCatalog catalog, {
    required Map<String, Object?> manifest,
    required Map<String, Object?> glossary,
  }) {
    final locale = catalog.locale;
    _require(['en', 'ru'].contains(locale), 'locale: unsupported package');
    _require(
      catalog.contentVersion > 0 &&
          manifest['contentVersion'] == catalog.contentVersion,
      '$locale/manifest: contentVersion mismatch',
    );
    _require(
      manifest['locale'] == locale && manifest['sourceLocale'] == 'en',
      '$locale/manifest: locale mismatch',
    );
    _text(manifest['license'], '$locale/manifest/license');
    for (final (field, file) in [
      ('lessonFile', 'lessons.json'),
      ('pilotLessonFile', 'pilot_lessons.json'),
      ('glossaryFile', 'glossary.json'),
    ]) {
      _require(
        manifest[field] == 'assets/content/$locale/$file',
        '$locale/manifest/$field: invalid local reference',
      );
    }
    final profiles = manifest['supportedRuleProfiles'];
    _require(
      profiles is List &&
          profiles.length == 1 &&
          profiles.single == GameRulesProfile.standard.id,
      '$locale/manifest: unverified rule profile',
    );
    final sources = manifest['mathematicalSources'];
    _require(
      sources is List &&
          sources.isNotEmpty &&
          sources.every((source) {
            final uri = source is String ? Uri.tryParse(source) : null;
            return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
          }),
      '$locale/manifest: invalid mathematical source reference',
    );
    if (locale != 'en') {
      _require(
        manifest['translationStatus'] == 'complete',
        '$locale/manifest: incomplete translation',
      );
    }
    for (final key in [
      'hit',
      'stand',
      'double',
      'split',
      'surrender',
      'hardHand',
      'softHand',
      'runningCount',
      'trueCount',
      'penetration',
    ]) {
      _text(glossary[key], '$locale/glossary/$key');
    }
    for (final entry in glossary.entries) {
      _text(entry.value, '$locale/glossary/${entry.key}');
    }
    final ids = <String>{};
    void register(String id) {
      _require(
        RegExp(r'^[a-z0-9]+(?:[.-][a-z0-9]+)*$').hasMatch(id) && ids.add(id),
        '$locale/$id: invalid or duplicate ID',
      );
    }

    _require(catalog.sections.isNotEmpty, '$locale: empty sections');
    for (final section in catalog.sections) {
      register(section.id);
      _text(section.title, '$locale/${section.id}/title');
      for (final lesson in section.lessons) {
        register(lesson.id);
        _text(lesson.skillId, '$locale/${lesson.id}/skillId');
        for (final exercise in lesson.exercises) {
          register(exercise.id);
        }
      }
    }
    _require(
      catalog.pilotLessons.isNotEmpty,
      '$locale: missing playable lessons',
    );
    if (catalog.contentVersion >= 4 || catalog.foundationLessons.isNotEmpty) {
      _require(
        catalog.foundationLessons.map((l) => l.id).join(',') ==
                'quick-start,card-values,hard-and-soft,player-actions' &&
            manifest['foundationLessonFile'] ==
                'assets/content/$locale/foundation_lessons.json',
        '$locale: invalid foundation package',
      );
    }
    if (catalog.contentVersion >= 5 || catalog.strategyLessons.isNotEmpty) {
      _require(
        catalog.strategyLessons.map((l) => l.id).join(',') ==
                'first-strategy,dealer-upcard,hard-doubles' &&
            manifest['strategyLessonFile'] ==
                'assets/content/$locale/strategy_lessons.json',
        '$locale: invalid strategy package',
      );
    }
    for (final lesson in catalog.playableLessons) {
      if (catalog.foundationLessons.contains(lesson) ||
          (catalog.strategyLessons.contains(lesson) &&
              lesson.id == 'first-strategy')) {
        final legacy = catalog.lessonById(lesson.id);
        _require(
          legacy.skillId == lesson.skillId,
          '$locale: foundation skill mismatch',
        );
      } else {
        register(lesson.id);
      }
      register(lesson.theoryBlock.id);
      final path = '$locale/${lesson.id}';
      _text(lesson.skillId, '$path/skillId');
      _text(lesson.title, '$path/title');
      _text(lesson.subtitle, '$path/subtitle');
      _text(lesson.theory, '$path/theory');
      _require(
        lesson.profileId == GameRulesProfile.standard.id,
        '$path: unverified rule profile',
      );
      for (final task in lesson.scenarios) {
        if (catalog.strategyLessons.contains(lesson)) {
          _require(
            task.kind == LessonMissionKind.decision,
            '$path/${task.id}: unexpected strategy mission',
          );
        }
        if (catalog.foundationLessons.contains(lesson)) {
          final kind = switch (lesson.id) {
            'quick-start' => LessonMissionKind.handOutcome,
            'card-values' => LessonMissionKind.handTotal,
            'hard-and-soft' => LessonMissionKind.handType,
            _ => LessonMissionKind.actionMeaning,
          };
          _require(
            task.kind == kind,
            '$path/${task.id}: unexpected foundation mission',
          );
        }
        register(task.id);
        _text(task.explanation, '$path/${task.id}/explanation');
        _text(task.contrast, '$path/${task.id}/contrast');
        final keys = task.answerKeys;
        final allowedKeys = task.usesActions
            ? PlayerAction.values.map((action) => action.name).toSet()
            : keys;
        _require(
          task.mistakes.keys.toSet().containsAll(keys) &&
              allowedKeys.containsAll(task.mistakes.keys),
          '$path/${task.id}/mistakes: missing or unknown answer',
        );
        for (final key in task.mistakes.keys) {
          _text(task.mistakes[key], '$path/${task.id}/mistakes/$key');
        }
        if (task.isCounting) {
          _require(
            task.expected == task.countAfter(task.cards.length).toString(),
            '$path/${task.id}: inconsistent count answer',
          );
        } else if (task.usesActions) {
          _require(
            task.cards.length >= 2 &&
                (task.cards.length == 2 ||
                    !task.availableActions.any(
                      (a) =>
                          a == PlayerAction.doubleDown ||
                          a == PlayerAction.surrender,
                    )),
            '$path/${task.id}: unavailable two-card action',
          );
        }
        if (task.isHandMission ||
            task.kind == LessonMissionKind.actionMeaning) {
          _text(task.prompt, '$path/${task.id}/prompt');
          _require(
            task.cards.length >= 2 &&
                task.cards.length <= 5 &&
                task.initialCount == 0,
            '$path/${task.id}: invalid foundation hand',
          );
          final evaluation = task.evaluation;
          if (task.isHandMission) {
            final expected = switch (task.kind) {
              LessonMissionKind.handTotal => '${evaluation.total}',
              LessonMissionKind.handType => evaluation.isSoft ? 'soft' : 'hard',
              _ =>
                evaluation.isBust
                    ? 'bust'
                    : evaluation.isBlackjack && !task.afterSplit
                    ? 'natural'
                    : evaluation.total == 21
                    ? 'twentyOne'
                    : 'inPlay',
            };
            _require(
              task.expected == expected && task.drawCards.isEmpty,
              '$path/${task.id}: inconsistent hand answer',
            );
          } else {
            final legal = <PlayerAction>{
              PlayerAction.hit,
              PlayerAction.stand,
              if (task.cards.length == 2) ...[
                PlayerAction.doubleDown,
                if (!task.afterSplit) PlayerAction.surrender,
                if (task.cards[0].rank.blackjackValue ==
                    task.cards[1].rank.blackjackValue)
                  PlayerAction.split,
              ],
            };
            _require(
              !evaluation.isBust &&
                  evaluation.total < 21 &&
                  legal.length == task.availableActions.length &&
                  legal.containsAll(task.availableActions),
              '$path/${task.id}: invalid legal actions',
            );
            final draws = switch (task.expected) {
              'hit' || 'doubleDown' => 1,
              'split' => 2,
              _ => 0,
            };
            _require(
              task.drawCards.length == draws,
              '$path/${task.id}: invalid action demonstration',
            );
          }
        } else {
          _require(
            task.prompt.isEmpty && !task.afterSplit && task.drawCards.isEmpty,
            '$path/${task.id}: unexpected foundation fields',
          );
        }
      }
    }
  }

  /// Checks references against the approved plan during authoring and CI.
  void validateSkillReferences(
    CourseCatalog catalog,
    Map<String, String> skillsByLesson,
  ) {
    for (final lesson in catalog.playableLessons) {
      _require(
        skillsByLesson[lesson.id] == lesson.skillId,
        '${catalog.locale}/${lesson.id}: unknown lesson/skill reference',
      );
    }
  }

  /// Locale text may differ; resume and scoring semantics must be identical.
  void validateTranslation(
    CourseCatalog source,
    CourseCatalog translation, {
    required Map<String, Object?> sourceGlossary,
    required Map<String, Object?> translatedGlossary,
  }) {
    _require(
      source.contentVersion == translation.contentVersion,
      '${translation.locale}: contentVersion differs from source',
    );
    _require(
      sourceGlossary.keys.toSet().containsAll(translatedGlossary.keys) &&
          translatedGlossary.keys.toSet().containsAll(sourceGlossary.keys),
      '${translation.locale}: glossary keys differ from source',
    );
    _require(
      source.pilotLessons.length == translation.pilotLessons.length,
      '${translation.locale}: playable lesson count differs from source',
    );
    for (var i = 0; i < source.pilotLessons.length; i++) {
      _require(
        source.pilotLessons[i].resumeSignature ==
            translation.pilotLessons[i].resumeSignature,
        '${translation.locale}/${translation.pilotLessons[i].id}: lesson semantics differ from source',
      );
    }
    _require(
      source.foundationLessons.length == translation.foundationLessons.length,
      '${translation.locale}: foundation count differs',
    );
    for (var i = 0; i < source.foundationLessons.length; i++) {
      _require(
        source.foundationLessons[i].resumeSignature ==
            translation.foundationLessons[i].resumeSignature,
        '${translation.locale}: foundation semantics differ',
      );
    }
    _require(
      source.strategyLessons.length == translation.strategyLessons.length,
      '${translation.locale}: strategy count differs',
    );
    for (var i = 0; i < source.strategyLessons.length; i++) {
      _require(
        source.strategyLessons[i].resumeSignature ==
            translation.strategyLessons[i].resumeSignature,
        '${translation.locale}: strategy semantics differ',
      );
    }
  }

  void _text(Object? value, String path) => _require(
    value is String && value.trim().isNotEmpty,
    '$path: missing text',
  );

  void _require(bool condition, String message) {
    if (!condition) throw FormatException(message);
  }
}
