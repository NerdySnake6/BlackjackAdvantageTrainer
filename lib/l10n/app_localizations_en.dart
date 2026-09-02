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
  String get prototypeBuild => '6-lesson foundation course';

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
  String get telemetryConsentTitle => 'Help improve the training';

  @override
  String get telemetryConsentBody =>
      'Choose separately whether to share anonymous usage events and technical crash reports.';

  @override
  String get usageAnalyticsTitle => 'Usage analytics';

  @override
  String get usageAnalyticsDescription =>
      'Share stable lesson IDs, session types, and aggregate correctness. Answer text and card sequences are never sent.';

  @override
  String get crashReportsTitle => 'Crash reports';

  @override
  String get crashReportsDescription =>
      'Share fatal technical diagnostics so crashes can be fixed. No gameplay content or personal profile is attached.';

  @override
  String get telemetryOptionalNote =>
      'Both choices are optional. Saying no does not limit the app, and you can change them in Progress.';

  @override
  String get saveAndContinue => 'Save and continue';

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
      'Accuracy unlocked the next node. Keep reviewing to retain the skill.';

  @override
  String get lessonNeedsReview => 'Lesson finished — review required';

  @override
  String get lessonNeedsReviewSubtitle =>
      'Reach at least 80% accuracy to unlock the next lesson.';

  @override
  String get retryLesson => 'Review and try again';

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
  String get quickReviewTitle => 'Quick Review';

  @override
  String get quickReviewReadyLater =>
      'Weak and due exercises will appear here.';

  @override
  String quickReviewDue(int count) {
    return '$count exercises ready · about 3–5 min';
  }

  @override
  String quickReviewProgress(int current, int total) {
    return 'Review $current of $total';
  }

  @override
  String get quickReviewEmptyTitle => 'Nothing to review yet';

  @override
  String get quickReviewEmptyBody =>
      'Complete a few lesson exercises, then return for a focused review.';

  @override
  String get quickReviewComplete => 'Review complete';

  @override
  String quickReviewResult(int correct, int total) {
    return '$correct of $total correct. Your next review dates were updated.';
  }

  @override
  String get countdownTitle => 'Running count';

  @override
  String get countdownSubtitle =>
      'Keep a Hi-Lo count as each card is revealed.';

  @override
  String get countDrillIntroTitle => 'Before your first count';

  @override
  String get countDrillIntroBody =>
      'Hi-Lo tracks exposed cards in the current shoe. Start at 0 and keep one running total.';

  @override
  String get countDrillIntroLowCards => '2–6  →  +1';

  @override
  String get countDrillIntroNeutralCards => '7–9  →  0';

  @override
  String get countDrillIntroHighCards => '10, J, Q, K, A  →  −1';

  @override
  String get countDrillIntroDeckNote =>
      'All 52 cards of one complete deck sum to 0 in Hi-Lo. In a multi-deck shoe, any 52 cards are only a mixed segment: keep the running count until the shoe is shuffled.';

  @override
  String get countDrillIntroKnown =>
      'I know these rules — don\'t show this again';

  @override
  String get countDrillIntroContinue => 'Got it';

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
      'Choose Human, Bot, or Empty for each seat. Changes during a round apply to the next round. Keep at least one Human.';

  @override
  String get seatChangesPending => 'Seat changes will apply to the next round.';

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
  String get practiceMode => 'PRACTICE TABLE';

  @override
  String get guidedModeName => 'Guided';

  @override
  String get practiceModeName => 'Practice';

  @override
  String tableRoundProgress(int completed, int total) {
    return 'Round $completed / $total';
  }

  @override
  String recommendedAction(String action) {
    return 'Recommended: $action';
  }

  @override
  String get continueAction => 'Continue';

  @override
  String get tableCountPrompt => 'What is the running count?';

  @override
  String get tableSessionComplete => 'Five-round session complete';

  @override
  String strategyAccuracy(int percent) {
    return 'Strategy $percent%';
  }

  @override
  String countAccuracy(int percent) {
    return 'Count $percent%';
  }

  @override
  String get startAnotherSession => 'Another session';

  @override
  String get strategyReasonSplitPair =>
      'Splitting this pair creates the stronger long-run play.';

  @override
  String get strategyReasonStandPair =>
      'This pair should stay together against this dealer card.';

  @override
  String get strategyReasonDoublePair =>
      'Play these cards as a hard ten and double against this dealer card.';

  @override
  String get strategyReasonHitPair =>
      'This pair is stronger when played as a regular hand.';

  @override
  String get strategyReasonSurrenderHard =>
      'Late surrender loses less than playing this weak hard total.';

  @override
  String get strategyReasonDoubleSoft =>
      'The soft total has enough upside to double against this dealer card.';

  @override
  String get strategyReasonStandSoft =>
      'This soft total is already strong enough to stand.';

  @override
  String get strategyReasonHitSoft =>
      'The ace protects the hand while another card can improve it.';

  @override
  String get strategyReasonDoubleHard =>
      'This hard total has an advantage against the dealer\'s up-card.';

  @override
  String get strategyReasonStandHard =>
      'The dealer is more likely to break; avoid taking another card.';

  @override
  String get strategyReasonHitHard =>
      'Standing is too weak here; take another card.';

  @override
  String get strategyReasonFallback =>
      'The preferred move is unavailable, so use the safest legal fallback.';

  @override
  String get standardRulesName =>
      'Standard six-deck · S17 · DAS · late surrender · 3:2';

  @override
  String get practiceUnits => 'Practice unit';

  @override
  String get dealingCards => 'Dealing cards...';

  @override
  String get dealerTurn => 'Dealer is resolving the round.';

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
  String get masteryLabel => 'Lesson accuracy';

  @override
  String get experienceSettingTitle => 'Experience level';

  @override
  String get experienceSettingSubtitle =>
      'Change your recommended starting point without deleting progress.';

  @override
  String lessonsCompleted(int completed, int total) {
    return '$completed of $total lessons completed';
  }

  @override
  String get privacyChoicesTitle => 'Privacy choices';

  @override
  String get privacyChoicesSubtitle =>
      'Optional collection stays off unless you enable it.';

  @override
  String get privacyNote =>
      'Telemetry follows your separate opt-in choices. Answer text, card sequences, and personal data are not collected.';

  @override
  String get educationDisclaimer =>
      'Training simulation only. Skill does not guarantee gambling profit.';

  @override
  String get proComingSoon => 'Pro course coming later';

  @override
  String get settings => 'Settings';

  @override
  String get resetProgress => 'Reset progress';

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
      'Restart the app. If the problem continues, reinstall the app.';
}
