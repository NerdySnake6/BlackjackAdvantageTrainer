import 'package:blackjack_advantage_trainer/data/local_progress_repository.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('saves, loads, and clears progress', () async {
    final storage = _MemoryProgressStorage();
    final repository = LocalProgressRepository.withStorage(storage);
    final snapshot = ProgressSnapshot(
      lessonScores: const {'quick-start': 0.9},
      experienceLevel: ExperienceLevel.basics,
      xp: 120,
      lastActivityDate: DateTime.utc(2026, 9, 2),
    );

    await repository.save(snapshot);
    final loaded = await repository.load();

    expect(loaded.lessonScores, snapshot.lessonScores);
    expect(loaded.experienceLevel, ExperienceLevel.basics);
    expect(loaded.xp, 120);
    await repository.clear();
    expect((await repository.load()).lessonScores, isEmpty);
  });

  test('loads an older snapshot with safe defaults', () async {
    final storage = _MemoryProgressStorage({
      'learning_progress_v1': '{"lessonScores":{"quick-start":1.0}}',
    });

    final loaded = await LocalProgressRepository.withStorage(storage).load();

    expect(loaded.lessonScores['quick-start'], 1);
    expect(loaded.exerciseReviewStates, isEmpty);
    expect(loaded.analyticsConsent.isGranted, isFalse);
    expect(loaded.hasSeenTelemetryConsent, isFalse);
  });

  test('quarantines corrupt JSON and starts with empty progress', () async {
    const corrupt = '{ definitely-not-json';
    final storage = _MemoryProgressStorage({'learning_progress_v1': corrupt});

    final loaded = await LocalProgressRepository.withStorage(storage).load();

    expect(loaded.lessonScores, isEmpty);
    expect(await storage.getString('learning_progress_v1'), isNull);
    expect(await storage.getString('learning_progress_corrupt_v1'), corrupt);
  });
}

class _MemoryProgressStorage implements ProgressStorage {
  _MemoryProgressStorage([Map<String, String>? initial])
    : values = {...?initial};

  final Map<String, String> values;

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }
}
