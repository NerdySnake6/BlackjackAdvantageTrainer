/// Navigation graph for the prototype application.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/drill/count_drill_screen.dart';
import '../presentation/home/app_shell.dart';
import '../presentation/learn/learning_path_screen.dart';
import '../presentation/learn/lesson_screen.dart';
import '../presentation/onboarding/experience_level_screen.dart';
import '../presentation/profile/progress_screen.dart';
import '../presentation/table/table_screen.dart';
import '../viewmodels/app_state.dart';

GoRouter createRouter({required AppState appState}) {
  return GoRouter(
    initialLocation: '/learn',
    refreshListenable: appState,
    redirect: (context, state) {
      final isOnboarding = state.matchedLocation == '/onboarding';
      if (!appState.hasExperienceLevel && !isOnboarding) {
        return '/onboarding';
      }
      if (appState.hasExperienceLevel && isOnboarding) {
        return '/learn';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const ExperienceLevelScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/learn',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: LearningPathScreen()),
          ),
          GoRoute(
            path: '/drill',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CountDrillScreen()),
          ),
          GoRoute(
            path: '/table',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TableScreen()),
          ),
          GoRoute(
            path: '/progress',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProgressScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/lesson/:lessonId',
        builder: (context, state) =>
            LessonScreen(lessonId: state.pathParameters['lessonId']!),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text(state.error.toString()))),
  );
}
