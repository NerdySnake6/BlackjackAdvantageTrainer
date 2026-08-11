/// Presentation state for a short spaced-review session.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/learning/answer_order.dart';
import '../domain/learning/models.dart';
import 'app_state.dart';

class QuickReviewViewModel extends ChangeNotifier {
  QuickReviewViewModel({required this.appState})
    : exercises = appState.reviewExercises() {
    unawaited(
      appState.trackTrainingEvent('quick_review_started', {
        'exercise_count': exercises.length,
      }),
    );
  }

  final AppState appState;
  final List<LessonExercise> exercises;
  late final List<List<int>> _optionOrders = deterministicAnswerOrders(
    exercises,
  );
  var _index = 0;
  int? _selectedIndex;
  var _answerIsCorrect = false;
  var _correctAnswers = 0;
  var _isComplete = false;

  bool get isEmpty => exercises.isEmpty;
  bool get isComplete => _isComplete;
  int get index => _index;
  int get correctAnswers => _correctAnswers;
  int? get selectedIndex => _selectedIndex;
  bool get hasAnswered => _selectedIndex != null;
  bool get answerIsCorrect => _answerIsCorrect;
  LessonExercise get currentExercise => exercises[_index];
  List<int> get currentOptionOrder => _optionOrders[_index];
  List<String> get currentOptions => [
    for (final optionIndex in currentOptionOrder)
      currentExercise.options[optionIndex],
  ];
  int get currentCorrectIndex =>
      currentOptionOrder.indexOf(currentExercise.correctIndex);

  Future<void> answer(int selectedIndex) async {
    if (isEmpty || hasAnswered || isComplete) {
      return;
    }
    _selectedIndex = selectedIndex;
    _answerIsCorrect = selectedIndex == currentCorrectIndex;
    if (_answerIsCorrect) {
      _correctAnswers++;
    }
    notifyListeners();
    await appState.recordReviewAttempt(
      exerciseId: currentExercise.id,
      wasCorrect: _answerIsCorrect,
    );
  }

  void next() {
    if (!hasAnswered) {
      return;
    }
    if (_index == exercises.length - 1) {
      _isComplete = true;
      unawaited(
        appState.trackTrainingEvent('quick_review_completed', {
          'exercise_count': exercises.length,
          'correct_answers': _correctAnswers,
        }),
      );
    } else {
      _index++;
      _selectedIndex = null;
      _answerIsCorrect = false;
    }
    notifyListeners();
  }
}
