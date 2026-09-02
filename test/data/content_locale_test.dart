import 'dart:convert';

import 'package:blackjack_advantage_trainer/data/content_repository.dart';
import 'package:blackjack_advantage_trainer/l10n/app_localizations_ru.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'ru package loads and keeps identical lesson and exercise ids with English',
    () async {
      final repository = ContentRepository();
      final english = await repository.loadCatalog();
      final russian = await repository.loadCatalog(localeCode: 'ru');

      expect(_ids(russian), _ids(english));
      expect(_ids(english), isNotEmpty);

      // Verify that lessons and exercises have translated text and preserved math
      for (var s = 0; s < english.sections.length; s++) {
        final enSection = english.sections[s];
        final ruSection = russian.sections[s];
        expect(ruSection.id, enSection.id);
        expect(ruSection.title, isNotEmpty);
        expect(ruSection.title, isNot(equals(enSection.title)));

        for (var l = 0; l < enSection.lessons.length; l++) {
          final enLesson = enSection.lessons[l];
          final ruLesson = ruSection.lessons[l];
          expect(ruLesson.id, enLesson.id);
          expect(ruLesson.skillId, enLesson.skillId);
          expect(ruLesson.exercises.length, enLesson.exercises.length);

          for (var e = 0; e < enLesson.exercises.length; e++) {
            final enEx = enLesson.exercises[e];
            final ruEx = ruLesson.exercises[e];
            expect(ruEx.id, enEx.id);
            expect(ruEx.correctIndex, enEx.correctIndex);
            expect(ruEx.options.length, enEx.options.length);
            expect(ruEx.prompt, isNotEmpty);
            expect(ruEx.explanation, isNotEmpty);
          }
        }
      }
    },
  );

  test(
    'ru glossary file exists and contains all required definitions',
    () async {
      final raw = await rootBundle.loadString(
        'assets/content/ru/glossary.json',
      );
      final Map<String, Object?> json = jsonDecode(raw) as Map<String, Object?>;

      expect(json.containsKey('hit'), isTrue);
      expect(json.containsKey('stand'), isTrue);
      expect(json.containsKey('double'), isTrue);
      expect(json.containsKey('split'), isTrue);
      expect(json.containsKey('surrender'), isTrue);
      expect(json.containsKey('hardHand'), isTrue);
      expect(json.containsKey('softHand'), isTrue);
      expect(json.containsKey('runningCount'), isTrue);
      expect(json.containsKey('trueCount'), isTrue);
      expect(json.containsKey('penetration'), isTrue);

      for (final value in json.values) {
        expect((value as String).isNotEmpty, isTrue);
      }
    },
  );

  test('ru manifest file defines valid metadata', () async {
    final raw = await rootBundle.loadString('assets/content/ru/manifest.json');
    final Map<String, Object?> json = jsonDecode(raw) as Map<String, Object?>;

    expect(json['locale'], 'ru');
    expect(json['sourceLocale'], 'en');
    expect(json['translationStatus'], 'complete');
    expect(json['lessonFile'], 'assets/content/ru/lessons.json');
    expect(json['glossaryFile'], 'assets/content/ru/glossary.json');
  });

  test('AppLocalizationsRu translates all critical interface keys', () {
    final l10n = AppLocalizationsRu();
    expect(l10n.appTitle, 'Blackjack Advantage');
    expect(l10n.learnTab, 'Обучение');
    expect(l10n.drillTab, 'Тренажёр');
    expect(l10n.tableTab, 'Стол');
    expect(l10n.profileTab, 'Прогресс');
    expect(l10n.hit, 'Ещё');
    expect(l10n.stand, 'Хватит');
    expect(l10n.doubleAction, 'Дабл');
    expect(l10n.split, 'Сплит');
    expect(l10n.surrender, 'Сдаться');
    expect(l10n.languageLabel, 'Язык');
    expect(l10n.systemDefault, 'Как в системе');
    expect(l10n.englishLanguage, 'English');
    expect(l10n.russianLanguage, 'Русский');
  });

  test('unknown locale falls back to English instead of throwing', () async {
    final repository = ContentRepository();
    final fallback = await repository.loadCatalog(localeCode: 'xx');

    expect(_ids(fallback), _ids(await repository.loadCatalog()));
  });

  test('throws when even the fallback package is missing', () async {
    final repository = ContentRepository(bundle: _EmptyBundle());

    expect(repository.loadCatalog(), throwsStateError);
  });
}

List<String> _ids(Object catalog) {
  final dynamic c = catalog;
  return [
    for (final section in c.sections)
      for (final lesson in section.lessons) ...[
        lesson.id as String,
        for (final exercise in lesson.exercises) exercise.id as String,
      ],
  ];
}

class _EmptyBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => throw FlutterError('missing $key');
}
