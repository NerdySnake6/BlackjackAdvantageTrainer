/// State for a one-deck Hi-Lo running-count drill.
library;

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../domain/blackjack_engine/card.dart';
import '../domain/blackjack_engine/counting_engine.dart';
import '../domain/blackjack_engine/game_rules.dart';
import '../domain/blackjack_engine/shoe.dart';

enum CountDrillPhase { idle, running, checkpoint, complete }

class CountDrillViewModel extends ChangeNotifier {
  CountDrillViewModel({Random? random, this.onEvent})
    : _shoe = Shoe(
        rules: const GameRulesProfile(
          id: 'countdown_single_deck',
          name: 'Single-deck countdown',
          deckCount: 1,
          blackjackPayout: BlackjackPayout.threeToTwo,
          dealerHitsSoft17: false,
          doubleAfterSplit: true,
          lateSurrender: true,
          dealerPeek: true,
          penetration: 1,
        ),
        random: random,
      );

  final Shoe _shoe;
  final CountingEngine _countingEngine = CountingEngine();
  final void Function(String, Map<String, Object?>)? onEvent;
  CountDrillPhase _phase = CountDrillPhase.idle;
  PlayingCard? _currentCard;
  var _submittedCount = 0;
  bool? _lastAnswerCorrect;
  int? _revealedCorrectCount;
  var _checkpointNumber = 0;

  CountDrillPhase get phase => _phase;
  PlayingCard? get currentCard => _currentCard;
  int get cardsSeen => _countingEngine.cardsSeen;
  int get submittedCount => _submittedCount;
  bool? get lastAnswerCorrect => _lastAnswerCorrect;
  int? get revealedCorrectCount => _revealedCorrectCount;
  int get checkpointNumber => _checkpointNumber;
  double get progress => cardsSeen / 52;

  void start() {
    _shoe.reset();
    _countingEngine.reset();
    _phase = CountDrillPhase.running;
    _currentCard = null;
    _submittedCount = 0;
    _lastAnswerCorrect = null;
    _revealedCorrectCount = null;
    _checkpointNumber = 0;
    revealNext();
    onEvent?.call('drill_started', {'session_type': 'one_deck'});
  }

  void revealNext() {
    if (_phase != CountDrillPhase.running || _shoe.remainingCount == 0) {
      return;
    }
    _currentCard = _shoe.draw();
    _countingEngine.reveal(_currentCard!);
    _lastAnswerCorrect = null;
    _revealedCorrectCount = null;

    if (_countingEngine.cardsSeen % 8 == 0 || _shoe.remainingCount == 0) {
      _phase = CountDrillPhase.checkpoint;
      _checkpointNumber++;
      _submittedCount = 0;
    }
    notifyListeners();
  }

  void changeSubmittedCount(int delta) {
    if (_phase != CountDrillPhase.checkpoint || _lastAnswerCorrect != null) {
      return;
    }
    _submittedCount += delta;
    notifyListeners();
  }

  void submitCount() {
    if (_phase != CountDrillPhase.checkpoint || _lastAnswerCorrect != null) {
      return;
    }
    _revealedCorrectCount = _countingEngine.runningCount;
    _lastAnswerCorrect = _submittedCount == _countingEngine.runningCount;
    onEvent?.call('count_check', {
      'session_type': 'drill',
      'is_correct': _lastAnswerCorrect!,
      'cards_seen': cardsSeen,
    });
    notifyListeners();
  }

  void continueAfterCheckpoint() {
    if (_phase != CountDrillPhase.checkpoint || _lastAnswerCorrect == null) {
      return;
    }
    if (_shoe.remainingCount == 0) {
      _phase = CountDrillPhase.complete;
      onEvent?.call('drill_completed', {
        'session_type': 'one_deck',
        'cards_seen': cardsSeen,
      });
      notifyListeners();
      return;
    }
    _phase = CountDrillPhase.running;
    revealNext();
  }
}
