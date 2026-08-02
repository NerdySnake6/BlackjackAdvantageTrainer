import 'dart:convert';
import 'dart:io';

import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('English prototype content has six valid, unique lessons', () async {
    final rawJson = await File('assets/content/en/lessons.json').readAsString();
    final rawManifest = await File(
      'assets/content/en/manifest.json',
    ).readAsString();
    final catalog = CourseCatalog.fromJson(
      jsonDecode(rawJson)! as Map<String, Object?>,
    );
    final manifest = jsonDecode(rawManifest)! as Map<String, Object?>;
    final lessons = catalog.lessons;
    final exercises = [for (final lesson in lessons) ...lesson.exercises];

    expect(catalog.contentVersion, 2);
    expect(manifest['contentVersion'], catalog.contentVersion);
    expect(manifest['locale'], catalog.locale);
    expect(catalog.locale, 'en');
    expect(lessons, hasLength(6));
    expect(lessons.map((lesson) => lesson.id).toSet(), hasLength(6));
    expect(exercises, hasLength(53));
    expect(exercises.map((exercise) => exercise.id).toSet(), hasLength(53));

    for (final lesson in lessons) {
      expect(lesson.id.trim(), isNotEmpty);
      expect(lesson.skillId.trim(), isNotEmpty);
      expect(lesson.exercises.length, greaterThanOrEqualTo(8));
      for (final exercise in lesson.exercises) {
        expect(exercise.id.trim(), isNotEmpty);
        expect(exercise.prompt.trim(), isNotEmpty);
        expect(exercise.options, isNotEmpty);
        for (final option in exercise.options) {
          expect(option.trim(), isNotEmpty);
        }
        expect(
          exercise.correctIndex,
          inInclusiveRange(0, exercise.options.length - 1),
        );
        expect(exercise.explanation.trim(), isNotEmpty);
      }
    }
  });
}
