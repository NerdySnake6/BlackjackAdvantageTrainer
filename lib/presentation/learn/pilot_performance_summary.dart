/// Honest comparison of completed practice, separate from new-task checks.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../viewmodels/app_state.dart';

class PilotPerformanceSummary extends StatelessWidget {
  const PilotPerformanceSummary({super.key, required this.lessonId});
  final String lessonId;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final current = app.latestPilotPerformance(lessonId);
    if (current == null) return const SizedBox.shrink();
    final previous = app.previousPilotPerformance(lessonId);
    final comparable = previous != null && current.comparableTo(previous);
    final strings = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          comparable
              ? strings.pilotPracticeComparison(
                  previous.correct,
                  current.correct,
                  previous.unassisted,
                  current.unassisted,
                )
              : strings.pilotPracticeBaseline(
                  current.correct,
                  current.unassisted,
                ),
          key: ValueKey('practice-performance-$lessonId'),
        ),
        Text(strings.pilotPracticeComparisonNote),
      ],
    );
  }
}
