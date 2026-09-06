import 'dart:convert';
import 'dart:io';

import 'package:blackjack_advantage_trainer/domain/learning/content_validator.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _package(String locale) => {
  for (final (key, filename) in [
    ('catalog', 'lessons'),
    ('pilotLessons', 'pilot_lessons'),
    ('manifest', 'manifest'),
    ('glossary', 'glossary'),
  ])
    key: jsonDecode(
      File('assets/content/$locale/$filename.json').readAsStringSync(),
    ),
};

CourseCatalog _parse(Map<String, dynamic> raw) =>
    const ContentValidator().parse(
      catalog: raw['catalog'] as Map<String, Object?>,
      pilotLessons: raw['pilotLessons'],
      manifest: raw['manifest'] as Map<String, Object?>,
      glossary: raw['glossary'] as Map<String, Object?>,
    );

void _replace(Map<String, dynamic> raw, String path, Object? value) {
  final parts = path.split('/');
  dynamic parent = raw;
  for (final part in parts.take(parts.length - 1)) {
    parent = parent is List ? parent[int.parse(part)] : parent[part];
  }
  if (parent is List) {
    parent[int.parse(parts.last)] = value;
  } else {
    parent[parts.last] = value;
  }
}

void main() {
  const validator = ContentValidator();
  test(
    'both shipped packages are valid and reference approved lesson skills',
    () {
      final plan =
          jsonDecode(File('docs/COURSE_SKILL_MAP.json').readAsStringSync())
              as Map;
      final skills = <String, String>{
        for (final section in plan['sections'] as List)
          for (final lesson in section['lessons'] as List)
            lesson['id'] as String: lesson['skillId'] as String,
      };
      final en = _package('en');
      final ru = _package('ru');
      validator.validateSkillReferences(_parse(en), skills);
      validator.validateSkillReferences(_parse(ru), skills);
      validator.validateTranslation(
        _parse(en),
        _parse(ru),
        sourceGlossary: en['glossary'] as Map<String, Object?>,
        translatedGlossary: ru['glossary'] as Map<String, Object?>,
      );
      expect(
        () => validator.validateSkillReferences(_parse(en), {}),
        throwsFormatException,
      );
    },
  );

  for (final (path, value) in <(String, Object?)>[
    ('pilotLessons', null),
    ('pilotLessons', []),
    ('pilotLessons/0/theory/text', '  '),
    ('pilotLessons/0/title', ''),
    ('pilotLessons/0/subtitle', ''),
    ('pilotLessons/0/skillId', ''),
    ('pilotLessons/0/id', 'bad ID'),
    ('pilotLessons/0/id', 'quick-start'),
    ('pilotLessons/0/theory/id', 'hard-12'),
    ('pilotLessons/0/schemaVersion', 5),
    ('pilotLessons/0/version', 0),
    ('pilotLessons/0/profileId', 'unverified_h17'),
    ('pilotLessons/0/scenarios/0/coaching', null),
    ('pilotLessons/0/scenarios/0/coaching/explanation', ''),
    ('pilotLessons/0/scenarios/0/coaching/contrast', ' '),
    (
      'pilotLessons/0/scenarios/0/coaching/mistakes',
      {'hit': 'Only one action'},
    ),
    ('pilotLessons/0/scenarios/0/coaching/mistakes/hit', ''),
    ('pilotLessons/0/scenarios/0/coaching/mistakes/typo', 'Unknown answer'),
    ('pilotLessons/0/scenarios/0/kind', 'camera'),
    ('pilotLessons/0/scenarios/0/stage', 'exam'),
    ('pilotLessons/0/scenarios/0/actions', ['unknown']),
    ('pilotLessons/0/scenarios/0/cards', ['?']),
    ('pilotLessons/0/scenarios/0/cards', ['2']),
    ('pilotLessons/0/scenarios/0/cards', ['2', '3', '7']),
    ('pilotLessons/1/scenarios/0/id', 'hard-12-intro-1'),
    ('pilotLessons/2/scenarios/0/expected', '99'),
    ('pilotLessons/2/scenarios/0/coaching/mistakes', {}),
    ('catalog/locale', 'xx'),
    ('catalog/sections', []),
    ('manifest/contentVersion', 999),
    ('manifest/locale', 'ru'),
    ('manifest/sourceLocale', 'xx'),
    ('manifest/license', ''),
    ('manifest/lessonFile', 'https://example.com/lessons.json'),
    ('manifest/pilotLessonFile', 'assets/content/ru/pilot_lessons.json'),
    ('manifest/glossaryFile', '../glossary.json'),
    ('manifest/supportedRuleProfiles', ['unverified_h17']),
    ('manifest/mathematicalSources', []),
    ('manifest/mathematicalSources', [1]),
    ('manifest/mathematicalSources', ['http://example.com']),
    ('glossary/hit', ''),
    ('glossary/extra', 1),
  ]) {
    test('rejects invalid $path = $value', () {
      final raw = _package('en');
      _replace(raw, path, value);
      expect(() => _parse(raw), throwsFormatException);
    });
  }

  test('incomplete Russian package is not a release-ready translation', () {
    final raw = _package('ru');
    raw['manifest']['translationStatus'] = 'draft';
    expect(() => _parse(raw), throwsFormatException);
  });

  for (final (path, value) in <(String, Object?)>[
    ('pilotLessons/0/skillId', 'another.skill'),
    ('pilotLessons/0/version', 2),
    ('pilotLessons/0/theory/id', 'another-theory'),
    ('pilotLessons/0/scenarios/0/cards', ['9', '3']),
    ('pilotLessons/0/scenarios/0/dealer', '5'),
    ('pilotLessons/0/scenarios/0/expected', 'hit'),
  ]) {
    test('rejects translated semantic drift at $path', () {
      final en = _package('en');
      final ru = _package('ru');
      _replace(ru, path, value);
      expect(
        () => validator.validateTranslation(
          _parse(en),
          _parse(ru),
          sourceGlossary: en['glossary'] as Map<String, Object?>,
          translatedGlossary: ru['glossary'] as Map<String, Object?>,
        ),
        throwsFormatException,
      );
    });
  }

  test('rejects translation with missing lessons or extra glossary keys', () {
    final en = _package('en');
    final ru = _package('ru');
    (ru['pilotLessons'] as List).removeLast();
    expect(
      () => validator.validateTranslation(
        _parse(en),
        _parse(ru),
        sourceGlossary: en['glossary'] as Map<String, Object?>,
        translatedGlossary: ru['glossary'] as Map<String, Object?>,
      ),
      throwsFormatException,
    );
    final fresh = _package('ru');
    fresh['glossary']['extra'] = 'Лишний термин';
    expect(
      () => validator.validateTranslation(
        _parse(en),
        _parse(fresh),
        sourceGlossary: en['glossary'] as Map<String, Object?>,
        translatedGlossary: fresh['glossary'] as Map<String, Object?>,
      ),
      throwsFormatException,
    );
  });
}
