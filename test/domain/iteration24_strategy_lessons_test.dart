import 'dart:convert';
import 'dart:io';

import 'package:blackjack_advantage_trainer/domain/blackjack_engine/blackjack_engine.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/game_rules.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/hand.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/strategy_engine.dart';
import 'package:blackjack_advantage_trainer/domain/learning/mastery_check.dart';
import 'package:blackjack_advantage_trainer/domain/learning/pilot_lesson.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/strategy_reference.dart';

List<PilotLesson> loadLessons(String locale, String file) =>
    (jsonDecode(File('assets/content/$locale/$file.json').readAsStringSync())
            as List)
        .map((l) => PilotLesson.fromJson(l as Map<String, Object?>))
        .toList();

void main() {
  for (final locale in ['en', 'ru']) {
    test(
      '$locale iteration 24 decisions match independent table and restrictions',
      () {
        final lessons = loadLessons(
          locale,
          'strategy_lessons',
        ).skip(6).toList();
        expect(lessons.map((l) => l.id), [
          'pairs-das',
          'unavailable-actions-surrender',
          'mixed-basic-strategy',
        ]);
        for (final lesson in lessons) {
          expect(lesson.scenarios, hasLength(12));
          for (final task in lesson.scenarios) {
            final expected = referenceStrategy(
              task.cards.map((c) => c.rank.label).toList(),
              task.dealer!.rank.label,
              task.availableActions,
            );
            expect(task.expected, expected, reason: task.id);
            expect(
              const StrategyEngine()
                  .recommend(
                    hand: BlackjackHand(task.cards),
                    dealerUpCard: task.dealer!,
                    rules: GameRulesProfile.standard,
                    availableActions: task.availableActions,
                  )
                  .name,
              expected,
              reason: task.id,
            );
            final engine = BlackjackEngine()
              ..phase = RoundPhase.playerTurn
              ..activeSeatIndex = 0
              ..activeHandIndex = 0;
            engine.seats.first.hands.add(
              PlayerHandState(
                hand: BlackjackHand(task.cards),
                fromSplit: task.afterSplit,
              ),
            );
            if (task.afterSplit &&
                !task.availableActions.contains(PlayerAction.split)) {
              for (var i = 0; i < 3; i++) {
                engine.seats.first.hands.add(
                  PlayerHandState(
                    hand: BlackjackHand(task.cards),
                    fromSplit: true,
                  ),
                );
              }
            }
            if (task.prompt.isEmpty || task.afterSplit) {
              expect(
                task.availableActions,
                engine.availableActions,
                reason: task.id,
              );
            } else {
              expect(
                task.availableActions.every(engine.availableActions.contains),
                isTrue,
              );
            }
          }
        }
      },
    );
  }

  test(
    'each standard strategy row is covered by lessons or held-out checks',
    () {
      final rows = <String>{};
      void record(List<String> ranks, Set<PlayerAction> actions) {
        final family = strategyFamily(ranks, actions);
        rows.add('$family/${strategyRow(ranks, family)}');
      }

      for (final file in ['strategy_lessons', 'pilot_lessons']) {
        for (final lesson in loadLessons('en', file)) {
          for (final task in lesson.scenarios.where((t) => t.usesActions)) {
            record(
              task.cards.map((c) => c.rank.label).toList(),
              task.availableActions,
            );
          }
        }
      }
      for (final task in MasteryCheckBank.tasks('mixed-basic-strategy', 0)) {
        record(task.cards.map((c) => c.rank.label).toList(), task.actions);
      }
      for (final family in ['hard', 'soft', 'pairs']) {
        for (final key in (strategyReference[family] as Map).keys) {
          expect(rows, contains('$family/$key'));
        }
      }
    },
  );

  test(
    'two 100-decision forms are disjoint from all practice and each other',
    () {
      final seen = <String>{};
      for (final file in [
        'foundation_lessons',
        'strategy_lessons',
        'pilot_lessons',
      ]) {
        for (final lesson in loadLessons('en', file)) {
          for (final task in lesson.scenarios) {
            seen.add(
              strategyFingerprint(
                task.cards.map((c) => c.rank.label).toList(),
                task.dealer?.rank.label,
              ),
            );
          }
        }
      }
      for (final id in ['hard-12', 'soft-18']) {
        for (var form = 0; form < 2; form++) {
          for (final task in MasteryCheckBank.tasks(id, form)) {
            seen.add(
              strategyFingerprint(
                task.cards.map((c) => c.rank.label).toList(),
                task.dealer?.rank.label,
              ),
            );
          }
        }
      }
      for (var form = 0; form < 2; form++) {
        final tasks = MasteryCheckBank.tasks('mixed-basic-strategy', form);
        expect(tasks, hasLength(100));
        final families = <String>{};
        final answers = <String>{};
        for (final task in tasks) {
          final ranks = task.cards.map((c) => c.rank.label).toList();
          expect(
            seen.add(strategyFingerprint(ranks, task.dealer!.rank.label)),
            isTrue,
          );
          expect(
            task.expected,
            referenceStrategy(ranks, task.dealer!.rank.label, task.actions),
          );
          expect(task.accepts(task.expected), isTrue);
          families.add(strategyFamily(ranks, task.actions));
          answers.add(task.expected);
        }
        expect(families, {'hard', 'soft', 'pairs'});
        expect(answers, PlayerAction.values.map((a) => a.name).toSet());
      }
    },
  );

  for (final errors in [0, 1]) {
    test(
      '100 consecutive first answers required, $errors errors, resume every step',
      () {
        var session = MasteryCheckSession('mixed-basic-strategy');
        for (var i = 0; i < 100; i++) {
          final task = session.current;
          session.answer(
            i < errors
                ? task.actions.firstWhere((a) => a.name != task.expected).name
                : task.expected,
          );
          session = MasteryCheckSession.restore(
            session.lessonId,
            session.toJson(),
          );
          expect(session.passed, i == 99 && errors == 0);
        }
        expect(session.correct, 100 - errors);
      },
    );
  }
}
