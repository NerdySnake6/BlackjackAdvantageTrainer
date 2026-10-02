/// Optional unscored examples before the first beginner lesson.
library;

import 'package:flutter/material.dart';

import '../../domain/blackjack_engine/hand.dart';
import '../../domain/learning/pilot_lesson.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/learn_card_view.dart';

class BeginnerPrimer extends StatefulWidget {
  const BeginnerPrimer({super.key});
  @override
  State<BeginnerPrimer> createState() => _BeginnerPrimerState();
}

class _BeginnerPrimerState extends State<BeginnerPrimer> {
  int _example = 0;
  int _revealed = 0;
  static const _hands = [
    ['10', '7'],
    ['10', '6', '8'],
    ['A', 'K'],
  ];
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final cards = _hands[_example].indexed
        .map((e) => PilotScenario.cardFromLabel(e.$2, e.$1))
        .toList();
    final explanation = [
      strings.primerCompare,
      strings.primerBust,
      strings.primerBlackjack,
    ][_example];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.primerTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(strings.primerGoal),
            Text(strings.primerValues),
            Text(strings.primerExample(_example + 1)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final card in cards.take(_revealed))
                  LearnCardView(card: card, width: 64),
              ],
            ),
            if (_revealed < cards.length)
              FilledButton.tonal(
                key: const ValueKey('primer-reveal'),
                onPressed: () => setState(() => _revealed++),
                child: Text(strings.foundationDeal),
              )
            else ...[
              Text(
                strings.handTotal(const HandEvaluator().evaluate(cards).total),
              ),
              if (_example == 0) ...[
                Text(strings.dealer),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final rank in ['10', '6'])
                      LearnCardView(
                        card: PilotScenario.cardFromLabel(rank, 0),
                        width: 64,
                      ),
                  ],
                ),
              ],
              Text(explanation),
              if (_example < 2)
                TextButton(
                  key: const ValueKey('primer-next'),
                  onPressed: () => setState(() {
                    _example++;
                    _revealed = 0;
                  }),
                  child: Text(strings.next),
                ),
            ],
            Text(strings.primerUnscored),
          ],
        ),
      ),
    );
  }
}
