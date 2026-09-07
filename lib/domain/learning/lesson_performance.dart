/// Practice evidence and the compatibility adapter for existing XP rewards.
library;

import 'decision_lesson.dart';

class PilotRewardAdapter {
  const PilotRewardAdapter();

  int xp({required int correct, required bool firstCompletion}) {
    if (correct < 0 || correct > 10) throw ArgumentError.value(correct);
    return correct * 10 + (firstCompletion && correct >= 8 ? 50 : 0);
  }
}

/// One completed practice attempt, never a mastery certificate or best score.
class LessonPerformance {
  LessonPerformance.fromSession(DecisionLessonSession session)
    : attempt = session.attempt,
      signature = session.lesson.resumeSignature,
      correct = session.correctAnswers,
      unassisted = session.unassistedAnswers {
    if (session.phase != DecisionLessonPhase.result) {
      throw StateError('Only finished practice can be compared');
    }
  }

  LessonPerformance.fromJson(Map<String, Object?> json)
    : attempt = json['attempt']! as int,
      signature = json['signature']! as String,
      correct = json['correct']! as int,
      unassisted = json['unassisted']! as int {
    if (attempt < 1 ||
        signature.isEmpty ||
        correct < 0 ||
        correct > 10 ||
        unassisted < 0 ||
        unassisted > correct) {
      throw const FormatException('Invalid practice performance');
    }
  }

  final int attempt;
  final String signature;
  final int correct;
  final int unassisted;

  bool comparableTo(LessonPerformance other) =>
      signature == other.signature && attempt > other.attempt;

  Map<String, Object?> toJson() => {
    'attempt': attempt,
    'signature': signature,
    'correct': correct,
    'unassisted': unassisted,
  };
}
