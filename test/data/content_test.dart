import 'dart:convert';
import 'dart:io';

import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('English prototype content has six valid, unique lessons', () async {
    final rawJson = await File('assets/content/en/lessons.json').readAsString();
    final catalog = CourseCatalog.fromJson(
      jsonDecode(rawJson)! as Map<String, Object?>,
    );

    expect(catalog.contentVersion, 1);
    expect(catalog.locale, 'en');
    expect(catalog.lessons, hasLength(6));
    expect(catalog.lessons.map((lesson) => lesson.id).toSet(), hasLength(6));
    for (final lesson in catalog.lessons) {
      expect(lesson.exercises.length, greaterThanOrEqualTo(8));
      for (final exercise in lesson.exercises) {
        expect(
          exercise.correctIndex,
          inInclusiveRange(0, exercise.options.length - 1),
        );
        expect(exercise.explanation, isNotEmpty);
      }
    }
  });
}
