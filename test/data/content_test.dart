import 'dart:convert';
import 'dart:io';

import 'package:blackjack_advantage_trainer/domain/learning/answer_order.dart';
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

    expect(catalog.contentVersion, 3);
    expect(manifest['contentVersion'], catalog.contentVersion);
    expect(manifest['locale'], catalog.locale);
    expect(catalog.locale, 'en');
    expect(lessons, hasLength(6));
    expect(lessons.map((lesson) => lesson.id).toSet(), hasLength(6));
    expect(exercises, hasLength(54));
    expect(exercises.map((exercise) => exercise.id).toSet(), hasLength(54));
    expect(
      exercises.map((exercise) => exercise.id),
      contains('hilo-multideck-carry'),
    );

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

  test(
    'stable answer order distributes correct answers across positions',
    () async {
      final rawJson = await File(
        'assets/content/en/lessons.json',
      ).readAsString();
      final catalog = CourseCatalog.fromJson(
        jsonDecode(rawJson)! as Map<String, Object?>,
      );
      final correctPositions = <int>[];

      for (final lesson in catalog.lessons) {
        final lessonPositions = <int>{};
        for (final exercise in lesson.exercises) {
          final firstOrder = deterministicAnswerOrder(
            exercise.id,
            exercise.options.length,
          );
          final secondOrder = deterministicAnswerOrder(
            exercise.id,
            exercise.options.length,
          );
          expect(secondOrder, firstOrder);
          expect(firstOrder.toSet(), {
            for (var index = 0; index < exercise.options.length; index++) index,
          });
          final correctPosition = firstOrder.indexOf(exercise.correctIndex);
          correctPositions.add(correctPosition);
          lessonPositions.add(correctPosition);
        }
        expect(lessonPositions.length, greaterThan(1));
      }

      expect(correctPositions.toSet(), containsAll(<int>{0, 1, 2}));
    },
  );
}
