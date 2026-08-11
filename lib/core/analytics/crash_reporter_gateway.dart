/// Consent-aware crash-reporting boundary.
library;

abstract interface class CrashReporterGateway {
  Future<void> setCollectionEnabled(bool enabled);

  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
  });
}

class NoOpCrashReporterGateway implements CrashReporterGateway {
  const NoOpCrashReporterGateway();

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
  }) async {}
}

class ConsentAwareCrashReporterGateway implements CrashReporterGateway {
  ConsentAwareCrashReporterGateway(this._delegate);

  final CrashReporterGateway _delegate;
  var _enabled = false;

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    _enabled = enabled;
    await _delegate.setCollectionEnabled(enabled);
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
  }) async {
    if (_enabled) {
      await _delegate.recordError(error, stackTrace, fatal: fatal);
    }
  }
}
