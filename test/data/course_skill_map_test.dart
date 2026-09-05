import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('course skill map covers the approved 26 Free and 32 Pro lessons', () {
    final map = _readJson('docs/COURSE_SKILL_MAP.json');
    final sections = (map['sections']! as List<Object?>)
        .cast<Map<String, Object?>>();
    final lessons = [
      for (final section in sections)
        ...(section['lessons']! as List<Object?>).cast<Map<String, Object?>>(),
    ];
    final ids = lessons.map((lesson) => lesson['id']! as String).toList();
    final skillIds = lessons
        .map((lesson) => lesson['skillId']! as String)
        .toList();

    expect(map['schemaVersion'], 1);
    expect(map['status'], 'approved-plan-not-production-content');
    expect(sections, hasLength(10));
    expect(lessons, hasLength(58));
    expect(ids.toSet(), hasLength(58));
    expect(skillIds.toSet(), hasLength(58));
    expect(
      sections
          .where((section) => section['access'] == 'free')
          .expand(
            (section) => (section['lessons']! as List<Object?>).cast<Object?>(),
          )
          .length,
      26,
    );
    expect(
      sections
          .where((section) => section['access'] == 'pro')
          .expand(
            (section) => (section['lessons']! as List<Object?>).cast<Object?>(),
          )
          .length,
      32,
    );

    final sources = (map['sourceRegistry']! as Map<String, Object?>).keys;
    final positionById = {
      for (var index = 0; index < ids.length; index++) ids[index]: index,
    };
    for (final lesson in lessons) {
      expect(lesson['outcome'], isA<String>());
      expect((lesson['outcome']! as String).trim(), isNotEmpty);
      expect(lesson['anchorExample'], isA<String>());
      expect((lesson['anchorExample']! as String).trim(), isNotEmpty);
      expect(lesson['transferCheck'], isA<String>());
      expect((lesson['transferCheck']! as String).trim(), isNotEmpty);

      final misconceptions = (lesson['misconceptions']! as List<Object?>)
          .cast<String>();
      expect(misconceptions, isNotEmpty);
      expect(misconceptions.every((item) => item.trim().isNotEmpty), isTrue);

      final sourceRefs = (lesson['sourceRefs']! as List<Object?>)
          .cast<String>();
      expect(sourceRefs, isNotEmpty);
      expect(sourceRefs.every(sources.contains), isTrue);

      final prerequisites = (lesson['prerequisiteLessonIds']! as List<Object?>)
          .cast<String>();
      for (final prerequisite in prerequisites) {
        expect(positionById.containsKey(prerequisite), isTrue);
        expect(
          positionById[prerequisite],
          lessThan(positionById[lesson['id']! as String]!),
          reason: '${lesson['id']} prerequisite order',
        );
      }
    }

    final existing = _readJson('assets/content/en/lessons.json');
    final existingLessons = [
      for (final section
          in (existing['sections']! as List<Object?>)
              .cast<Map<String, Object?>>())
        ...(section['lessons']! as List<Object?>).cast<Map<String, Object?>>(),
    ];
    final mapById = {
      for (final lesson in lessons) lesson['id']! as String: lesson,
    };
    for (final lesson in existingLessons) {
      final planned = mapById[lesson['id']! as String]!;
      expect(planned['skillId'], lesson['skillId']);
    }
  });
}

Map<String, Object?> _readJson(String path) {
  return jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
}
