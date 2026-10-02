/// Saves a single Learn review without using the legacy Quick Review queue.
library;

import 'package:flutter/foundation.dart';

import '../domain/learning/learn_review.dart';
import '../domain/learning/pilot_lesson.dart';
import 'app_state.dart';

class LearnReviewViewModel extends ChangeNotifier {
  LearnReviewViewModel({required this.appState, required this.lesson}) {
    var attempt = 0;
    final schedule = appState.progress.learnReviews[lesson.id];
    if (schedule != null) {
      try {
        attempt = LearnReviewSchedule.fromJson(schedule).runs;
      } on FormatException {
        // Keep other progress intact when one review date is damaged.
      }
    }
    _session = LearnReviewSession(lesson, attempt: attempt);
    final saved = appState.progress.learnReviewSessions[lesson.id];
    if (saved != null) {
      try {
        final old = LearnReviewSession.restore(lesson, saved);
        if (!old.complete || old.attempt >= attempt) _session = old;
      } on FormatException {
        incompatible = true;
      }
    }
  }
  final AppState appState;
  final PilotLesson lesson;
  late LearnReviewSession _session;
  bool busy = false;
  bool saveFailed = false;
  bool incompatible = false;
  bool _disposed = false;
  LearnReviewSession get session => _session;
  Future<void> reveal() => _change((next) => next.reveal());
  Future<void> adjust(int delta) => _change((next) => next.adjust(delta));
  Future<void> answer(String value) => _change((next) => next.submit(value));
  Future<void> restart() =>
      _save(LearnReviewSession(lesson, attempt: session.attempt + 1));
  Future<void> _change(void Function(LearnReviewSession) action) async {
    if (busy || incompatible) return;
    final next = LearnReviewSession.restore(lesson, session.toJson());
    action(next);
    await _save(next);
  }

  Future<void> _save(LearnReviewSession next) async {
    if (busy) return;
    busy = true;
    saveFailed = false;
    _notify();
    try {
      await appState.saveLearnReview(next);
      _session = LearnReviewSession.restore(
        lesson,
        appState.progress.learnReviewSessions[lesson.id]!,
      );
      incompatible = false;
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
