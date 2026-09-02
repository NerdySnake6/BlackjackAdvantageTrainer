/// Progress, mastery, privacy, and prototype reset screen.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../domain/learning/models.dart';
import '../../l10n/app_localizations.dart';
import '../../viewmodels/app_state.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final appState = context.watch<AppState>();
    final progress = appState.progress;

    return Scaffold(
      appBar: AppBar(title: Text(strings.progressTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Text(
              strings.progressSubtitle,
              style: const TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _ProgressStat(
                    icon: Icons.bolt,
                    color: AppColors.gold,
                    value: '${progress.xp}',
                    label: strings.xpLabel,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ProgressStat(
                    icon: Icons.local_fire_department,
                    color: const Color(0xFFFF8A4C),
                    value: '${progress.streakDays}',
                    label: strings.streakLabel,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.privacy_tip_outlined,
                      color: AppColors.mint,
                    ),
                    title: Text(strings.privacyChoicesTitle),
                    subtitle: Text(strings.privacyChoicesSubtitle),
                  ),
                  SwitchListTile(
                    value: progress.analyticsConsent.isGranted,
                    onChanged: (value) => appState.setTelemetryConsent(
                      analyticsEnabled: value,
                      crashReportsEnabled:
                          progress.crashReportsConsent.isGranted,
                    ),
                    title: Text(strings.usageAnalyticsTitle),
                  ),
                  SwitchListTile(
                    value: progress.crashReportsConsent.isGranted,
                    onChanged: (value) => appState.setTelemetryConsent(
                      analyticsEnabled: progress.analyticsConsent.isGranted,
                      crashReportsEnabled: value,
                    ),
                    title: Text(strings.crashReportsTitle),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.experienceSettingTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      strings.experienceSettingSubtitle,
                      style: const TextStyle(color: Colors.white60),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<ExperienceLevel>(
                      initialValue: progress.experienceLevel,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final level in ExperienceLevel.values)
                          DropdownMenuItem(
                            value: level,
                            child: Text(_experienceLabel(strings, level)),
                          ),
                      ],
                      onChanged: (level) {
                        if (level != null) {
                          appState.chooseExperienceLevel(level);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.insights, color: AppColors.mint),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            strings.masteryLabel,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(progress.averageMastery * 100).round()}%',
                          style: const TextStyle(
                            color: AppColors.mint,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(
                      value: progress.averageMastery,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(10),
                      backgroundColor: Colors.white10,
                      color: AppColors.mint,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      strings.lessonsCompleted(
                        appState.completedLessonCount,
                        appState.catalog.lessons.length,
                      ),
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.mint),
                    const SizedBox(height: 12),
                    Text(
                      strings.privacyNote,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      strings.educationDisclaimer,
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _confirmReset(context, appState),
              icon: const Icon(Icons.restart_alt),
              label: Text(strings.resetProgress),
            ),
          ],
        ),
      ),
    );
  }

  String _experienceLabel(AppLocalizations strings, ExperienceLevel level) {
    return switch (level) {
      ExperienceLevel.beginner => strings.beginnerLevelTitle,
      ExperienceLevel.basics => strings.basicsLevelTitle,
      ExperienceLevel.experienced => strings.experiencedLevelTitle,
    };
  }

  Future<void> _confirmReset(BuildContext context, AppState appState) async {
    final strings = AppLocalizations.of(context);
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.resetProgress),
        content: Text(strings.resetConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.reset),
          ),
        ],
      ),
    );
    if (shouldReset ?? false) {
      await appState.resetProgress();
    }
  }
}

class _ProgressStat extends StatelessWidget {
  const _ProgressStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
