/// Navigation graph for the prototype application.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/drill/count_drill_screen.dart';
import '../presentation/home/app_shell.dart';
import '../presentation/learn/learning_path_screen.dart';
import '../presentation/learn/lesson_screen.dart';
import '../presentation/profile/progress_screen.dart';
import '../presentation/table/table_screen.dart';

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/learn',
    routes: [
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
