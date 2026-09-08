import 'dart:convert';
import 'dart:io';

import 'package:blackjack_advantage_trainer/domain/blackjack_engine/blackjack_engine.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/game_rules.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/hand.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/strategy_engine.dart';
import 'package:blackjack_advantage_trainer/domain/learning/decision_lesson.dart';
import 'package:blackjack_advantage_trainer/domain/learning/pilot_lesson.dart';
import 'package:flutter_test/flutter_test.dart';

List<PilotLesson> lessons(String locale) =>
    (jsonDecode(
              File(
                'assets/content/$locale/strategy_lessons.json',
              ).readAsStringSync(),
            )
            as List)
        .take(3)
        .map((l) => PilotLesson.fromJson(l as Map<String, Object?>))
        .toList();

void main() {
  final reference =
      jsonDecode(
            File(
              'test/fixtures/standard_strategy_s17_das_ls.json',
            ).readAsStringSync(),
          )
          as Map;
  for (final locale in ['en', 'ru']) {
    test(
      '$locale: every new strategy task matches independent S17 table and legal actions',
      () {
        final course = lessons(locale);
        expect(course.map((l) => l.id), [
          'first-strategy',
          'dealer-upcard',
          'hard-doubles',
        ]);
        final allActions = <String>{};
        for (final lesson in course) {
          expect(lesson.scenarios, hasLength(12));
          for (final task in lesson.scenarios) {
            // These authored hands are hard, with no pair: numeric ranks and aces
            // counted as one, checked independently of HandEvaluator.
            final ranks = task.cards.map((c) => c.rank.label).toList();
            final total = ranks.fold<int>(
              0,
              (sum, r) => sum + (r == 'A' ? 1 : int.tryParse(r) ?? 10),
            );
            expect(ranks.contains('A') && total + 10 <= 21, isFalse);
            expect(ranks.length != 2 || ranks.first != ranks.last, isTrue);
            expect(task.evaluation.total, total);
            expect(task.evaluation.isSoft, isFalse);
            final dealerIndex = (reference['dealerOrder'] as List).indexOf(
              task.dealer!.rank.label,
            );
            final row =
                (reference['hard'] as Map)['${total.clamp(5, 17)}'] as String;
            var expected =
                (reference['codes'] as Map)[row[dealerIndex]] as String;
            if (expected == 'doubleDown' && task.cards.length > 2) {
              expected = 'hit';
            }
            expect(task.expected, expected, reason: task.id);
            allActions.add(expected);
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
            );
            final engine = BlackjackEngine()
              ..phase = RoundPhase.playerTurn
              ..activeSeatIndex = 0
              ..activeHandIndex = 0;
            engine.seats.first.hands.add(
              PlayerHandState(hand: BlackjackHand(task.cards)),
            );
            expect(task.availableActions, engine.availableActions);
          }
          String fingerprint(PilotScenario task) =>
              '${task.cards.map((c) => c.rank.label).join(',')}/${task.dealer!.rank.label}';
          final practice = lesson.scenarios.take(7).map(fingerprint).toSet();
          expect(
            lesson.scenarios.skip(7).map(fingerprint).any(practice.contains),
            isFalse,
          );
        }
        expect(allActions, {'hit', 'stand', 'doubleDown'});
        final doubles = course.last;
        expect(doubles.scenarios[1].expected, 'hit'); // 11 vs A in S17.
        expect(doubles.scenarios[2].expected, 'hit'); // 9 vs 2.
        expect(doubles.scenarios[3].expected, 'doubleDown'); // 9 vs 3.
        expect(doubles.scenarios[4].expected, 'doubleDown'); // 10 vs 9.
        expect(doubles.scenarios[5].expected, 'hit'); // 10 vs 10.
        expect(doubles.scenarios[6].availableActions, {
          PlayerAction.hit,
          PlayerAction.stand,
        });
        expect(doubles.scenarios[6].expected, 'hit'); // Multicard 11.
      },
    );

    test(
      '$locale: correction, unassisted scoring and cross-locale resume for all three',
      () {
        final course = lessons(locale);
        final translated = lessons(locale == 'en' ? 'ru' : 'en');
        for (var j = 0; j < course.length; j++) {
          final lesson = course[j];
          expect(lesson.resumeSignature, translated[j].resumeSignature);
          expect(lesson.theory, isNot(translated[j].theory));
          var session = DecisionLessonSession(lesson)..begin();
          for (var i = 0; i < 12; i++) {
            final task = session.current;
            if (i == 3) session.useHint();
            final wrong = task.availableActions
                .firstWhere((a) => a.name != task.expected)
                .name;
            session.answer(i == 2 ? wrong : task.expected);
            if (i == 2) {
              session = DecisionLessonSession.restore(
                translated[j],
                session.toJson(),
              );
              session.answer(task.expected);
              expect(session.firstAnswer, wrong);
            }
            session.next();
            session = DecisionLessonSession.restore(lesson, session.toJson());
          }
          expect(session.correctAnswers, 9);
          expect(session.unassistedAnswers, 8);
          expect(session.stars, 2);
          expect(session.adaptation, isNull);
        }
      },
    );
  }
}
