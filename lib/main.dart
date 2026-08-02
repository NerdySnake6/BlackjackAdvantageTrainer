import 'package:flutter/material.dart';

import 'app/app.dart';
import 'data/content_repository.dart';
import 'data/local_progress_repository.dart';
import 'viewmodels/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final contentRepository = ContentRepository();
  final progressRepository = LocalProgressRepository();
  final catalog = await contentRepository.loadEnglishCatalog();
  final progress = await progressRepository.load();
  final appState = AppState(
    catalog: catalog,
    progress: progress,
    progressRepository: progressRepository,
  );
  await appState.initializeEntitlement();

  runApp(BlackjackTrainerApp(appState: appState));
}
