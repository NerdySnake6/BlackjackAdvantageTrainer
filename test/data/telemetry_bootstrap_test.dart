import 'package:blackjack_advantage_trainer/core/analytics/analytics_gateway.dart';
import 'package:blackjack_advantage_trainer/core/analytics/crash_reporter_gateway.dart';
import 'package:blackjack_advantage_trainer/data/telemetry_bootstrap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unsupported platforms use no-op gateways', () async {
    var initialized = false;

    final gateways = await initializeTelemetryGateways(
      supportsFirebase: false,
      initializeFirebase: () async => initialized = true,
      createAnalytics: _Analytics.new,
      createCrashReporter: _CrashReporter.new,
    );

    expect(initialized, isFalse);
    expect(gateways.analytics, isA<NoOpAnalyticsGateway>());
    expect(gateways.crashReporter, isA<NoOpCrashReporterGateway>());
  });

  test(
    'Firebase initialization failure falls back to no-op gateways',
    () async {
      final gateways = await initializeTelemetryGateways(
        supportsFirebase: true,
        initializeFirebase: () => Future<void>.error(StateError('offline')),
        createAnalytics: _Analytics.new,
        createCrashReporter: _CrashReporter.new,
      );

      expect(gateways.analytics, isA<NoOpAnalyticsGateway>());
      expect(gateways.crashReporter, isA<NoOpCrashReporterGateway>());
    },
  );

  test('successful initialization creates production gateways', () async {
    final gateways = await initializeTelemetryGateways(
      supportsFirebase: true,
      initializeFirebase: () async {},
      createAnalytics: _Analytics.new,
      createCrashReporter: _CrashReporter.new,
    );

    expect(gateways.analytics, isA<_Analytics>());
    expect(gateways.crashReporter, isA<_CrashReporter>());
  });
}

class _Analytics extends NoOpAnalyticsGateway {}

class _CrashReporter extends NoOpCrashReporterGateway {}
