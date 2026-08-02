import 'dart:math';

import 'package:blackjack_advantage_trainer/domain/blackjack_engine/blackjack_engine.dart';
import 'package:blackjack_advantage_trainer/viewmodels/table_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('table reveals cards in casino dealing order', (tester) async {
    final viewModel = TableViewModel(
      engine: BlackjackEngine(random: Random(14)),
    );
    addTearDown(viewModel.dispose);

    viewModel.startRound();

    expect(viewModel.isDealing, isTrue);
    expect(viewModel.dealProgress, 0);
    expect(viewModel.visibleCardsForSeat(0), 0);
    expect(viewModel.visibleDealerCards, 0);

    await tester.pump(const Duration(milliseconds: 350));
    expect(viewModel.visibleCardsForSeat(0), 1);
    expect(viewModel.visibleCardsForSeat(1), 0);

    await tester.pump(const Duration(milliseconds: 1_700));
    expect(viewModel.visibleDealerCards, 1);

    await tester.pump(const Duration(milliseconds: 2_040));
    expect(viewModel.isDealing, isFalse);
    expect(viewModel.visibleCardsForSeat(0), 2);
    expect(viewModel.visibleDealerCards, 2);
  });
}
