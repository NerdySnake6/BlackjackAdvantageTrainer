/// Persistence contract for locale-independent learning progress.
library;

import '../../domain/learning/models.dart';

abstract interface class ProgressRepository {
  Future<ProgressSnapshot> load();
  Future<void> save(ProgressSnapshot snapshot);
  Future<void> clear();
}
