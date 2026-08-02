// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Blackjack Advantage';

  @override
  String get learnTab => 'Learn';

  @override
  String get drillTab => 'Drill';

  @override
  String get tableTab => 'Table';

  @override
  String get profileTab => 'Progress';

  @override
  String get learningPath => 'Learning path';

  @override
  String get learningPathSubtitle =>
      'Build perfect decisions before adding speed.';

  @override
  String get prototypeBuild => '6-lesson validation build';

  @override
  String get experienceLevelTitle => 'Where should we start?';

  @override
  String get experienceLevelSubtitle =>
      'Choose the starting point that fits your blackjack experience. You can review every earlier lesson later.';

  @override
  String get beginnerLevelTitle => 'I\'m new to blackjack';

  @override
  String get beginnerLevelDescription =>
      'Start with the rules, the first hand, and the decisions you need at the table.';

  @override
  String get basicsLevelTitle => 'I know the basics';

  @override
  String get basicsLevelDescription =>
      'Skip the introduction and begin with hard and soft hands.';

  @override
  String get experiencedLevelTitle => 'I\'m an experienced player';

  @override
  String get experiencedLevelDescription =>
      'Jump into common basic-strategy decisions and use earlier lessons as optional review.';

  @override
  String get experienceLevelNote =>
      'This changes your recommended starting point, not your saved progress.';

  @override
  String get recommendedStart => 'Start here';

  @override
  String minutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String get mastered => 'Mastered';

  @override
  String get inProgress => 'In progress';

  @override
  String get freeLabel => 'FREE';

  @override
  String get proLabel => 'PRO';

  @override
  String get startLesson => 'Start lesson';

  @override
  String get continueLesson => 'Continue lesson';

  @override
  String get lockedLesson => 'Complete the previous lesson to unlock';

  @override
  String get lessonComplete => 'Lesson complete';

  @override
  String get lessonCompleteSubtitle =>
      'Accuracy unlocks the next node. Mastery still requires repetition.';

  @override
  String lessonResult(int correct, int total) {
    return '$correct of $total correct';
  }

  @override
  String get correctAnswer => 'Correct';

  @override
  String get incorrectAnswer => 'Not quite';

  @override
  String get next => 'Next';

  @override
  String get finish => 'Finish';

  @override
  String get backToPath => 'Back to path';

  @override
  String get countdownTitle => 'Running count';

  @override
  String get countdownSubtitle =>
      'Keep a Hi-Lo count as each card is revealed.';

  @override
  String get startDrill => 'Start one-deck drill';

  @override
  String get nextCard => 'Reveal next card';

  @override
  String get submitCount => 'Check count';

  @override
  String get yourCount => 'Your count';

  @override
  String cardsSeen(int count) {
    return '$count cards seen';
  }

  @override
  String get checkpoint => 'Checkpoint';

  @override
  String get countCorrect => 'Count is correct. Keep going.';

  @override
  String countIncorrect(int count) {
    return 'The exact count was $count.';
  }

  @override
  String get drillComplete => 'Deck complete';

  @override
  String get drillCompleteSubtitle =>
      'A complete Hi-Lo deck always returns to zero.';

  @override
  String get restartDrill => 'Run another deck';

  @override
  String get revealInstruction =>
      'Memorize the count, then reveal the next card.';

  @override
  String get adjustCountInstruction =>
      'Set the running count you have in mind.';

  @override
  String get newRound => 'New round';

  @override
  String get hit => 'Hit';

  @override
  String get stand => 'Stand';

  @override
  String get doubleAction => 'Double';

  @override
  String get split => 'Split';

  @override
  String get surrender => 'Surrender';

  @override
  String get dealer => 'Dealer';

  @override
  String seat(int number) {
    return 'Seat $number';
  }

  @override
  String get human => 'Human';

  @override
  String get bot => 'Bot';

  @override
  String get empty => 'Empty';

  @override
  String get configureSeats => 'Configure seats';

  @override
  String get configureSeatsHint =>
      'Tap a seat to cycle Human → Bot → Empty. Keep at least one Human.';

  @override
  String get done => 'Done';

  @override
  String currentCount(int count) {
    return 'Running count: $count';
  }

  @override
  String shoeStatus(int dealt, int total) {
    return '$dealt / $total cards dealt';
  }

  @override
  String get turnPrompt => 'Choose the best action';

  @override
  String get roundComplete => 'Round complete';

  @override
  String get startFirstRound => 'Deal the first round';

  @override
  String get guidedMode => 'GUIDED TABLE';

  @override
  String get hiddenCard => 'Hidden card';

  @override
  String handTotal(int total) {
    return 'Total $total';
  }

  @override
  String resultUnits(String outcome, String units) {
    return '$outcome · $units units';
  }

  @override
  String get outcomeBlackjack => 'Blackjack';

  @override
  String get outcomeWin => 'Win';

  @override
  String get outcomePush => 'Push';

  @override
  String get outcomeLoss => 'Loss';

  @override
  String get outcomeSurrender => 'Surrender';

  @override
  String get reshuffled => 'The shoe was reshuffled at 75% penetration.';

  @override
  String get progressTitle => 'Your progress';

  @override
  String get progressSubtitle =>
      'Motivation and mastery are measured separately.';

  @override
  String get xpLabel => 'XP';

  @override
  String get streakLabel => 'day streak';

  @override
  String get masteryLabel => 'Path mastery';

  @override
  String lessonsCompleted(int completed, int total) {
    return '$completed of $total prototype lessons completed';
  }

  @override
  String get privacyNote =>
      'Analytics and crash reporting are off in this prototype.';

  @override
  String get educationDisclaimer =>
      'Training simulation only. Skill does not guarantee gambling profit.';

  @override
  String get proComingSoon => 'Pro course coming later';

  @override
  String get settings => 'Settings';

  @override
  String get resetProgress => 'Reset prototype progress';

  @override
  String get resetConfirmation => 'Reset all lesson progress and XP?';

  @override
  String get cancel => 'Cancel';

  @override
  String get reset => 'Reset';

  @override
  String get loadFailureTitle => 'The training content could not be loaded';

  @override
  String get loadFailureBody =>
      'Restart the app. If the problem continues, reinstall this prototype.';
}
