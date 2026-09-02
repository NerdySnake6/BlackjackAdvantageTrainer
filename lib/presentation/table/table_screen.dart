/// Landscape guided blackjack practice table.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../domain/blackjack_engine/game_rules.dart';
import '../../domain/learning/models.dart';
import '../../domain/learning/table_training.dart';
import '../../l10n/app_localizations.dart';
import '../../viewmodels/app_state.dart';
import '../../viewmodels/table_view_model.dart';
import 'seat_configuration_sheet.dart';
import 'table_action_tray.dart';
import 'table_top_view.dart';

class TableScreen extends StatefulWidget {
  const TableScreen({super.key});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final experienceLevel = appState.progress.experienceLevel;
    return ChangeNotifierProvider(
      create: (context) => TableViewModel(
        mode: experienceLevel == ExperienceLevel.experienced
            ? TableTrainingMode.practice
            : TableTrainingMode.guided,
        onEvent: (eventName, parameters) {
          unawaited(appState.trackTrainingEvent(eventName, parameters));
        },
      ),
      child: const _TableView(),
    );
  }
}

class _TableView extends StatelessWidget {
  const _TableView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TableViewModel>();
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          child: Column(
            children: [
              _TableHeader(viewModel: viewModel),
              const SizedBox(height: 8),
              Expanded(child: TableTopView(viewModel: viewModel)),
              const SizedBox(height: 8),
              TableActionTray(viewModel: viewModel),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.viewModel});

  final TableViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final engine = viewModel.engine;
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 1000;
    final isPortraitTransition = width < 480;
    return Row(
      children: [
        IconButton(
          onPressed: () => context.go('/learn'),
          tooltip: strings.backToPath,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PopupMenuButton<TableTrainingMode>(
                enabled: viewModel.canChangeMode,
                initialValue: viewModel.mode,
                onSelected: viewModel.setMode,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: TableTrainingMode.guided,
                    child: Text(strings.guidedModeName),
                  ),
                  PopupMenuItem(
                    value: TableTrainingMode.practice,
                    child: Text(strings.practiceModeName),
                  ),
                ],
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      viewModel.mode == TableTrainingMode.guided
                          ? strings.guidedMode
                          : strings.practiceMode,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.arrow_drop_down,
                      size: 16,
                      color: AppColors.gold,
                    ),
                  ],
                ),
              ),
              Text(
                engine.rules.id == GameRulesProfile.standard.id
                    ? strings.standardRulesName
                    : engine.rules.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ),
        if (!isPortraitTransition && viewModel.showsRunningCount) ...[
          _HeaderPill(
            icon: Icons.speed_rounded,
            label: strings.currentCount(engine.countingEngine.runningCount),
            color: AppColors.mint,
          ),
          const SizedBox(width: 6),
        ],
        if (!isCompact && !isPortraitTransition)
          _HeaderPill(
            icon: Icons.flag_outlined,
            label: strings.tableRoundProgress(
              viewModel.roundsCompleted,
              viewModel.roundsPerSession,
            ),
            color: AppColors.gold,
          ),
        if (!isCompact) ...[
          const SizedBox(width: 6),
          _HeaderPill(
            icon: Icons.layers_outlined,
            label: strings.shoeStatus(engine.dealtCards, engine.totalCards),
            color: Colors.white70,
          ),
        ],
        const SizedBox(width: 4),
        IconButton(
          onPressed: () => _showSeatConfiguration(context),
          tooltip: strings.configureSeats,
          icon: const Icon(Icons.tune_rounded),
        ),
      ],
    );
  }

  void _showSeatConfiguration(BuildContext context) {
    final viewModel = context.read<TableViewModel>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => ChangeNotifierProvider.value(
        value: viewModel,
        child: const SeatConfigurationSheet(),
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
