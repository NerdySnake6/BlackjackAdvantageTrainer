/// Modal sheet for configuring roles of the five table seats.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../domain/blackjack_engine/game_rules.dart';
import '../../l10n/app_localizations.dart';
import '../../viewmodels/table_view_model.dart';
import 'table_formatters.dart';

class SeatConfigurationSheet extends StatelessWidget {
  const SeatConfigurationSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final viewModel = context.watch<TableViewModel>();
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.configureSeats,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              strings.configureSeatsHint,
              style: const TextStyle(color: Colors.white60),
            ),
            if (viewModel.hasPendingSeatConfiguration) ...[
              const SizedBox(height: 4),
              Text(
                strings.seatChangesPending,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                for (final (seatIndex, role)
                    in viewModel.configuredSeatRoles.indexed)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: PopupMenuButton<SeatRole>(
                        initialValue: role,
                        onSelected: (role) =>
                            viewModel.setSeatRole(seatIndex, role),
                        itemBuilder: (context) => [
                          for (final role in SeatRole.values)
                            PopupMenuItem(
                              value: role,
                              enabled: viewModel.canSetSeatRole(
                                seatIndex,
                                role,
                              ),
                              child: Row(
                                children: [
                                  Icon(roleIcon(role), size: 20),
                                  const SizedBox(width: 10),
                                  Text(roleLabel(strings, role)),
                                ],
                              ),
                            ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Icon(roleIcon(role)),
                              const SizedBox(height: 5),
                              Text(
                                strings.seat(seatIndex + 1),
                                style: const TextStyle(fontSize: 11),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      roleLabel(strings, role),
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down, size: 16),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.done),
            ),
          ],
        ),
      ),
    );
  }
}
