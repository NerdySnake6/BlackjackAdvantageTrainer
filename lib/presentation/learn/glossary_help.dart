/// Explicit term links, separate from answer and gameplay controls.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/blackjack_engine/game_rules.dart';
import '../../l10n/app_localizations.dart';
import '../../viewmodels/app_state.dart';
import '../table/table_formatters.dart';

class GlossaryHelp extends StatelessWidget {
  const GlossaryHelp({super.key, this.beforeOpen});
  final Future<bool> Function()? beforeOpen;
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final glossary = context.watch<AppState>().catalog.glossary;
    final labels = {
      'hit': actionLabel(strings, PlayerAction.hit),
      'stand': actionLabel(strings, PlayerAction.stand),
      'double': actionLabel(strings, PlayerAction.doubleDown),
      'split': actionLabel(strings, PlayerAction.split),
      'surrender': actionLabel(strings, PlayerAction.surrender),
      'hardHand': strings.foundationHard,
      'softHand': strings.foundationSoft,
      'runningCount': strings.glossaryRunningCount,
    };
    return ExpansionTile(
      title: Text(strings.glossaryTitle),
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final entry in labels.entries)
              if (glossary.containsKey(entry.key))
                TextButton.icon(
                  key: ValueKey('term-${entry.key}'),
                  icon: const Icon(Icons.info_outline),
                  label: Text(entry.value),
                  onPressed: () async {
                    if (beforeOpen != null && !await beforeOpen!()) return;
                    if (!context.mounted) return;
                    await showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        scrollable: true,
                        title: Text(entry.value),
                        content: Text(glossary[entry.key]!),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(strings.done),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ],
        ),
      ],
    );
  }
}
