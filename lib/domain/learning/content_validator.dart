/// Fail-closed validation of bundled learning packages, without platform APIs.
library;

import 'dart:convert';

import '../blackjack_engine/game_rules.dart';
import 'models.dart';
import 'pilot_lesson.dart';

class ContentValidator {
  const ContentValidator();

  CourseCatalog parse({
    required Map<String, Object?> catalog,
    required Object? pilotLessons,
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
    for (final lesson in catalog.pilotLessons) {
      register(lesson.id);
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
        register(task.id);
        _text(task.explanation, '$path/${task.id}/explanation');
        _text(task.contrast, '$path/${task.id}/contrast');
        final keys = task.isCounting
            ? {'count'}
            : task.availableActions.map((a) => a.name).toSet();
        final allowedKeys = task.isCounting
            ? {'count'}
            : PlayerAction.values.map((action) => action.name).toSet();
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
        } else {
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
      }
    }
  }

  /// Checks references against the approved plan during authoring and CI.
  void validateSkillReferences(
    CourseCatalog catalog,
    Map<String, String> skillsByLesson,
  ) {
    for (final lesson in catalog.pilotLessons) {
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
        jsonEncode(_structure(source.pilotLessons[i])) ==
            jsonEncode(_structure(translation.pilotLessons[i])),
        '${translation.locale}/${translation.pilotLessons[i].id}: lesson semantics differ from source',
      );
    }
  }

  Map<String, Object?> _structure(PilotLesson lesson) => {
    'id': lesson.id,
    'skill': lesson.skillId,
    'schema': lesson.schemaVersion,
    'version': lesson.version,
    'profile': lesson.profileId,
    'theory': lesson.theoryBlock.id,
    'policy': lesson.scoring.policyId,
    'pass': lesson.scoring.passCorrect,
    'stars': lesson.scoring.starCorrect,
    'unassisted': lesson.scoring.topStarRequiresUnassisted,
    'tasks': [
      for (final task in lesson.scenarios)
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
  };

  void _text(Object? value, String path) => _require(
    value is String && value.trim().isNotEmpty,
    '$path: missing text',
  );

  void _require(bool condition, String message) {
    if (!condition) throw FormatException(message);
  }
}
