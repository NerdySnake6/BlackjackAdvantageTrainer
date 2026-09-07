// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get cardAce => 'Ace';

  @override
  String get cardJack => 'Jack';

  @override
  String get cardQueen => 'Queen';

  @override
  String get cardKing => 'King';

  @override
  String get cardClubs => 'clubs';

  @override
  String get cardDiamonds => 'diamonds';

  @override
  String get cardHearts => 'hearts';

  @override
  String get cardSpades => 'spades';

  @override
  String cardDescription(String rank, String suit) {
    return '$rank of $suit';
  }

  @override
  String get adaptiveHelpTitle =>
      'A quick example before the independent block';

  @override
  String get adaptiveChallengeTitle =>
      'Five correct without hints — try one extra card';

  @override
  String get adaptiveOptional =>
      'Optional, unscored practice. You can continue to the unchanged independent tasks.';

  @override
  String get adaptiveHardStand =>
      'This rule boundary caused more than one error. Hard 12 stands against 4–6. Compare 10+2 against 6 (Stand) with the same hand against 3 (Hit).';

  @override
  String get adaptiveHardHit =>
      'This rule boundary caused more than one error. Hard 12 hits against 2–3 and 7–A. A small dealer card does not always mean Stand: against 3 choose Hit, against 4 choose Stand.';

  @override
  String get adaptiveSoftDouble =>
      'The available Double was missed more than once. With A+7 against 3–6, Double is the standard choice. Without Double, use Stand, not Hit.';

  @override
  String get adaptiveSoftStand =>
      'The soft-18 Stand cases caused more than one error. A+7 stands against 2, 7 or 8; against 9, 10 or A it hits.';

  @override
  String get adaptiveSoftHit =>
      'The soft-18 Hit cases caused more than one error. Against 9, 10 or A, choose Hit. The ace can change from 11 to 1, so this is not hard 18.';

  @override
  String get adaptiveSoftFallback =>
      'The unavailable-Double cases caused more than one error. A+2+5 is soft 18, but Double is unavailable after an extra card. Against 3–6, the fallback is Stand.';

  @override
  String get adaptiveCountResult =>
      'More than one final count was incorrect. That alone does not identify the cause. Start with a simple pair: 3 adds +1 and K adds −1; together they leave RC unchanged.';

  @override
  String get adaptiveExtraHard =>
      'An extra card does not change hard 12: Stand against 4–6, Hit against 2–3 and 7–A. There is no timer.';

  @override
  String get adaptiveExtraSoft =>
      'With an extra card, this is still soft 18 but Double is unavailable. Stand against 2–8; Hit against 9, 10 or A. There is no timer.';

  @override
  String get adaptiveExtraCount =>
      'One extra card, the same Hi-Lo tags, no timer. Starting from zero, add the tags shown on the cards; neutral cards do not change RC.';

  @override
  String adaptiveVariant(int number) {
    return 'Practice variant $number';
  }

  @override
  String pilotPracticeBaseline(int correct, int unassisted) {
    return 'Last practice: $correct/10 first answers correct; $unassisted/10 correct without hints.';
  }

  @override
  String pilotPracticeComparison(
    int before,
    int after,
    int beforeUnassisted,
    int afterUnassisted,
  ) {
    return 'Previous → latest practice: $before/10 → $after/10 correct; without hints: $beforeUnassisted/10 → $afterUnassisted/10.';
  }

  @override
  String get pilotPracticeComparisonNote =>
      'These are repeated practice tasks, not a new-task mastery result.';

  @override
  String get pilotTitle => 'Three game lessons · pilot';

  @override
  String get pilotWarmup => 'Introduction · unscored';

  @override
  String get pilotPractice => 'Practice · first answers count';

  @override
  String get pilotIndependent => 'Independent practice · no hints';

  @override
  String get pilotHint => 'Show hint';

  @override
  String get pilotCorrectTask =>
      'Try the correct answer on these same cards to continue. Your first answer stays recorded.';

  @override
  String get pilotCorrected => 'Corrected';

  @override
  String get pilotRevealBeforeCount =>
      'Reveal all the cards, then enter the final running count.';

  @override
  String get pilotDoubleAvailable =>
      'Double is available on this two-card hand.';

  @override
  String get pilotDoubleUnavailable => 'Double is unavailable for this hand.';

  @override
  String get pilotResultNote =>
      '80% first answers passes this lesson. This fixed practice does not confirm mastery; take the separate check on new tasks.';

  @override
  String pilotMasteryStatus(int percent) {
    return 'New-task check: $percent% first answers';
  }

  @override
  String get pilotMastered =>
      'Lesson check passed. This is not a full strategy or whole-deck certificate.';

  @override
  String get pilotMasteryPending =>
      'Lesson check not passed yet. Review the explanations before trying a fresh form.';

  @override
  String get checkpointTitle => 'Check on new tasks';

  @override
  String get checkpointIntro =>
      '10 new tasks, at least 9 correct first answers. No timer, hints or feedback until the end. Each answer is saved; leaving resumes the same form. No additional XP. This narrow check does not certify the whole skill.';

  @override
  String get checkpointSoftScope =>
      'This form checks soft 18 with extra cards, when Double is unavailable.';

  @override
  String get checkpointBegin => 'Start new-task check';

  @override
  String get checkpointNextForm => 'Try a fresh form';

  @override
  String get checkpointExhausted =>
      'No unused forms remain in this version. You can practise the lesson, but repeating these answers cannot confirm mastery.';

  @override
  String get checkpointIncompatible =>
      'This saved check cannot be verified with the current content. It has been preserved, but does not confirm mastery. Your other progress is unchanged.';

  @override
  String checkpointReview(String actual, String expected) {
    return 'Your answer: $actual. Correct answer: $expected.';
  }

  @override
  String get pilotSaveFailed =>
      'Could not save. Your last change was not applied. Try the action again before leaving.';

  @override
  String get pilotIncompatible =>
      'This saved lesson cannot be resumed with this content. Restart only this lesson; your XP and other progress will remain.';

  @override
  String get pilotDecrease => 'Decrease count';

  @override
  String get pilotIncrease => 'Increase count';

  @override
  String pilotStartingCount(int count) {
    return 'Starting RC: $count';
  }

  @override
  String pilotUnassisted(int count) {
    return 'Without hints: $count/10';
  }

  @override
  String pilotStars(int count) {
    return 'Stars: $count/3';
  }

  @override
  String pilotReward(int count) {
    return 'Earned: $count XP';
  }

  @override
  String pilotSelected(String answer) {
    return 'Your first answer: $answer';
  }

  @override
  String get diagnosticTitle => 'Quick skill check';

  @override
  String get diagnosticIntro =>
      'Four untimed questions suggest where to practise next. This is not a certificate.';

  @override
  String get diagnosticStart => 'Start check';

  @override
  String diagnosticQuestionProgress(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String get diagnosticQ1 =>
      'What mainly changes the best basic-strategy action?';

  @override
  String get diagnosticQ1A => 'The dealer up-card and your hand';

  @override
  String get diagnosticQ1B => 'The last round\'s result';

  @override
  String get diagnosticQ1C => 'The size of the table';

  @override
  String get diagnosticQ2 =>
      'When is Double normally available in this trainer?';

  @override
  String get diagnosticQ2A => 'On a two-card hand when the rules allow it';

  @override
  String get diagnosticQ2B => 'After any hit';

  @override
  String get diagnosticQ2C => 'Only after winning a round';

  @override
  String get diagnosticQ3 => 'In Hi-Lo, what tag does a 5 receive?';

  @override
  String get diagnosticQ3A => '+1';

  @override
  String get diagnosticQ3B => '0';

  @override
  String get diagnosticQ3C => '−1';

  @override
  String get diagnosticQ4 => 'When should you reset a running count?';

  @override
  String get diagnosticQ4A => 'After every hand';

  @override
  String get diagnosticQ4B => 'When the dealer shows an ace';

  @override
  String get diagnosticQ4C => 'When the shoe is shuffled';

  @override
  String get diagnosticResultTitle => 'Suggested next focus';

  @override
  String get diagnosticRecommendationStrategy =>
      'Practise basic-strategy decisions first.';

  @override
  String get diagnosticRecommendationCount =>
      'Practise Hi-Lo and running count first.';

  @override
  String get diagnosticRecommendationCombined =>
      'Alternate basic strategy with running-count practice.';

  @override
  String get diagnosticResultNote =>
      'This check only suggests a starting point. It does not unlock lessons or certify mastery.';

  @override
  String get diagnosticRestart => 'Run again';

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

  @override
  String get languageLabel => 'Language';

  @override
  String get systemDefault => 'System default';

  @override
  String get englishLanguage => 'English';

  @override
  String get russianLanguage => 'Русский';
}
