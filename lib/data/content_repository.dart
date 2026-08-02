/// Loads versioned, locale-specific course content bundled with the app.
library;

import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/learning/models.dart';

class ContentRepository {
  ContentRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  Future<CourseCatalog> loadEnglishCatalog() async {
    final rawJson = await _bundle.loadString('assets/content/en/lessons.json');
    return CourseCatalog.fromJson(jsonDecode(rawJson)! as Map<String, Object?>);
  }
}
