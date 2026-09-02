import 'package:blackjack_advantage_trainer/core/analytics/analytics_gateway.dart';
import 'package:blackjack_advantage_trainer/core/analytics/crash_reporter_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConsentAwareAnalyticsGateway', () {
    test('blocks collection before consent and filters payloads', () async {
      final delegate = _RecordingAnalytics();
      final gateway = ConsentAwareAnalyticsGateway(delegate);

      await gateway.track('lesson_started', {'lesson_id': 'quick-start'});
      await gateway.setUserProperty('experience_level', 'beginner');
      expect(delegate.events, isEmpty);
      expect(delegate.properties, isEmpty);

      await gateway.setCollectionEnabled(true);
      await gateway.setUserProperty('experience_level', 'experienced');
      await gateway.setUserProperty('email', 'private@example.com');
      await gateway.track('exercise_answered', {
        'exercise_id': 'stable-id',
        'is_correct': true,
        'answer_text': 'private answer',
        'card_sequence': 'AS-KH',
        'email': 'private@example.com',
        'unknown': 42,
      });
      await gateway.track('unknown_event', {'lesson_id': 'quick-start'});

      expect(delegate.properties, {'experience_level': 'experienced'});
      expect(delegate.events, hasLength(1));
      expect(delegate.events.single.$1, 'exercise_answered');
      expect(delegate.events.single.$2, {
        'exercise_id': 'stable-id',
        'is_correct': true,
      });
    });

    test('supports the canonical training completion event', () async {
      final delegate = _RecordingAnalytics();
      final gateway = ConsentAwareAnalyticsGateway(delegate);
      await gateway.setCollectionEnabled(true);

      await gateway.track('training_session_completed', {
        'session_type': 'table',
        'rounds_completed': 5,
        'strategy_correct': 8,
        'strategy_total': 10,
      });

      expect(delegate.events.single.$1, 'training_session_completed');
      expect(delegate.events.single.$2['session_type'], 'table');
    });
  });

  group('ConsentAwareCrashReporterGateway', () {
    test('records only while crash consent is enabled', () async {
      final delegate = _RecordingCrashes();
      final gateway = ConsentAwareCrashReporterGateway(delegate);

      await gateway.recordError(StateError('blocked'), StackTrace.current);
      await gateway.setCollectionEnabled(true);
      await gateway.recordError(
        StateError('allowed'),
        StackTrace.current,
        fatal: true,
      );
      await gateway.setCollectionEnabled(false);
      await gateway.recordError(
        StateError('blocked again'),
        StackTrace.current,
      );

      expect(delegate.errors, hasLength(1));
      expect(delegate.fatalValues, [true]);
    });
  });
}

class _RecordingAnalytics implements AnalyticsGateway {
  final events = <(String, Map<String, Object?>)>[];
  final properties = <String, String?>{};

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setUserProperty(String name, String? value) async {
    properties[name] = value;
  }

  @override
  Future<void> track(
    String eventName, [
    Map<String, Object?> parameters = const {},
  ]) async {
    events.add((eventName, parameters));
  }
}

class _RecordingCrashes implements CrashReporterGateway {
  final errors = <Object>[];
  final fatalValues = <bool>[];

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
  }) async {
    errors.add(error);
    fatalValues.add(fatal);
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}
}
