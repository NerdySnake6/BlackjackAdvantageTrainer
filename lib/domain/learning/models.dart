/// Versioned learning-content and progress models.
library;

enum ExperienceLevel {
  beginner('quick-start'),
  basics('hard-and-soft'),
  experienced('first-strategy');

  const ExperienceLevel(this.startLessonId);

  final String startLessonId;

  static ExperienceLevel? fromStorage(String? value) {
    return switch (value) {
      'beginner' => ExperienceLevel.beginner,
      'basics' => ExperienceLevel.basics,
      'experienced' => ExperienceLevel.experienced,
      _ => null,
    };
  }
}

class CourseCatalog {
  const CourseCatalog({
    required this.contentVersion,
    required this.locale,
    required this.sections,
  });

  factory CourseCatalog.fromJson(Map<String, Object?> json) {
    return CourseCatalog(
      contentVersion: json['contentVersion']! as int,
      locale: json['locale']! as String,
      sections: (json['sections']! as List<Object?>)
          .map((item) => CourseSection.fromJson(item! as Map<String, Object?>))
          .toList(growable: false),
    );
  }

  final int contentVersion;
  final String locale;
  final List<CourseSection> sections;

  List<LessonDefinition> get lessons => [
    for (final section in sections) ...section.lessons,
  ];

  LessonDefinition lessonById(String lessonId) {
    return lessons.firstWhere((lesson) => lesson.id == lessonId);
  }
}

class CourseSection {
  const CourseSection({
    required this.id,
    required this.title,
    required this.summary,
    required this.isPro,
    required this.lessons,
  });

  factory CourseSection.fromJson(Map<String, Object?> json) {
    return CourseSection(
      id: json['id']! as String,
      title: json['title']! as String,
      summary: json['summary']! as String,
      isPro: json['isPro']! as bool,
      lessons: (json['lessons']! as List<Object?>)
          .map(
            (item) => LessonDefinition.fromJson(item! as Map<String, Object?>),
          )
          .toList(growable: false),
    );
  }

  final String id;
  final String title;
  final String summary;
  final bool isPro;
  final List<LessonDefinition> lessons;
}

class LessonDefinition {
  const LessonDefinition({
    required this.id,
    required this.skillId,
    required this.title,
    required this.subtitle,
    required this.estimatedMinutes,
    required this.exercises,
  });

  factory LessonDefinition.fromJson(Map<String, Object?> json) {
    return LessonDefinition(
      id: json['id']! as String,
      skillId: json['skillId']! as String,
      title: json['title']! as String,
      subtitle: json['subtitle']! as String,
      estimatedMinutes: json['estimatedMinutes']! as int,
      exercises: (json['exercises']! as List<Object?>)
          .map((item) => LessonExercise.fromJson(item! as Map<String, Object?>))
          .toList(growable: false),
    );
  }

  final String id;
  final String skillId;
  final String title;
  final String subtitle;
  final int estimatedMinutes;
  final List<LessonExercise> exercises;
}

