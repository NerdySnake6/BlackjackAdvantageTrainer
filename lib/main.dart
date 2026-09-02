import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'data/content_repository.dart';
import 'data/firebase_telemetry.dart';
import 'data/local_progress_repository.dart';
import 'data/telemetry_bootstrap.dart';
import 'firebase_options.dart';
import 'viewmodels/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final contentRepository = ContentRepository();
  final progressRepository = LocalProgressRepository();
  final supportsFirebase =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  final telemetry = await initializeTelemetryGateways(
    supportsFirebase: supportsFirebase,
    initializeFirebase: () =>
        Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    createAnalytics: FirebaseAnalyticsGateway.new,
    createCrashReporter: FirebaseCrashReporterGateway.new,
  );
  final catalog = await contentRepository.loadCatalog(
    localeCode: PlatformDispatcher.instance.locale.languageCode,
  );
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
