/// SharedPreferencesAsync-backed prototype progress storage.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/persistence/progress_repository.dart';
import '../domain/learning/models.dart';

class LocalProgressRepository implements ProgressRepository {
  LocalProgressRepository({SharedPreferencesAsync? preferences})
    : _storage = _SharedPreferencesProgressStorage(
        preferences ?? SharedPreferencesAsync(),
      );

  /// Creates progress storage with an injectable backend for deterministic tests.
  LocalProgressRepository.withStorage(ProgressStorage storage)
    : _storage = storage;

  static const _progressKey = 'learning_progress_v1';
  static const _recoveryKey = 'learning_progress_corrupt_v1';
  final ProgressStorage _storage;

  @override
  Future<ProgressSnapshot> load() async {
    final rawJson = await _storage.getString(_progressKey);
    if (rawJson == null) {
      return const ProgressSnapshot();
    }
    try {
      return ProgressSnapshot.fromJson(
        jsonDecode(rawJson)! as Map<String, Object?>,
      );
    } on Object {
      await _storage.setString(_recoveryKey, rawJson);
      await _storage.remove(_progressKey);
      return const ProgressSnapshot();
    }
  }

  @override
  Future<void> save(ProgressSnapshot snapshot) {
    return _storage.setString(_progressKey, jsonEncode(snapshot.toJson()));
  }

  @override
  Future<void> clear() => _storage.remove(_progressKey);
}

/// Minimal string storage needed by [LocalProgressRepository].
abstract interface class ProgressStorage {
  Future<String?> getString(String key);

  Future<void> setString(String key, String value);

  Future<void> remove(String key);
}

class _SharedPreferencesProgressStorage implements ProgressStorage {
  const _SharedPreferencesProgressStorage(this._preferences);

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> getString(String key) => _preferences.getString(key);

  @override
  Future<void> remove(String key) => _preferences.remove(key);

  @override
  Future<void> setString(String key, String value) =>
      _preferences.setString(key, value);
}
