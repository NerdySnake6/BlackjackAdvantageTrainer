/// Persists timed count evidence, pausing during storage and app background.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../domain/learning/count_certification.dart';
import 'app_state.dart';

class CountCertificationViewModel extends ChangeNotifier
    with WidgetsBindingObserver {
  CountCertificationViewModel(this.appState, {Stopwatch? stopwatch})
    : _watch = stopwatch ?? Stopwatch() {
    final saved = appState.progress.masteryChecks['running-count-speed'];
    _session = CountCertificationSession(
      seed: Random.secure().nextInt(0x7fffffff),
    );
    if (saved != null) {
      try {
        _session = CountCertificationSession.restore(saved);
      } on FormatException {
        incompatible = true;
      }
    }
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_foreground && session.active) unawaited(tick());
    });
    if (session.active && !incompatible) _watch.start();
  }

  final AppState appState;
  late CountCertificationSession _session;
  final Stopwatch _watch;
  late final Timer _timer;
  bool busy = false;
  bool saveFailed = false;
  bool incompatible = false;
  bool _foreground = true;
  bool _disposed = false;
  CountCertificationSession get session => _session;

  Future<void> begin() => _change((next) => next.begin());
  Future<void> reveal() => _change((next) => next.reveal());
  Future<void> adjust(int delta) => _change((next) => next.adjust(delta));
  Future<void> answer() => _change((next) => next.answer());
  Future<void> tick() => session.active ? _change((_) {}) : Future.value();
  Future<void> pause() async {
    _foreground = false;
    _watch.stop();
    await tick();
  }

  void resume() {
    _foreground = true;
    if (session.active && !busy && !incompatible) _watch.start();
  }

  Future<void> restart() async {
    if (busy || (!session.failed && !incompatible)) return;
    await _save(
      CountCertificationSession(
        seed: Random.secure().nextInt(0x7fffffff),
        attempt: session.attempt + 1,
      ),
    );
  }

  Future<void> _change(void Function(CountCertificationSession) action) async {
    if (busy || incompatible || _disposed) return;
    _watch.stop();
    final next = CountCertificationSession.restore(session.toJson());
    next.addTime(_watch.elapsedMilliseconds);
    if (!next.failed) action(next);
    await _save(next);
  }

  Future<void> _save(CountCertificationSession next) async {
    busy = true;
    _watch.stop();
    _notify();
    try {
      await appState.saveCountCertification(next);
      _session = CountCertificationSession.restore(next.toJson());
      _watch.reset();
      incompatible = false;
      saveFailed = false;
    } catch (_) {
      saveFailed = true;
    } finally {
      busy = false;
      if (session.active && _foreground && !_disposed && !incompatible) {
        _watch.start();
      }
      _notify();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      resume();
    } else {
      unawaited(pause());
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer.cancel();
    _watch.stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
