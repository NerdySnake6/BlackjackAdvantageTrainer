/// Bottom action tray managing player turns, feedback, count checks, and summaries.
library;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../domain/blackjack_engine/game_rules.dart';
import '../../domain/learning/table_training.dart';
import '../../l10n/app_localizations.dart';
import '../../viewmodels/table_view_model.dart';
import 'table_formatters.dart';

class TableActionTray extends StatelessWidget {
  const TableActionTray({super.key, required this.viewModel});

  final TableViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final engine = viewModel.engine;
    if (viewModel.sessionSummary case final summary?) {
      return SessionSummaryBar(viewModel: viewModel, summary: summary);
    }
    if (viewModel.decisionFeedback case final feedback?) {
      return DecisionFeedbackBar(viewModel: viewModel, feedback: feedback);
    }
    if (viewModel.awaitingCountCheck) {
      return CountCheckBar(viewModel: viewModel);
    }
    if (viewModel.isDealing) {
      return SizedBox(
        height: 48,
        child: Center(
          child: Text(
            strings.dealingCards,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ),
      );
    }
    if (engine.phase == RoundPhase.waiting) {
      return SizedBox(
        height: 48,
        child: FilledButton.icon(
          onPressed: viewModel.startRound,
          icon: const Icon(Icons.style_rounded),
          label: Text(strings.startFirstRound),
        ),
      );
    }
    if (engine.phase == RoundPhase.complete) {
      return SizedBox(
        height: 48,
        child: FilledButton.icon(
          onPressed: viewModel.startRound,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(strings.newRound),
        ),
      );
    }
    if (engine.phase == RoundPhase.dealerTurn) {
      return SizedBox(
        height: 48,
        child: Center(
          child: Text(
            strings.dealerTurn,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ),
      );
    }
    return SizedBox(height: 48, child: ActionBar(viewModel: viewModel));
  }
}

class ActionBar extends StatelessWidget {
  const ActionBar({super.key, required this.viewModel});

  final TableViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final available = viewModel.engine.availableActions;
    final actions = [
      (PlayerAction.hit, strings.hit),
      (PlayerAction.stand, strings.stand),
      (PlayerAction.doubleDown, strings.doubleAction),
      (PlayerAction.split, strings.split),
      (PlayerAction.surrender, strings.surrender),
    ];
    final isCompact = MediaQuery.sizeOf(context).width < 1000;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!isCompact) ...[
          Text(
            strings.turnPrompt,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
          const SizedBox(width: 10),
        ],
        for (final item in actions)
          if (available.contains(item.$1))
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: FilledButton.tonal(
                  onPressed: () => viewModel.applyAction(item.$1),
                  style: FilledButton.styleFrom(
                    minimumSize: Size(isCompact ? 0 : 78, 42),
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 6 : 10,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.$2,
                      textScaler: isCompact ? TextScaler.noScaling : null,
                      style: TextStyle(fontSize: isCompact ? 11 : null),
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

class DecisionFeedbackBar extends StatelessWidget {
  const DecisionFeedbackBar({
    super.key,
    required this.viewModel,
    required this.feedback,
  });

  final TableViewModel viewModel;
  final TableDecisionAttempt feedback;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF4B2529),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger),
      ),
      child: Row(
        children: [
          const Icon(Icons.school_outlined, color: AppColors.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.recommendedAction(
                    actionLabel(strings, feedback.recommendedAction),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  reasonLabel(strings, feedback.reason),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: viewModel.dismissDecisionFeedback,
            child: Text(strings.continueAction),
          ),
        ],
      ),
    );
  }
}

class CountCheckBar extends StatelessWidget {
  const CountCheckBar({super.key, required this.viewModel});

  final TableViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final answered = viewModel.countWasCorrect != null;
    return SizedBox(
      height: 58,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            answered
                ? viewModel.countWasCorrect!
                      ? strings.countCorrect
                      : strings.countIncorrect(viewModel.revealedCount!)
                : strings.tableCountPrompt,
            style: TextStyle(
              color: answered && !viewModel.countWasCorrect!
                  ? AppColors.danger
                  : Colors.white70,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 12),
          if (!answered) ...[
            IconButton.filledTonal(
              onPressed: () => viewModel.changeSubmittedCount(-1),
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 54,
              child: Text(
                '${viewModel.submittedCount >= 0 ? '+' : ''}${viewModel.submittedCount}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton.filledTonal(
              onPressed: () => viewModel.changeSubmittedCount(1),
              icon: const Icon(Icons.add),
            ),
          ],
          const SizedBox(width: 12),
          FilledButton(
            onPressed: answered
                ? viewModel.continueAfterCountCheck
                : viewModel.submitCount,
            child: Text(
              answered ? strings.continueAction : strings.submitCount,
            ),
          ),
        ],
      ),
    );
  }
}

class SessionSummaryBar extends StatelessWidget {
  const SessionSummaryBar({
    super.key,
    required this.viewModel,
    required this.summary,
  });

  final TableViewModel viewModel;
  final TableSessionSummary summary;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return SizedBox(
      height: 58,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_outlined, color: AppColors.mint),
            const SizedBox(width: 8),
            Text(
              strings.tableSessionComplete,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 16),
            Text(
              strings.strategyAccuracy(
                (summary.strategyAccuracy * 100).round(),
              ),
            ),
            if (summary.countAccuracy case final accuracy?) ...[
              const SizedBox(width: 12),
              Text(strings.countAccuracy((accuracy * 100).round())),
            ],
            const SizedBox(width: 16),
            FilledButton(
              onPressed: viewModel.startNewSession,
              child: Text(strings.startAnotherSession),
            ),
          ],
        ),
      ),
    );
  }
}
