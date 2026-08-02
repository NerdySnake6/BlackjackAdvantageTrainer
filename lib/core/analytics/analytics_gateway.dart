/// Consent-aware analytics boundary; no telemetry is sent by the prototype.
library;

abstract interface class AnalyticsGateway {
  Future<void> track(
    String eventName, [
    Map<String, Object?> parameters = const {},
  ]);
}

class NoOpAnalyticsGateway implements AnalyticsGateway {
  const NoOpAnalyticsGateway();

  @override
  Future<void> track(
    String eventName, [
    Map<String, Object?> parameters = const {},
  ]) async {}
}
