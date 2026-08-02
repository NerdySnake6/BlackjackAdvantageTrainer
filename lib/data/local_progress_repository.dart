/// SharedPreferencesAsync-backed prototype progress storage.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/persistence/progress_repository.dart';
import '../domain/learning/models.dart';

class LocalProgressRepository implements ProgressRepository {
  LocalProgressRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _progressKey = 'learning_progress_v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<ProgressSnapshot> load() async {
    final rawJson = await _preferences.getString(_progressKey);
    if (rawJson == null) {
      return const ProgressSnapshot();
    }
    return ProgressSnapshot.fromJson(
      jsonDecode(rawJson)! as Map<String, Object?>,
    );
  }

  @override
  Future<void> save(ProgressSnapshot snapshot) {
    return _preferences.setString(_progressKey, jsonEncode(snapshot.toJson()));
  }

  @override
  Future<void> clear() => _preferences.remove(_progressKey);
}
