/// Presentation state for a resumable lesson session.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../domain/learning/answer_order.dart';
import '../domain/learning/models.dart';
import 'app_state.dart';

class LessonViewModel extends ChangeNotifier {
  LessonViewModel({required this.appState, required this.lesson}) {
    unawaited(
      appState.trackTrainingEvent('lesson_started', {'lesson_id': lesson.id}),
    );
    final saved = appState.sessionFor(lesson.id);
    if (saved != null) {
      _exerciseIndex = min(
        saved.nextExerciseIndex,
        lesson.exercises.length - 1,
      );
      _correctAnswers = saved.correctAnswers;
      if (saved.nextExerciseIndex >= lesson.exercises.length) {
        _selectedIndex = saved.lastSelectedIndex ?? currentCorrectIndex;
        _answerIsCorrect = saved.lastAnswerWasCorrect ?? true;
      }
    }
  }

  final AppState appState;
  final LessonDefinition lesson;
  var _exerciseIndex = 0;
  var _correctAnswers = 0;
  int? _selectedIndex;
  bool _answerIsCorrect = false;
  bool _isComplete = false;
  double _finalScore = 0;

  int get exerciseIndex => _exerciseIndex;
  int get correctAnswers => _correctAnswers;
  int? get selectedIndex => _selectedIndex;
  bool get answerIsCorrect => _answerIsCorrect;
  bool get hasAnswered => _selectedIndex != null;
  bool get isComplete => _isComplete;
  double get finalScore => _finalScore;
  bool get passed => _finalScore >= 0.8;
  bool get isLastExercise => _exerciseIndex == lesson.exercises.length - 1;
  LessonExercise get currentExercise => lesson.exercises[_exerciseIndex];
  List<int> get currentOptionOrder => deterministicAnswerOrder(
    currentExercise.id,
    currentExercise.options.length,
  );
  List<String> get currentOptions => [
    for (final index in currentOptionOrder) currentExercise.options[index],
  ];
  int get currentCorrectIndex =>
      currentOptionOrder.indexOf(currentExercise.correctIndex);

  Future<void> answer(int selectedIndex) async {
    if (hasAnswered || _isComplete) {
      return;
    }
    _selectedIndex = selectedIndex;
    _answerIsCorrect = selectedIndex == currentCorrectIndex;
    if (_answerIsCorrect) {
      _correctAnswers++;
    }
    notifyListeners();
    await appState.saveSession(
      lessonId: lesson.id,
      nextExerciseIndex: min(_exerciseIndex + 1, lesson.exercises.length),
      correctAnswers: _correctAnswers,
      selectedIndex: selectedIndex,
      answerWasCorrect: _answerIsCorrect,
      exerciseId: currentExercise.id,
    );
  }

  Future<void> next() async {
    if (!hasAnswered) {
      return;
    }
    if (isLastExercise) {
      _finalScore = await appState.completeLesson(
        lesson: lesson,
        correctAnswers: _correctAnswers,
      );
      _isComplete = true;
    } else {
      _exerciseIndex++;
      _selectedIndex = null;
      _answerIsCorrect = false;
    }
    notifyListeners();
  }

  void retry() {
    _exerciseIndex = 0;
    _correctAnswers = 0;
    _selectedIndex = null;
    _answerIsCorrect = false;
    _isComplete = false;
    _finalScore = 0;
    notifyListeners();
  }
}
