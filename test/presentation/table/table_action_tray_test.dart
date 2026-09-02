import 'dart:math';

import 'package:blackjack_advantage_trainer/app/theme.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/blackjack_engine.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/card.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/game_rules.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/shoe.dart';
import 'package:blackjack_advantage_trainer/domain/learning/table_training.dart';
import 'package:blackjack_advantage_trainer/l10n/app_localizations.dart';
import 'package:blackjack_advantage_trainer/presentation/table/table_action_tray.dart';
import 'package:blackjack_advantage_trainer/viewmodels/table_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TableActionTray shows start button in waiting phase', (
    tester,
  ) async {
    _setupLandscape(tester);
    final viewModel = TableViewModel(
      engine: BlackjackEngine(random: Random(42)),
    );
    addTearDown(viewModel.dispose);

    await _pumpTray(tester, viewModel);

    expect(find.text('Deal the first round'), findsOneWidget);
    await tester.tap(find.text('Deal the first round'));
    await tester.pump();
    expect(viewModel.isDealing, isTrue);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('TableActionTray shows dealing state', (tester) async {
    _setupLandscape(tester);
    final viewModel = TableViewModel(
      engine: BlackjackEngine(random: Random(42)),
    );
    addTearDown(viewModel.dispose);

    await _pumpTray(tester, viewModel);
    viewModel.startRound();
    await tester.pump();

    expect(find.text('Dealing cards...'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets(
    'TableActionTray shows action bar and handles actions during player turn',
    (tester) async {
      _setupLandscape(tester);
      final viewModel = TableViewModel(
        engine: _scriptedEngine([
          CardRank.ten, // player
          CardRank.six, // dealer
          CardRank.two, // player
          CardRank.ten, // dealer hole
        ]),
      );
      addTearDown(viewModel.dispose);

      await _pumpTray(tester, viewModel);
      viewModel.startRound();
      await tester.pump(const Duration(seconds: 3));

      expect(viewModel.engine.phase, RoundPhase.playerTurn);
      expect(find.text('Hit'), findsOneWidget);
      expect(find.text('Stand'), findsOneWidget);

      await tester.tap(find.text('Stand'));
      await tester.pump(const Duration(seconds: 2));

      expect(viewModel.engine.phase, RoundPhase.complete);
    },
  );

  testWidgets('TableActionTray displays decision feedback and dismisses it', (
    tester,
  ) async {
    _setupLandscape(tester);
    final viewModel = TableViewModel(
      engine: _scriptedEngine([
        CardRank.ten, // player
        CardRank.six, // dealer
        CardRank.two, // player -> total 12 vs 6
        CardRank.ten, // dealer hole -> dealer has 16
        CardRank.ten, // player hit card -> 22 bust
      ]),
    );
    addTearDown(viewModel.dispose);

    await _pumpTray(tester, viewModel);
    viewModel.startRound();
    await tester.pump(const Duration(seconds: 3));

    // Basic strategy says stand on 12 vs 6. Hitting triggers feedback in guided mode.
    viewModel.applyAction(PlayerAction.hit);
    await tester.pump();

    expect(viewModel.decisionFeedback, isNotNull);
    expect(find.byType(DecisionFeedbackBar), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(viewModel.decisionFeedback, isNull);
  });

  testWidgets(
    'CountCheckBar appears in practice mode, adjusts count, and submits',
    (tester) async {
      _setupLandscape(tester);
      final viewModel = TableViewModel(
        engine: _scriptedEngine([
          CardRank.ten,
          CardRank.ten,
          CardRank.seven,
          CardRank.seven,
        ]),
        mode: TableTrainingMode.practice,
      );
      addTearDown(viewModel.dispose);

      await _pumpTray(tester, viewModel);
      viewModel.startRound();
      await tester.pump(const Duration(seconds: 3));
      viewModel.applyAction(PlayerAction.stand);
      await tester.pump(const Duration(seconds: 2));

      expect(viewModel.awaitingCountCheck, isTrue);
      expect(find.byType(CountCheckBar), findsOneWidget);
      expect(find.text('What is the running count?'), findsOneWidget);

      // Adjust count
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(viewModel.submittedCount, 1);

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();
      expect(viewModel.submittedCount, 0);

      // Submit count
      expect(find.text('Check count'), findsOneWidget);
      await tester.tap(find.text('Check count'));
      await tester.pump();

      expect(viewModel.countWasCorrect, isNotNull);
      expect(find.text('Continue'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(viewModel.awaitingCountCheck, isFalse);
    },
  );

  testWidgets(
    'SessionSummaryBar displays after 5 rounds and can reset session',
    (tester) async {
      _setupLandscape(tester);
      final viewModel = TableViewModel(
        engine: _scriptedEngine([
          CardRank.ten,
          CardRank.ten,
          CardRank.seven,
          CardRank.seven,
        ]),
      );
      addTearDown(viewModel.dispose);

      await _pumpTray(tester, viewModel);

      for (var round = 0; round < 5; round++) {
        viewModel.startRound();
        await tester.pump(const Duration(seconds: 3));
        viewModel.applyAction(PlayerAction.stand);
        await tester.pump(const Duration(seconds: 2));
      }

      expect(viewModel.sessionSummary, isNotNull);
      expect(find.byType(SessionSummaryBar), findsOneWidget);
      expect(find.text('Five-round session complete'), findsOneWidget);
      expect(find.text('Another session'), findsOneWidget);

      await tester.tap(find.text('Another session'));
      await tester.pump();

      expect(viewModel.sessionSummary, isNull);
      expect(viewModel.roundsCompleted, 0);
    },
  );
}

void _setupLandscape(WidgetTester tester) {
  tester.view.physicalSize = const Size(1024, 768);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _pumpTray(WidgetTester tester, TableViewModel viewModel) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) =>
              Center(child: TableActionTray(viewModel: viewModel)),
        ),
      ),
    ),
  );
  await tester.pump();
}

BlackjackEngine _scriptedEngine(List<CardRank> ranks) {
  final repeatedRanks = [
    for (var i = 0; i < 15; i++) ...ranks,
    for (var i = 0; i < 30; i++) CardRank.ten,
  ];
  return BlackjackEngine(
    rules: GameRulesProfile.standard,
    shoe: Shoe.scripted(
      rules: GameRulesProfile.standard,
      cards: [
        for (var index = 0; index < repeatedRanks.length; index++)
          PlayingCard(
            deckIndex: 0,
            suit: CardSuit.values[index % CardSuit.values.length],
            rank: repeatedRanks[index],
          ),
      ],
    ),
    seatConfiguration: SeatConfiguration([
      SeatRole.human,
      SeatRole.empty,
      SeatRole.empty,
      SeatRole.empty,
      SeatRole.empty,
    ]),
  );
}
