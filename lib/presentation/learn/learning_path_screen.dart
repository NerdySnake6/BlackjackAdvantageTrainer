/// Duolingo-style vertical map for the prototype course.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../domain/learning/models.dart';
import '../../l10n/app_localizations.dart';
import '../../viewmodels/app_state.dart';

class LearningPathScreen extends StatelessWidget {
  const LearningPathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final appState = context.watch<AppState>();
    final section = appState.catalog.sections.first;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            sliver: SliverToBoxAdapter(child: _PathHeader(appState: appState)),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.feltLight, AppColors.felt],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.freeLabel,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      section.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      section.summary,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            sliver: SliverList.separated(
              itemCount: section.lessons.length,
              separatorBuilder: (context, index) => const _PathConnector(),
              itemBuilder: (context, index) {
                final lesson = section.lessons[index];
                return _LessonNode(
                  index: index,
                  lesson: lesson,
                  unlocked: appState.isLessonUnlocked(lesson.id),
                  completed: appState.isLessonCompleted(lesson.id),
                  score: appState.progress.lessonScores[lesson.id],
                  hasSession: appState.sessionFor(lesson.id) != null,
                );
              },
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            sliver: SliverToBoxAdapter(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.ink,
                        child: Icon(Icons.workspace_premium),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.proLabel,
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(strings.proComingSoon),
                          ],
                        ),
                      ),
                      const Icon(Icons.lock_outline, color: Colors.white38),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PathHeader extends StatelessWidget {
  const _PathHeader({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.learningPath,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.learningPathSubtitle,
                    style: const TextStyle(color: Colors.white60),
                  ),
                ],
              ),
            ),
            _StatPill(icon: Icons.bolt, value: '${appState.progress.xp}'),
            const SizedBox(width: 8),
            _StatPill(
              icon: Icons.local_fire_department,
              value: '${appState.progress.streakDays}',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          strings.prototypeBuild,
          style: const TextStyle(
            color: AppColors.mint,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.gold),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _PathConnector extends StatelessWidget {
  const _PathConnector();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 3,
        height: 22,
        margin: const EdgeInsets.only(left: 27),
        color: Colors.white12,
      ),
    );
  }
}

class _LessonNode extends StatelessWidget {
  const _LessonNode({
    required this.index,
    required this.lesson,
    required this.unlocked,
    required this.completed,
    required this.score,
    required this.hasSession,
  });

  final int index;
  final LessonDefinition lesson;
  final bool unlocked;
  final bool completed;
  final double? score;
  final bool hasSession;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final nodeColor = completed
        ? AppColors.mint
        : unlocked
        ? AppColors.gold
        : Colors.white24;

    return InkWell(
      onTap: unlocked ? () => context.push('/lesson/${lesson.id}') : null,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: unlocked
              ? Colors.white.withValues(alpha: 0.055)
              : Colors.white.withValues(alpha: 0.025),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: nodeColor.withValues(alpha: 0.38)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: nodeColor.withValues(alpha: unlocked ? 1 : 0.35),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: completed
                  ? const Icon(Icons.check, color: AppColors.ink, size: 30)
                  : unlocked
                  ? Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    )
                  : const Icon(Icons.lock_outline, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    lesson.subtitle,
                    style: TextStyle(
                      color: unlocked ? Colors.white60 : Colors.white30,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 14, color: nodeColor),
                      const SizedBox(width: 4),
                      Text(
                        strings.minutesShort(lesson.estimatedMinutes),
                        style: TextStyle(
                          color: nodeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (completed && score != null) ...[
                        const SizedBox(width: 10),
                        Text(
                          '${(score! * 100).round()}%',
                          style: const TextStyle(
                            color: AppColors.mint,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ] else if (hasSession) ...[
                        const SizedBox(width: 10),
                        Text(
                          strings.inProgress,
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: unlocked ? nodeColor : Colors.white12,
            ),
          ],
        ),
      ),
    );
  }
}
