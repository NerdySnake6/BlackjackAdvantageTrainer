/// Persists every checkpoint interaction, without changing lesson rewards.
library;

import 'package:flutter/foundation.dart';

import '../domain/learning/mastery_check.dart';
import 'app_state.dart';

class MasteryCheckViewModel extends ChangeNotifier {
  MasteryCheckViewModel({required this.appState, required this.lessonId}) {
    final saved = appState.progress.masteryChecks[lessonId];
    _session = MasteryCheckSession(lessonId);
    if (saved != null) {
      try {
        _session = MasteryCheckSession.restore(lessonId, saved);
        started = true;
      } on FormatException {
        incompatibleSave = true;
      }
    }
  }

  final AppState appState;
  final String lessonId;
  late MasteryCheckSession _session;
  bool started = false;
  bool busy = false;
  bool saveFailed = false;
  bool incompatibleSave = false;
  bool _disposed = false;

  MasteryCheckSession get session => _session;
  bool get hasNextForm =>
      session.complete &&
      !session.passed &&
      session.form + 1 < MasteryCheckBank.formCount;

  Future<void> begin() => _save(_session);
  Future<void> nextForm() async {
    if (!hasNextForm) return;
    await _save(MasteryCheckSession(lessonId, form: session.form + 1));
  }

  Future<void> reveal() => _change((next) => next.reveal());
  Future<void> adjustCount(int delta) => _change((next) => next.adjust(delta));
  Future<void> answer(String value) => _change((next) => next.answer(value));

  Future<void> _change(void Function(MasteryCheckSession) action) async {
    if (busy || incompatibleSave || !started) return;
    final next = MasteryCheckSession.restore(lessonId, session.toJson());
    action(next);
    await _save(next);
  }

  Future<void> _save(MasteryCheckSession next) async {
    if (busy || incompatibleSave) return;
    busy = true;
    saveFailed = false;
    _notify();
    try {
      await appState.saveMasteryCheck(next);
      _session = MasteryCheckSession.restore(
        lessonId,
        appState.progress.masteryChecks[lessonId]!,
      );
      started = true;
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