class LessonExercise {
  const LessonExercise({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory LessonExercise.fromJson(Map<String, Object?> json) {
    return LessonExercise(
      id: json['id']! as String,
      prompt: json['prompt']! as String,
      options: (json['options']! as List<Object?>).cast<String>(),
      correctIndex: json['correctIndex']! as int,
      explanation: json['explanation']! as String,
    );
  }

  final String id;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;
}

class ExerciseAttempt {
  const ExerciseAttempt({
    required this.exerciseId,
    required this.selectedIndex,
    required this.isCorrect,
    required this.answeredAt,
  });

  final String exerciseId;
  final int selectedIndex;
  final bool isCorrect;
  final DateTime answeredAt;
}

class LessonSessionProgress {
  const LessonSessionProgress({
    required this.nextExerciseIndex,
    required this.correctAnswers,
    this.lastSelectedIndex,
    this.lastAnswerWasCorrect,
  });

  factory LessonSessionProgress.fromJson(Map<String, Object?> json) {
    return LessonSessionProgress(
      nextExerciseIndex: json['nextExerciseIndex']! as int,
      correctAnswers: json['correctAnswers']! as int,
      lastSelectedIndex: json['lastSelectedIndex'] as int?,
      lastAnswerWasCorrect: json['lastAnswerWasCorrect'] as bool?,
    );
  }

  final int nextExerciseIndex;
  final int correctAnswers;
  final int? lastSelectedIndex;
  final bool? lastAnswerWasCorrect;

  Map<String, Object?> toJson() => {
    'nextExerciseIndex': nextExerciseIndex,
    'correctAnswers': correctAnswers,
    'lastSelectedIndex': lastSelectedIndex,
    'lastAnswerWasCorrect': lastAnswerWasCorrect,
  };
}

class ProgressSnapshot {
  const ProgressSnapshot({
    this.lessonScores = const {},
    this.activeSessions = const {},
    this.experienceLevel,
    this.hasSeenCountDrillIntro = false,
    this.xp = 0,
    this.streakDays = 0,
    this.lastActivityDate,
  });

  factory ProgressSnapshot.fromJson(Map<String, Object?> json) {
    final rawScores = json['lessonScores'] as Map<String, Object?>? ?? {};
    final rawSessions = json['activeSessions'] as Map<String, Object?>? ?? {};
    return ProgressSnapshot(
      lessonScores: rawScores.map(
        (key, value) => MapEntry(key, (value! as num).toDouble()),
      ),
      activeSessions: rawSessions.map(
        (key, value) => MapEntry(
          key,
          LessonSessionProgress.fromJson(value! as Map<String, Object?>),
        ),
      ),
      experienceLevel: ExperienceLevel.fromStorage(
        json['experienceLevel'] as String?,
      ),
      hasSeenCountDrillIntro: json['hasSeenCountDrillIntro'] as bool? ?? false,
      xp: json['xp'] as int? ?? 0,
      streakDays: json['streakDays'] as int? ?? 0,
      lastActivityDate: json['lastActivityDate'] == null
          ? null
          : DateTime.parse(json['lastActivityDate']! as String),
    );
  }

  final Map<String, double> lessonScores;
  final Map<String, LessonSessionProgress> activeSessions;
  final ExperienceLevel? experienceLevel;
  final bool hasSeenCountDrillIntro;
  final int xp;
  final int streakDays;
  final DateTime? lastActivityDate;

  double get averageMastery {
    if (lessonScores.isEmpty) {
      return 0;
    }
    return lessonScores.values.reduce((a, b) => a + b) / lessonScores.length;
  }

  Map<String, Object?> toJson() => {
    'lessonScores': lessonScores,
    'activeSessions': activeSessions.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
    'experienceLevel': experienceLevel?.name,
    'hasSeenCountDrillIntro': hasSeenCountDrillIntro,
    'xp': xp,
    'streakDays': streakDays,
    'lastActivityDate': lastActivityDate?.toIso8601String(),
  };

  ProgressSnapshot copyWith({
    Map<String, double>? lessonScores,
    Map<String, LessonSessionProgress>? activeSessions,
    ExperienceLevel? experienceLevel,
    bool? hasSeenCountDrillIntro,
    int? xp,
    int? streakDays,
    DateTime? lastActivityDate,
    bool clearLastActivityDate = false,
  }) {
    return ProgressSnapshot(
      lessonScores: lessonScores ?? this.lessonScores,
      activeSessions: activeSessions ?? this.activeSessions,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      hasSeenCountDrillIntro:
          hasSeenCountDrillIntro ?? this.hasSeenCountDrillIntro,
      xp: xp ?? this.xp,
      streakDays: streakDays ?? this.streakDays,
      lastActivityDate: clearLastActivityDate
          ? null
          : lastActivityDate ?? this.lastActivityDate,
    );
  }
}
