/// Consent-aware analytics boundary; no telemetry is sent by the prototype.
library;

abstract interface class AnalyticsGateway {
  Future<void> setCollectionEnabled(bool enabled);

  Future<void> track(
    String eventName, [
    Map<String, Object?> parameters = const {},
  ]);
}

class NoOpAnalyticsGateway implements AnalyticsGateway {
  const NoOpAnalyticsGateway();

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}

  @override
  Future<void> track(
    String eventName, [
    Map<String, Object?> parameters = const {},
  ]) async {}
}

class ConsentAwareAnalyticsGateway implements AnalyticsGateway {
  ConsentAwareAnalyticsGateway(this._delegate);

  final AnalyticsGateway _delegate;
  var _enabled = false;

  static const _allowedEvents = {
    'experience_level_selected',
    'lesson_started',
    'lesson_completed',
    'exercise_answered',
    'drill_started',
    'drill_completed',
    'table_round_started',
    'table_session_completed',
    'strategy_decision',
    'count_check',
    'quick_review_started',
    'quick_review_answered',
    'quick_review_completed',
  };

  static const _allowedParameterKeys = {
    'lesson_id',
    'exercise_id',
    'experience_level',
    'session_type',
    'is_correct',
    'score_percent',
    'cards_seen',
    'round_number',
    'rounds_completed',
    'exercise_count',
    'correct_answers',
    'strategy_correct',
    'strategy_total',
    'count_correct',
    'count_total',
  };

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    _enabled = enabled;
    await _delegate.setCollectionEnabled(enabled);
  }

  @override
  Future<void> track(
    String eventName, [
    Map<String, Object?> parameters = const {},
  ]) async {
    if (!_enabled || !_allowedEvents.contains(eventName)) {
      return;
    }
    final safeParameters = {
      for (final entry in parameters.entries)
        if (_allowedParameterKeys.contains(entry.key) &&
            _isSupportedValue(entry.value))
          entry.key: entry.value,
    };
    await _delegate.track(eventName, safeParameters);
  }

  bool _isSupportedValue(Object? value) =>
      value is String || value is int || value is double || value is bool;
}
