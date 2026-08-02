import 'package:blackjack_advantage_trainer/app/app.dart';
import 'package:blackjack_advantage_trainer/core/persistence/progress_repository.dart';
import 'package:blackjack_advantage_trainer/data/content_repository.dart';
import 'package:blackjack_advantage_trainer/domain/learning/models.dart';
import 'package:blackjack_advantage_trainer/viewmodels/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('learning path opens the first interactive lesson', (
    tester,
  ) async {
    final catalog = await ContentRepository().loadEnglishCatalog();
    final repository = _MemoryProgressRepository();
    final appState = AppState(
      catalog: catalog,
      progress: const ProgressSnapshot(),
      progressRepository: repository,
    );

    await tester.pumpWidget(BlackjackTrainerApp(appState: appState));
    await tester.pumpAndSettle();

    expect(find.text('Learning path'), findsOneWidget);
    expect(find.text('Your first hand'), findsOneWidget);

    await tester.tap(find.text('Your first hand'));
    await tester.pumpAndSettle();

    expect(
      find.text('What is the main goal of a blackjack hand?'),
      findsOneWidget,
    );
  });
}

class _MemoryProgressRepository implements ProgressRepository {
  ProgressSnapshot snapshot = const ProgressSnapshot();

  @override
  Future<void> clear() async {
    snapshot = const ProgressSnapshot();
  }

  @override
  Future<ProgressSnapshot> load() async => snapshot;

  @override
  Future<void> save(ProgressSnapshot snapshot) async {
    this.snapshot = snapshot;
  }
}
