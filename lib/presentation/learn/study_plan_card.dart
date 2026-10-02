/// Three optional suggestions; the complete course remains directly accessible.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../viewmodels/app_state.dart';

class StudyPlanCard extends StatelessWidget {
  const StudyPlanCard({super.key});
  @override
  Widget build(BuildContext context) {
    final plan = context.watch<AppState>().studyPlan;
    final strings = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.studyPlanTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (plan.reviewLesson == null)
              Text(strings.studyNoReview)
            else
              FilledButton.tonal(
                key: const ValueKey('study-review'),
                onPressed: () =>
                    context.push('/learn-review/${plan.reviewLesson!.id}'),
                child: Text(strings.studyDueReview(plan.reviewLesson!.title)),
              ),
            if (plan.nextLesson == null)
              Text(strings.studyCoursePractised)
            else
              FilledButton(
                key: const ValueKey('study-next'),
                onPressed: () => context.push('/lesson/${plan.nextLesson!.id}'),
                child: Text(strings.studyNextLesson(plan.nextLesson!.title)),
              ),
            OutlinedButton(
              key: const ValueKey('study-combined'),
              onPressed: () => context.push('/combined-practice'),
              child: Text(strings.combinedTitle),
            ),
            if (plan.challengeLesson != null)
              OutlinedButton(
                key: const ValueKey('study-challenge'),
                onPressed: () =>
                    context.push('/learn-review/${plan.challengeLesson!.id}'),
                child: Text(
                  strings.studyOptionalChallenge(plan.challengeLesson!.title),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
