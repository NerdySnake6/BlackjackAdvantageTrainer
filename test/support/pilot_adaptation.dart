import 'package:blackjack_advantage_trainer/domain/learning/decision_lesson.dart';
import 'package:blackjack_advantage_trainer/domain/learning/pilot_lesson.dart';

/// Reaches the boundary after the five practice tasks in the current pilots.
DecisionLessonSession boundary(
  PilotLesson lesson, {
  Set<int> errors = const {},
  bool hinted = false,
}) {
  final session = DecisionLessonSession(lesson)..begin();
  for (var i = 0; i < 7; i++) {
    if (i == 2 && hinted) session.useHint();
    while (session.current.isCounting && !session.canAnswer) {
      session.reveal();
    }
    final task = session.current;
    final wrong = task.isCounting
        ? '${int.parse(task.expected) + 1}'
        : task.expected == 'hit'
        ? 'stand'
        : 'hit';
    session.answer(errors.contains(i) ? wrong : task.expected);
    if (errors.contains(i)) session.answer(task.expected);
    if (i < 6) session.next();
  }
  return session;
}
