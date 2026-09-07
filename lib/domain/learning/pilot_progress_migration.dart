/// Lossless, idempotent migration of compatible legacy pilot sessions.
library;

import 'decision_lesson.dart';
import 'models.dart';

class PilotProgressMigration {
  const PilotProgressMigration();

  ProgressSnapshot migrate(ProgressSnapshot progress, CourseCatalog catalog) {
    final sessions = Map<String, Map<String, Object?>>.of(
      progress.pilotSessions,
    );
    var changed = false;
    for (final lesson in catalog.playableLessons) {
      final saved = sessions[lesson.id];
      if (saved == null || saved['schema'] != 1) continue;
      try {
        sessions[lesson.id] = DecisionLessonSession.restore(
          lesson,
          saved,
        ).toJson();
        changed = true;
      } on FormatException {
        // Keep incompatible state for the existing explicit per-lesson restart.
      }
    }
    return changed ? progress.copyWith(pilotSessions: sessions) : progress;
  }
}
