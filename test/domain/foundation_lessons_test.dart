import 'dart:convert';
import 'dart:io';

import 'package:blackjack_advantage_trainer/domain/blackjack_engine/blackjack_engine.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/game_rules.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/hand.dart';
import 'package:blackjack_advantage_trainer/domain/blackjack_engine/shoe.dart';
import 'package:blackjack_advantage_trainer/domain/learning/content_validator.dart';
import 'package:blackjack_advantage_trainer/domain/learning/decision_lesson.dart';
import 'package:blackjack_advantage_trainer/domain/learning/lesson_format.dart';
import 'package:blackjack_advantage_trainer/domain/learning/pilot_lesson.dart';
import 'package:flutter_test/flutter_test.dart';

List<dynamic> rawLessons(String locale) =>
    jsonDecode(
          File(
            'assets/content/$locale/foundation_lessons.json',
          ).readAsStringSync(),
        )
        as List;

List<PilotLesson> lessons(String locale) => rawLessons(locale)
    .map((raw) => PilotLesson.fromJson(Map<String, Object?>.from(raw as Map)))
    .toList();

// Independent reference: enumerate all ace assignments instead of using the
// production evaluator's running-sum algorithm. Rules reviewed 2026-09-08:
// https://wizardofodds.com/games/blackjack/basics/ (Rules 2, 3, 8).
(int, bool) referenceHand(List<String> ranks) {
  var choices = <(int, bool)>[(0, false)];
  for (final rank in ranks) {
    final values = rank == 'A' ? [1, 11] : [int.tryParse(rank) ?? 10];
    choices = [
      for (final previous in choices)
        for (final value in values)
          (previous.$1 + value, previous.$2 || value == 11),
    ];
  }
  final live = choices.where((entry) => entry.$1 <= 21).toList()
    ..sort((a, b) => b.$1.compareTo(a.$1));
  choices.sort((a, b) => a.$1.compareTo(b.$1));
  return live.isEmpty ? choices.first : live.first;
}

