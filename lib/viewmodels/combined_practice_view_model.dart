/// Coordinates saved joint practice and optional foreground-only active time.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../domain/learning/combined_practice.dart';
import 'app_state.dart';

class CombinedPracticeViewModel extends ChangeNotifier
    with WidgetsBindingObserver {
  CombinedPracticeViewModel(this.appState, {Stopwatch? stopwatch})
    : _watch = stopwatch ?? Stopwatch() {
    _session = CombinedPracticeSession(
      appState.catalog,
      week: CombinedPracticeSession.weekOf(appState.studyDate),
    );
    final records = appState.progress.combinedPracticeSessions;
    for (final raw in records.values) {
      try {
        final old = CombinedPracticeSession.restore(appState.catalog, raw);
        if (old.started && !old.complete) {
          _session = old;
          break;
        }
      } on FormatException {
        // The current week's screen offers an explicit restart.
      }
    }
    final saved = records[session.week];
    if (saved != null) {
      try {
        _session = CombinedPracticeSession.restore(appState.catalog, saved);
      } on FormatException {
        incompatible = true;
      }
    }
    WidgetsBinding.instance.addObserver(this);
    if (session.timed && session.active && !incompatible) _watch.start();
  }
  final AppState appState;
  final Stopwatch _watch;
  late CombinedPracticeSession _session;
  bool busy = false;
  bool saveFailed = false;
  bool incompatible = false;
  bool _foreground = true;
  bool _disposed = false;
  CombinedPracticeSession get session => _session;
  Future<void> begin() => _change((s) => s.begin());
  Future<void> reveal() => _change((s) => s.reveal());
  Future<void> choose(String value) => _change((s) => s.choose(value));
  Future<void> adjust(int delta) => _change((s) => s.adjust(delta));
  Future<void> answer() => _change((s) => s.answer());
  Future<void> next() => _change((s) => s.next());
  Future<void> restart({bool? timed}) async {
    if (busy || (!session.complete && session.started && !incompatible)) return;
    final week = session.complete
        ? CombinedPracticeSession.weekOf(appState.studyDate)
        : session.week;
    final raw = appState.progress.combinedPracticeSessions[week];
    final attempt = week == session.week
        ? session.attempt + 1
        : raw?['attempt'] is int
        ? (raw!['attempt'] as int) + 1
        : 1;
    await _save(
      CombinedPracticeSession(
        appState.catalog,
        week: week,
        attempt: attempt,
        timed: timed ?? session.timed,
      ),
    );
  }

  Future<void> pause() async {
    _foreground = false;
    _watch.stop();
    if (!incompatible && session.active) await _change((_) {});
  }

  void resume() {
    _foreground = true;
    if (!busy && session.timed && session.active && !incompatible) {
      _watch.start();
    }
  }

  Future<void> _change(void Function(CombinedPracticeSession) action) async {
    if (busy || incompatible || _disposed) return;
    _watch.stop();
    final next = CombinedPracticeSession.restore(
      appState.catalog,
      session.toJson(),
    );
    next.addTime(_watch.elapsedMilliseconds);
    action(next);
    await _save(next);
  }

  Future<void> _save(CombinedPracticeSession next) async {
    if (busy || _disposed) return;
    busy = true;
    _watch.stop();
    _notify();
    try {
      await appState.saveCombinedPractice(next);
      _session = CombinedPracticeSession.restore(
        appState.catalog,
        appState.progress.combinedPracticeSessions[next.week]!,
      );
      _watch.reset();
      saveFailed = false;
      incompatible = false;
    } catch (_) {
      saveFailed = true;
    } finally {
      busy = false;
      if (_foreground && !_disposed) resume();
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      resume();
    } else {
      unawaited(pause());
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _watch.stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
