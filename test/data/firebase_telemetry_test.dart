import 'package:blackjack_advantage_trainer/data/firebase_telemetry.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAnalytics implements FirebaseAnalytics {
  bool? collectionEnabled;
  String? userPropertyName;
  String? userPropertyValue;
  String? loggedEventName;
  Map<String, Object?>? loggedEventParams;

  @override
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    collectionEnabled = enabled;
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
    AnalyticsCallOptions? callOptions,
  }) async {
    userPropertyName = name;
    userPropertyValue = value;
  }

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object?>? parameters,
    AnalyticsCallOptions? callOptions,
    List<AnalyticsEventItem>? items,
  }) async {
    loggedEventName = name;
    loggedEventParams = parameters;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCrashlytics implements FirebaseCrashlytics {
  bool? collectionEnabled;
  bool unsentReportsDeleted = false;
  Object? recordedError;
  StackTrace? recordedStackTrace;
  bool? recordedFatal;

  @override
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    collectionEnabled = enabled;
  }

  @override
  Future<void> deleteUnsentReports() async {
    unsentReportsDeleted = true;
  }

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    Iterable<Object> information = const [],
    bool? printDetails,
    bool? fatal = false,
  }) async {
    recordedError = exception;
    recordedStackTrace = stack;
    recordedFatal = fatal;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('FirebaseAnalyticsGateway', () {
    test('setCollectionEnabled forwards to FirebaseAnalytics', () async {
      final fake = _FakeAnalytics();
      final gateway = FirebaseAnalyticsGateway(analytics: fake);

      await gateway.setCollectionEnabled(true);
      expect(fake.collectionEnabled, isTrue);

      await gateway.setCollectionEnabled(false);
      expect(fake.collectionEnabled, isFalse);
    });

    test('setUserProperty forwards name and value', () async {
      final fake = _FakeAnalytics();
      final gateway = FirebaseAnalyticsGateway(analytics: fake);

      await gateway.setUserProperty('experience_level', 'beginner');
      expect(fake.userPropertyName, 'experience_level');
      expect(fake.userPropertyValue, 'beginner');

      await gateway.setUserProperty('experience_level', null);
      expect(fake.userPropertyValue, isNull);
    });

    test(
      'track maps booleans to 1/0, preserves numbers and strings, ignores unmapped types',
      () async {
        final fake = _FakeAnalytics();
        final gateway = FirebaseAnalyticsGateway(analytics: fake);

        await gateway.track('test_event', {
          'flag_true': true,
          'flag_false': false,
          'count': 42,
          'ratio': 0.85,
          'title': 'hello',
          'unsupported': <String>['array', 'not', 'mapped'],
        });

        expect(fake.loggedEventName, 'test_event');
        expect(fake.loggedEventParams, {
          'flag_true': 1,
          'flag_false': 0,
          'count': 42,
          'ratio': 0.85,
          'title': 'hello',
        });
      },
    );

    test('track passes null parameters when map is empty', () async {
      final fake = _FakeAnalytics();
      final gateway = FirebaseAnalyticsGateway(analytics: fake);

      await gateway.track('empty_event');
      expect(fake.loggedEventName, 'empty_event');
      expect(fake.loggedEventParams, isNull);
    });
  });

  group('FirebaseCrashReporterGateway', () {
    test(
      'setCollectionEnabled forwards and deletes unsent reports when disabled',
      () async {
        final fake = _FakeCrashlytics();
        final gateway = FirebaseCrashReporterGateway(crashlytics: fake);

        await gateway.setCollectionEnabled(true);
        expect(fake.collectionEnabled, isTrue);
        expect(fake.unsentReportsDeleted, isFalse);

        await gateway.setCollectionEnabled(false);
        expect(fake.collectionEnabled, isFalse);
        expect(fake.unsentReportsDeleted, isTrue);
      },
    );

    test(
      'recordError forwards exception, stacktrace, and fatal flag',
      () async {
        final fake = _FakeCrashlytics();
        final gateway = FirebaseCrashReporterGateway(crashlytics: fake);

        final error = Exception('test crash');
        final stack = StackTrace.current;

        await gateway.recordError(error, stack, fatal: true);
        expect(fake.recordedError, error);
        expect(fake.recordedStackTrace, stack);
        expect(fake.recordedFatal, isTrue);

        await gateway.recordError(error, stack, fatal: false);
        expect(fake.recordedFatal, isFalse);
      },
    );
  });
}
