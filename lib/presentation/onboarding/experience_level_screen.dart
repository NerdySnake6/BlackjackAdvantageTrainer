/// First-launch experience-level selection.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../domain/learning/models.dart';
import '../../l10n/app_localizations.dart';
import '../../viewmodels/app_state.dart';

class ExperienceLevelScreen extends StatelessWidget {
  const ExperienceLevelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 380 ? 16.0 : 24.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                28,
                horizontalPadding,
                32,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      strings.experienceLevelTitle,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      strings.experienceLevelSubtitle,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 28),
                    _ExperienceLevelCard(
                      level: ExperienceLevel.beginner,
                      icon: Icons.school_outlined,
                      title: strings.beginnerLevelTitle,
                      description: strings.beginnerLevelDescription,
                    ),
                    const SizedBox(height: 12),
                    _ExperienceLevelCard(
                      level: ExperienceLevel.basics,
                      icon: Icons.auto_stories_outlined,
                      title: strings.basicsLevelTitle,
                      description: strings.basicsLevelDescription,
                    ),
                    const SizedBox(height: 12),
                    _ExperienceLevelCard(
                      level: ExperienceLevel.experienced,
                      icon: Icons.speed_outlined,
                      title: strings.experiencedLevelTitle,
                      description: strings.experiencedLevelDescription,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      strings.experienceLevelNote,
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ExperienceLevelCard extends StatelessWidget {
  const _ExperienceLevelCard({
    required this.level,
    required this.icon,
    required this.title,
    required this.description,
  });

  final ExperienceLevel level;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        await context.read<AppState>().chooseExperienceLevel(level);
        if (context.mounted) {
          context.go('/learn');
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.mint.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.mint.withValues(alpha: 0.18),
              foregroundColor: AppColors.mint,
              child: Icon(icon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.mint),
          ],
        ),
      ),
    );
  }
}
