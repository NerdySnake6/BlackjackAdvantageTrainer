import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../core/analytics/analytics_gateway.dart';
import '../core/analytics/crash_reporter_gateway.dart';

class FirebaseAnalyticsGateway implements AnalyticsGateway {
  FirebaseAnalyticsGateway({FirebaseAnalytics? analytics})
    : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  @override
  Future<void> setCollectionEnabled(bool enabled) {
    return _analytics.setAnalyticsCollectionEnabled(enabled);
  }

  @override
  Future<void> setUserProperty(String name, String? value) {
    return _analytics.setUserProperty(name: name, value: value);
  }

  @override
  Future<void> track(
    String eventName, [
    Map<String, Object?> parameters = const {},
  ]) {
    final firebaseParameters = <String, Object>{};
    for (final entry in parameters.entries) {
      final value = entry.value;
      if (value is bool) {
        firebaseParameters[entry.key] = value ? 1 : 0;
      } else if (value is String) {
        firebaseParameters[entry.key] = value;
      } else if (value is num) {
        firebaseParameters[entry.key] = value;
      }
    }
    return _analytics.logEvent(
      name: eventName,
      parameters: firebaseParameters.isEmpty ? null : firebaseParameters,
    );
  }
}

class FirebaseCrashReporterGateway implements CrashReporterGateway {
  FirebaseCrashReporterGateway({FirebaseCrashlytics? crashlytics})
    : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
    if (!enabled) {
      await _crashlytics.deleteUnsentReports();
    }
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
  }) {
    return _crashlytics.recordError(
      error,
      stackTrace,
      fatal: fatal,
      printDetails: false,
    );
  }
}
