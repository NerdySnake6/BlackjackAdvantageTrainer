/// Validates bundled EN/RU packages and approved stable references before build.
library;

import 'dart:convert';
import 'dart:io';

import 'package:blackjack_advantage_trainer/domain/learning/content_validator.dart';

void main() {
  try {
    const validator = ContentValidator();
    final skillMap = _object('docs/COURSE_SKILL_MAP.json');
    final skills = <String, String>{
      for (final section in skillMap['sections']! as List)
        for (final lesson in section['lessons'] as List)
          lesson['id'] as String: lesson['skillId'] as String,
    };
    final packages = [
      for (final locale in ['en', 'ru'])
        (
          catalog: validator.parse(
            catalog: _object('assets/content/$locale/lessons.json'),
            pilotLessons: _json('assets/content/$locale/pilot_lessons.json'),
            foundationLessons: _json(
              'assets/content/$locale/foundation_lessons.json',
            ),
            manifest: _object('assets/content/$locale/manifest.json'),
            strategyLessons: _json(
              'assets/content/$locale/strategy_lessons.json',
            ),
            glossary: _object('assets/content/$locale/glossary.json'),
          ),
          glossary: _object('assets/content/$locale/glossary.json'),
        ),
    ];
    for (final package in packages) {
      validator.validateSkillReferences(package.catalog, skills);
    }
    validator.validateTranslation(
      packages.first.catalog,
      packages.last.catalog,
      sourceGlossary: packages.first.glossary,
      translatedGlossary: packages.last.glossary,
    );
    stdout.writeln(
      'Content validation passed: EN/RU packages, stable references and lesson semantics.',
    );
  } on Object catch (error) {
    stderr.writeln('Content validation failed: $error');
    exitCode = 1;
  }
}

Object? _json(String path) => jsonDecode(File(path).readAsStringSync());
Map<String, Object?> _object(String path) =>
    _json(path)! as Map<String, Object?>;
