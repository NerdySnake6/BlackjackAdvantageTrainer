/// Versioned, authored building blocks shared by playable Learn lessons.
library;

enum LessonMissionKind {
  decision,
  runningCount,
  handTotal,
  handType,
  handOutcome,
  actionMeaning,
}

enum LessonMissionStage { introduction, practice, independent }

class LessonTheory {
  LessonTheory.fromJson(Map<String, Object?> json)
    : id = json['id']! as String,
      text = json['text']! as String;

  final String id;
  final String text;
}

class LessonCoaching {
  LessonCoaching.fromJson(Map<String, Object?> json)
    : explanation = json['explanation']! as String,
      contrast = json['contrast']! as String,
      mistakes = Map<String, String>.unmodifiable(
        Map<String, String>.from(json['mistakes']! as Map),
      );

  final String explanation;
  final String contrast;
  final Map<String, String> mistakes;
}

/// First answers determine completion; correction never replaces an attempt.
class LessonScoring {
  LessonScoring.fromJson(Map<String, Object?> json)
    : policyId = json['policyId']! as String,
      passCorrect = json['passCorrect']! as int,
      starCorrect = List<int>.unmodifiable(json['starCorrect']! as List),
      topStarRequiresUnassisted = json['topStarRequiresUnassisted']! as bool {
    // The current policy is the approved ten-answer ordinary-lesson contract.
    if (policyId != 'first_answer_v1' ||
        passCorrect != 8 ||
        starCorrect.join(',') != '8,9,10' ||
        !topStarRequiresUnassisted) {
      throw const FormatException('Unsupported lesson scoring policy');
    }
  }

  final String policyId;
  final int passCorrect;
  final List<int> starCorrect;
  final bool topStarRequiresUnassisted;

  bool passes(int correct) => correct >= passCorrect;

  int stars({required int correct, required int unassisted}) {
    var earned = 0;
    for (var i = 0; i < starCorrect.length; i++) {
      if (correct >= starCorrect[i] &&
          (i < starCorrect.length - 1 ||
              !topStarRequiresUnassisted ||
              unassisted >= starCorrect[i])) {
        earned = i + 1;
      }
    }
    return earned;
  }
}