void main() {
  for (final locale in ['en', 'ru']) {
    test('$locale: 48 authored tasks agree with independent rules', () {
      final course = lessons(locale);
      expect(course.map((l) => l.id), [
        'quick-start',
        'card-values',
        'hard-and-soft',
        'player-actions',
      ]);
      for (final lesson in course) {
        expect(lesson.scenarios, hasLength(12));
        for (final task in lesson.scenarios) {
          final ranks = task.cards.map((c) => c.rank.label).toList();
          final (total, soft) = referenceHand(ranks);
          expect(task.evaluation.total, total, reason: task.id);
          expect(task.evaluation.isSoft, soft, reason: task.id);
          final natural =
              ranks.length == 2 &&
              ranks.contains('A') &&
              ranks.any((r) => ['10', 'J', 'Q', 'K'].contains(r)) &&
              !task.afterSplit;
          final expected = switch (task.kind) {
            LessonMissionKind.handTotal => '$total',
            LessonMissionKind.handType => soft ? 'soft' : 'hard',
            LessonMissionKind.handOutcome =>
              total > 21
                  ? 'bust'
                  : natural
                  ? 'natural'
                  : total == 21
                  ? 'twentyOne'
                  : 'inPlay',
            _ => task.expected,
          };
          expect(task.expected, expected, reason: task.id);
          if (task.usesActions) {
            // Fixed authored reference, not a strategy recommendation.
            const actions = [
              'hit',
              'stand',
              'doubleDown',
              'split',
              'surrender',
              'hit',
              'stand',
              'split',
              'doubleDown',
              'hit',
              'stand',
              'surrender',
            ];
            expect(task.expected, actions[lesson.scenarios.indexOf(task)]);
            final engine =
                BlackjackEngine(
                    shoe: Shoe.scripted(
                      rules: GameRulesProfile.standard,
                      cards: [
                        ...task.drawCards,
                        PilotScenario.cardFromLabel('2', 20),
                      ],
                    ),
                  )
                  ..phase = RoundPhase.playerTurn
                  ..activeSeatIndex = 0
                  ..activeHandIndex = 0
                  ..dealerHand = BlackjackHand([
                    PilotScenario.cardFromLabel('10', 21),
                    PilotScenario.cardFromLabel('8', 22),
                  ]);
            engine.seats[0].hands.add(
              PlayerHandState(
                hand: BlackjackHand(task.cards),
                fromSplit: task.afterSplit,
              ),
            );
            expect(task.availableActions, engine.availableActions);
            engine.applyAction(PlayerAction.values.byName(task.expected));
            expect(
              engine.seats[0].hands
                  .map((h) => h.hand.cards.map((c) => c.rank.label).toList())
                  .toList(),
              task.demonstrationHands
                  .map((h) => h.map((c) => c.rank.label).toList())
                  .toList(),
            );
            expect(
              task.demonstrationHands.expand((h) => h).length,
              task.cards.length + task.drawCards.length,
            );
            expect(
              task.demonstrationHands.length,
              task.expected == 'split' ? 2 : 1,
            );
          }
        }
      }
      expect(course[3].scenarios[5].availableActions, {
        PlayerAction.hit,
        PlayerAction.stand,
      });
      expect(course[3].scenarios[8].availableActions, {
        PlayerAction.hit,
        PlayerAction.stand,
        PlayerAction.doubleDown,
      });
    });

    for (var lessonIndex = 0; lessonIndex < 4; lessonIndex++) {
      test(
        '$locale lesson $lessonIndex: every interaction resumes, first answer stays',
        () {
          final lesson = lessons(locale)[lessonIndex];
          var session = DecisionLessonSession(lesson)..begin();
          void reload() =>
              session = DecisionLessonSession.restore(lesson, session.toJson());
          for (final task in lesson.scenarios) {
            if (task.requiresReveal) {
              expect(() => session.answer(task.expected), throwsStateError);
              for (var i = 0; i < task.cards.length; i++) {
                session.reveal();
                reload();
                expect(session.revealed, i + 1);
              }
            }
            if (task.usesNumber) {
              session.adjustCount(1);
              reload();
              expect(session.countInput, 1);
            }
            if (session.index == 2) {
              final wrong = task.usesNumber
                  ? '0'
                  : task.answerKeys.firstWhere((k) => k != task.expected);
              session.useHint();
              session.answer(wrong);
              reload();
              expect(session.corrected, isFalse);
              expect(() => session.next(), throwsStateError);
              session.answer(task.expected);
              reload();
              expect(session.firstAnswer, wrong);
            } else {
              session.answer(task.expected);
            }
            if (session.isIndependent) {
              expect(() => session.useHint(), throwsStateError);
            }
            session.next();
            reload();
          }
          expect(session.phase, DecisionLessonPhase.result);
          expect(session.correctAnswers, 9);
          expect(session.unassistedAnswers, 9);
          expect(session.stars, 2);
          expect(session.adaptation, isNull);
        },
      );
    }
  }

  test(
    'translation preserves every signature; old pilot signatures unchanged by fields',
    () {
      final en = lessons('en');
      final ru = lessons('ru');
      for (var i = 0; i < en.length; i++) {
        expect(en[i].resumeSignature, ru[i].resumeSignature);
        expect(en[i].theory, isNot(ru[i].theory));
      }
      final raw = rawLessons('en')[0] as Map<String, dynamic>;
      final session = DecisionLessonSession(en.first).toJson();
      ((raw['scenarios'] as List).first as Map)['afterSplit'] = true;
      final changed = PilotLesson.fromJson(raw);
      expect(
        () => DecisionLessonSession.restore(changed, session),
        throwsFormatException,
      );
    },
  );

  test('hand input and reveal ranges fail closed on corrupt saves', () {
    final lesson = lessons('en')[1];
    final session = DecisionLessonSession(lesson)..begin();
    for (final _ in session.current.cards) {
      session.reveal();
    }
    for (var i = 0; i < 30; i++) {
      session.adjustCount(1);
    }
    expect(session.countInput, session.current.maximumInput);
    expect(session.current.accepts('018'), isFalse);
    expect(session.current.accepts('-1'), isFalse);
    for (final (key, value) in [
      ('revealed', 99),
      ('countInput', -1),
      ('countInput', 999),
    ]) {
      expect(
        () => DecisionLessonSession.restore(lesson, {
          ...session.toJson(),
          key: value,
        }),
        throwsFormatException,
      );
    }
  });

  for (final mutation in [
    'answer',
    'prompt',
    'actions',
    'draw',
    'duplicate',
    'skill',
    'kind',
  ]) {
    test('validator rejects foundation $mutation corruption', () {
      final raw = rawLessons('en');
      final hand = raw[0]['scenarios'][0] as Map;
      final action = raw[3]['scenarios'][0] as Map;
      switch (mutation) {
        case 'answer':
          hand['expected'] = 'bust';
        case 'prompt':
          hand['prompt'] = '';
        case 'actions':
          action['actions'] = ['hit'];
        case 'draw':
          action['drawCards'] = [];
        case 'duplicate':
          raw[1]['id'] = 'quick-start';
        case 'skill':
          raw[0]['skillId'] = 'other';
        case 'kind':
          hand['kind'] = 'unverified';
      }
      Map<String, Object?> read(String file) =>
          jsonDecode(File('assets/content/en/$file.json').readAsStringSync())
              as Map<String, Object?>;
      expect(
        () => const ContentValidator().parse(
          catalog: read('lessons'),
          pilotLessons: jsonDecode(
            File('assets/content/en/pilot_lessons.json').readAsStringSync(),
          ),
          foundationLessons: raw,
          manifest: read('manifest'),
          glossary: read('glossary'),
        ),
        throwsFormatException,
      );
    });
  }
}
