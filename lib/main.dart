import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/analytics/analytics_gateway.dart';
import 'core/analytics/crash_reporter_gateway.dart';
import 'data/content_repository.dart';
import 'data/firebase_telemetry.dart';
import 'data/local_progress_repository.dart';
import 'firebase_options.dart';
import 'viewmodels/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final contentRepository = ContentRepository();
  final progressRepository = LocalProgressRepository();
  final telemetry = await _initializeTelemetry();
  final catalog = await contentRepository.loadEnglishCatalog();
  final progress = await progressRepository.load();
  final appState = AppState(
    catalog: catalog,
    progress: progress,
    progressRepository: progressRepository,
    analytics: telemetry.analytics,
    crashReporter: telemetry.crashReporter,
  );
  await appState.initializeTelemetry();
  await appState.initializeEntitlement();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(
      appState.recordError(
        details.exception,
        details.stack ?? StackTrace.current,
        fatal: true,
      ),
    );
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    unawaited(appState.recordError(error, stackTrace, fatal: true));
    return true;
  };

  runApp(BlackjackTrainerApp(appState: appState));
}

Future<({AnalyticsGateway analytics, CrashReporterGateway crashReporter})>
_initializeTelemetry() async {
  final supportsFirebase =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  if (!supportsFirebase) {
    return (
      analytics: const NoOpAnalyticsGateway(),
      crashReporter: const NoOpCrashReporterGateway(),
    );
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  return (
    analytics: FirebaseAnalyticsGateway(),
    crashReporter: FirebaseCrashReporterGateway(),
  );
}
