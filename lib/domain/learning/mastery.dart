/// Learning-score and spaced-review policies.
library;

class SessionScorer {
  const SessionScorer();

  double score({required int correctAnswers, required int totalAnswers}) {
    if (totalAnswers <= 0) {
      return 0;
    }
    return correctAnswers / totalAnswers;
  }

  bool isLessonComplete(double score) => score >= 0.8;
  bool needsReview(double score) => score < 0.8;
}

class ReviewScheduler {
  const ReviewScheduler();

  static const intervals = [1, 3, 7, 14, 30];

  DateTime nextReview({
    required DateTime completedAt,
    required int successfulReviews,
    required bool wasCorrect,
  }) {
    final intervalIndex = wasCorrect
        ? successfulReviews.clamp(0, intervals.length - 1)
        : 0;
    return completedAt.add(Duration(days: intervals[intervalIndex]));
  }
}
