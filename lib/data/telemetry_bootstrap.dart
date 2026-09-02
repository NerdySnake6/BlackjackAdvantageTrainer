/// Fault-tolerant telemetry initialization.
library;

import '../core/analytics/analytics_gateway.dart';
import '../core/analytics/crash_reporter_gateway.dart';

/// Analytics and crash-reporting gateways used by the application.
class TelemetryGateways {
  const TelemetryGateways({
    required this.analytics,
    required this.crashReporter,
  });

  final AnalyticsGateway analytics;
  final CrashReporterGateway crashReporter;
}

/// Initializes optional telemetry without making it a startup dependency.
Future<TelemetryGateways> initializeTelemetryGateways({
  required bool supportsFirebase,
  required Future<void> Function() initializeFirebase,
  required AnalyticsGateway Function() createAnalytics,
  required CrashReporterGateway Function() createCrashReporter,
}) async {
  if (!supportsFirebase) {
    return const TelemetryGateways(
      analytics: NoOpAnalyticsGateway(),
      crashReporter: NoOpCrashReporterGateway(),
    );
  }

  try {
    await initializeFirebase();
    return TelemetryGateways(
      analytics: createAnalytics(),
      crashReporter: createCrashReporter(),
    );
  } on Object {
    return const TelemetryGateways(
      analytics: NoOpAnalyticsGateway(),
      crashReporter: NoOpCrashReporterGateway(),
    );
  }
}
