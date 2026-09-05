/// Coordinates pilot sessions and writes every accepted interaction before exit.
library;

import 'package:flutter/foundation.dart';

import '../domain/learning/decision_lesson.dart';
import '../domain/learning/pilot_lesson.dart';
import 'app_state.dart';

class PilotLessonViewModel extends ChangeNotifier {
  PilotLessonViewModel({required this.appState, required this.lesson}) {
    final saved = appState.progress.pilotSessions[lesson.id];
    try {
      _session = saved == null
          ? DecisionLessonSession(lesson)
          : DecisionLessonSession.restore(lesson, saved);
    } catch (_) {
      incompatibleSave = true;
      _session = DecisionLessonSession(lesson);
    }
  }

  final AppState appState;
  final PilotLesson lesson;
  late DecisionLessonSession _session;
  bool busy = false;
  bool saveFailed = false;
  bool incompatibleSave = false;
  bool _disposed = false;

  DecisionLessonSession get session => _session;

  Future<void> begin() => _change((next) => next.begin());
  Future<void> reveal() => _change((next) => next.reveal());
  Future<void> hint() => _change((next) => next.useHint());
  Future<void> adjustCount(int delta) =>
      _change((next) => next.adjustCount(delta));
  Future<void> answer(String answer) => _change((next) => next.answer(answer));
  Future<void> next() => _change((next) => next.next());

  Future<void> restart() async {
    if (busy) return;
    final saved = appState.progress.pilotSessions[lesson.id];
    final attempt = saved?['attempt'];
    await _save(
      DecisionLessonSession(lesson, attempt: attempt is int ? attempt + 1 : 1),
    );
  }

  Future<void> _change(void Function(DecisionLessonSession) change) async {
    if (busy || incompatibleSave) return;
    final next = DecisionLessonSession.restore(lesson, _session.toJson());
    change(next);
    await _save(next);
  }

  Future<void> _save(DecisionLessonSession next) async {
    busy = true;
    saveFailed = false;
    _notify();
    try {
      await appState.savePilotSession(next);
      // Read the persisted reward flag, including idempotent completion calls.
      _session = DecisionLessonSession.restore(
        lesson,
        appState.progress.pilotSessions[lesson.id]!,
      );
      incompatibleSave = false;
    } catch (_) {
      saveFailed = true;
    } finally {
      busy = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
