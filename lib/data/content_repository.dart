/// Loads versioned, locale-specific course content bundled with the app.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/learning/content_validator.dart';
import '../domain/learning/models.dart';

class ContentRepository {
  ContentRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const String fallbackLocale = 'en';

  final AssetBundle _bundle;

  /// Loads the course package for [localeCode], falling back to English when
  /// that locale ships no package yet. Lesson and exercise IDs are stable
  /// across locales, so stored progress survives a language change.
  Future<CourseCatalog> loadCatalog({
    String localeCode = fallbackLocale,
  }) async {
    final rawJson =
        await _loadRaw(localeCode) ??
        (localeCode == fallbackLocale ? null : await _loadRaw(fallbackLocale));
    if (rawJson == null) {
      throw StateError('No course content bundled for "$localeCode".');
    }
    final json = jsonDecode(rawJson)! as Map<String, Object?>;
    final locale = json['locale']! as String;
    final pilotJson = await _bundle.loadString(
      'assets/content/$locale/pilot_lessons.json',
    );
    final manifest =
        jsonDecode(
              await _bundle.loadString('assets/content/$locale/manifest.json'),
            )!
            as Map<String, Object?>;
    final glossary =
        jsonDecode(
              await _bundle.loadString('assets/content/$locale/glossary.json'),
            )!
            as Map<String, Object?>;
    return const ContentValidator().parse(
      catalog: json,
      pilotLessons: jsonDecode(pilotJson),
      foundationLessons: jsonDecode(
        await _bundle.loadString(
          'assets/content/$locale/foundation_lessons.json',
        ),
      ),
      manifest: manifest,
      strategyLessons: jsonDecode(
        await _bundle.loadString(
          'assets/content/$locale/strategy_lessons.json',
        ),
      ),
      glossary: glossary,
    );
  }

  Future<String?> _loadRaw(String localeCode) async {
    try {
      return await _bundle.loadString(
        'assets/content/$localeCode/lessons.json',
      );
    } on FlutterError {
      return null;
    }
  }
}
