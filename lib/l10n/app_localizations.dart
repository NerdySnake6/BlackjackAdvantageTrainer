import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Blackjack Advantage'**
  String get appTitle;

  /// No description provided for @learnTab.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get learnTab;

  /// No description provided for @drillTab.
  ///
  /// In en, this message translates to:
  /// **'Drill'**
  String get drillTab;

  /// No description provided for @tableTab.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get tableTab;

  /// No description provided for @profileTab.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get profileTab;

  /// No description provided for @learningPath.
  ///
  /// In en, this message translates to:
  /// **'Learning path'**
  String get learningPath;

  /// No description provided for @learningPathSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Build perfect decisions before adding speed.'**
  String get learningPathSubtitle;

  /// No description provided for @prototypeBuild.
  ///
  /// In en, this message translates to:
  /// **'6-lesson foundation course'**
  String get prototypeBuild;

  /// No description provided for @experienceLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'Where should we start?'**
  String get experienceLevelTitle;

  /// No description provided for @experienceLevelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the starting point that fits your blackjack experience. You can review every earlier lesson later.'**
  String get experienceLevelSubtitle;

  /// No description provided for @beginnerLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'I\'m new to blackjack'**
  String get beginnerLevelTitle;

  /// No description provided for @beginnerLevelDescription.
  ///
  /// In en, this message translates to:
  /// **'Start with the rules, the first hand, and the decisions you need at the table.'**
  String get beginnerLevelDescription;

  /// No description provided for @basicsLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'I know the basics'**
  String get basicsLevelTitle;

  /// No description provided for @basicsLevelDescription.
  ///
  /// In en, this message translates to:
  /// **'Skip the introduction and begin with hard and soft hands.'**
  String get basicsLevelDescription;

  /// No description provided for @experiencedLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'I\'m an experienced player'**
  String get experiencedLevelTitle;

  /// No description provided for @experiencedLevelDescription.
  ///
  /// In en, this message translates to:
  /// **'Jump into common basic-strategy decisions and use earlier lessons as optional review.'**
  String get experiencedLevelDescription;

  /// No description provided for @experienceLevelNote.
  ///
  /// In en, this message translates to:
  /// **'This changes your recommended starting point, not your saved progress.'**
  String get experienceLevelNote;

  /// No description provided for @telemetryConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Help improve the training'**
  String get telemetryConsentTitle;

  /// No description provided for @telemetryConsentBody.
  ///
  /// In en, this message translates to:
  /// **'Choose separately whether to share anonymous usage events and technical crash reports.'**
  String get telemetryConsentBody;

  /// No description provided for @usageAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Usage analytics'**
  String get usageAnalyticsTitle;

  /// No description provided for @usageAnalyticsDescription.
  ///
  /// In en, this message translates to:
  /// **'Share stable lesson IDs, session types, and aggregate correctness. Answer text and card sequences are never sent.'**
  String get usageAnalyticsDescription;

  /// No description provided for @crashReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Crash reports'**
  String get crashReportsTitle;

  /// No description provided for @crashReportsDescription.
  ///
  /// In en, this message translates to:
  /// **'Share fatal technical diagnostics so crashes can be fixed. No gameplay content or personal profile is attached.'**
  String get crashReportsDescription;

  /// No description provided for @telemetryOptionalNote.
  ///
  /// In en, this message translates to:
  /// **'Both choices are optional. Saying no does not limit the app, and you can change them in Progress.'**
  String get telemetryOptionalNote;

  /// No description provided for @saveAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Save and continue'**
  String get saveAndContinue;

  /// No description provided for @recommendedStart.
  ///
  /// In en, this message translates to:
  /// **'Start here'**
  String get recommendedStart;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minutesShort(int minutes);

  /// No description provided for @mastered.
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get mastered;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get inProgress;

  /// No description provided for @freeLabel.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get freeLabel;

  /// No description provided for @proLabel.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get proLabel;

  /// No description provided for @startLesson.
  ///
  /// In en, this message translates to:
  /// **'Start lesson'**
  String get startLesson;

  /// No description provided for @continueLesson.
  ///
  /// In en, this message translates to:
  /// **'Continue lesson'**
  String get continueLesson;

  /// No description provided for @lockedLesson.
  ///
  /// In en, this message translates to:
  /// **'Complete the previous lesson to unlock'**
  String get lockedLesson;

  /// No description provided for @lessonComplete.
  ///
  /// In en, this message translates to:
  /// **'Lesson complete'**
  String get lessonComplete;

  /// No description provided for @lessonCompleteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Accuracy unlocked the next node. Keep reviewing to retain the skill.'**
  String get lessonCompleteSubtitle;

  /// No description provided for @lessonNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'Lesson finished — review required'**
  String get lessonNeedsReview;

  /// No description provided for @lessonNeedsReviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reach at least 80% accuracy to unlock the next lesson.'**
  String get lessonNeedsReviewSubtitle;

  /// No description provided for @retryLesson.
  ///
  /// In en, this message translates to:
  /// **'Review and try again'**
  String get retryLesson;

  /// No description provided for @lessonResult.
  ///
  /// In en, this message translates to:
  /// **'{correct} of {total} correct'**
  String lessonResult(int correct, int total);

  /// No description provided for @correctAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get correctAnswer;

  /// No description provided for @incorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Not quite'**
  String get incorrectAnswer;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @backToPath.
  ///
  /// In en, this message translates to:
  /// **'Back to path'**
  String get backToPath;

  /// No description provided for @quickReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Review'**
  String get quickReviewTitle;

  /// No description provided for @quickReviewReadyLater.
  ///
  /// In en, this message translates to:
  /// **'Weak and due exercises will appear here.'**
  String get quickReviewReadyLater;

  /// No description provided for @quickReviewDue.
  ///
  /// In en, this message translates to:
  /// **'{count} exercises ready · about 3–5 min'**
  String quickReviewDue(int count);

  /// No description provided for @quickReviewProgress.
  ///
  /// In en, this message translates to:
  /// **'Review {current} of {total}'**
  String quickReviewProgress(int current, int total);

  /// No description provided for @quickReviewEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to review yet'**
  String get quickReviewEmptyTitle;

  /// No description provided for @quickReviewEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Complete a few lesson exercises, then return for a focused review.'**
  String get quickReviewEmptyBody;

  /// No description provided for @quickReviewComplete.
  ///
  /// In en, this message translates to:
  /// **'Review complete'**
  String get quickReviewComplete;

  /// No description provided for @quickReviewResult.
  ///
  /// In en, this message translates to:
  /// **'{correct} of {total} correct. Your next review dates were updated.'**
  String quickReviewResult(int correct, int total);

  /// No description provided for @countdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Running count'**
  String get countdownTitle;

  /// No description provided for @countdownSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep a Hi-Lo count as each card is revealed.'**
  String get countdownSubtitle;

  /// No description provided for @countDrillIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Before your first count'**
  String get countDrillIntroTitle;

  /// No description provided for @countDrillIntroBody.
  ///
  /// In en, this message translates to:
  /// **'Hi-Lo tracks exposed cards in the current shoe. Start at 0 and keep one running total.'**
  String get countDrillIntroBody;

  /// No description provided for @countDrillIntroLowCards.
  ///
  /// In en, this message translates to:
  /// **'2–6  →  +1'**
  String get countDrillIntroLowCards;

  /// No description provided for @countDrillIntroNeutralCards.
  ///
  /// In en, this message translates to:
  /// **'7–9  →  0'**
  String get countDrillIntroNeutralCards;

  /// No description provided for @countDrillIntroHighCards.
  ///
  /// In en, this message translates to:
  /// **'10, J, Q, K, A  →  −1'**
  String get countDrillIntroHighCards;

  /// No description provided for @countDrillIntroDeckNote.
  ///
  /// In en, this message translates to:
  /// **'All 52 cards of one complete deck sum to 0 in Hi-Lo. In a multi-deck shoe, any 52 cards are only a mixed segment: keep the running count until the shoe is shuffled.'**
  String get countDrillIntroDeckNote;

  /// No description provided for @countDrillIntroKnown.
  ///
  /// In en, this message translates to:
  /// **'I know these rules — don\'t show this again'**
  String get countDrillIntroKnown;

  /// No description provided for @countDrillIntroContinue.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get countDrillIntroContinue;

  /// No description provided for @startDrill.
  ///
  /// In en, this message translates to:
  /// **'Start one-deck drill'**
  String get startDrill;

  /// No description provided for @nextCard.
  ///
  /// In en, this message translates to:
  /// **'Reveal next card'**
  String get nextCard;

  /// No description provided for @submitCount.
  ///
  /// In en, this message translates to:
  /// **'Check count'**
  String get submitCount;

  /// No description provided for @yourCount.
  ///
  /// In en, this message translates to:
  /// **'Your count'**
  String get yourCount;

  /// No description provided for @cardsSeen.
  ///
  /// In en, this message translates to:
  /// **'{count} cards seen'**
  String cardsSeen(int count);

  /// No description provided for @checkpoint.
  ///
  /// In en, this message translates to:
  /// **'Checkpoint'**
  String get checkpoint;

  /// No description provided for @countCorrect.
  ///
  /// In en, this message translates to:
  /// **'Count is correct. Keep going.'**
  String get countCorrect;

  /// No description provided for @countIncorrect.
  ///
  /// In en, this message translates to:
  /// **'The exact count was {count}.'**
  String countIncorrect(int count);

  /// No description provided for @drillComplete.
  ///
  /// In en, this message translates to:
  /// **'Deck complete'**
  String get drillComplete;

  /// No description provided for @drillCompleteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A complete Hi-Lo deck always returns to zero.'**
  String get drillCompleteSubtitle;

  /// No description provided for @restartDrill.
  ///
  /// In en, this message translates to:
  /// **'Run another deck'**
  String get restartDrill;

  /// No description provided for @revealInstruction.
  ///
  /// In en, this message translates to:
  /// **'Memorize the count, then reveal the next card.'**
  String get revealInstruction;

  /// No description provided for @adjustCountInstruction.
  ///
  /// In en, this message translates to:
  /// **'Set the running count you have in mind.'**
  String get adjustCountInstruction;

  /// No description provided for @newRound.
  ///
  /// In en, this message translates to:
  /// **'New round'**
  String get newRound;

  /// No description provided for @hit.
  ///
  /// In en, this message translates to:
  /// **'Hit'**
  String get hit;

  /// No description provided for @stand.
  ///
  /// In en, this message translates to:
  /// **'Stand'**
  String get stand;

  /// No description provided for @doubleAction.
  ///
  /// In en, this message translates to:
  /// **'Double'**
  String get doubleAction;

  /// No description provided for @split.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get split;

  /// No description provided for @surrender.
  ///
  /// In en, this message translates to:
  /// **'Surrender'**
  String get surrender;

  /// No description provided for @dealer.
  ///
  /// In en, this message translates to:
  /// **'Dealer'**
  String get dealer;

  /// No description provided for @seat.
  ///
  /// In en, this message translates to:
  /// **'Seat {number}'**
  String seat(int number);

  /// No description provided for @human.
  ///
  /// In en, this message translates to:
  /// **'Human'**
  String get human;

  /// No description provided for @bot.
  ///
  /// In en, this message translates to:
  /// **'Bot'**
  String get bot;

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get empty;

  /// No description provided for @configureSeats.
  ///
  /// In en, this message translates to:
  /// **'Configure seats'**
  String get configureSeats;

  /// No description provided for @configureSeatsHint.
  ///
  /// In en, this message translates to:
  /// **'Choose Human, Bot, or Empty for each seat. Changes during a round apply to the next round. Keep at least one Human.'**
  String get configureSeatsHint;

  /// No description provided for @seatChangesPending.
  ///
  /// In en, this message translates to:
  /// **'Seat changes will apply to the next round.'**
  String get seatChangesPending;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @currentCount.
  ///
  /// In en, this message translates to:
  /// **'Running count: {count}'**
  String currentCount(int count);

  /// No description provided for @shoeStatus.
  ///
  /// In en, this message translates to:
  /// **'{dealt} / {total} cards dealt'**
  String shoeStatus(int dealt, int total);

  /// No description provided for @turnPrompt.
  ///
  /// In en, this message translates to:
  /// **'Choose the best action'**
  String get turnPrompt;

  /// No description provided for @roundComplete.
  ///
  /// In en, this message translates to:
  /// **'Round complete'**
  String get roundComplete;

  /// No description provided for @startFirstRound.
  ///
  /// In en, this message translates to:
  /// **'Deal the first round'**
  String get startFirstRound;

  /// No description provided for @guidedMode.
  ///
  /// In en, this message translates to:
  /// **'GUIDED TABLE'**
  String get guidedMode;

  /// No description provided for @practiceMode.
  ///
  /// In en, this message translates to:
  /// **'PRACTICE TABLE'**
  String get practiceMode;

  /// No description provided for @guidedModeName.
  ///
  /// In en, this message translates to:
  /// **'Guided'**
  String get guidedModeName;

  /// No description provided for @practiceModeName.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get practiceModeName;

  /// No description provided for @tableRoundProgress.
  ///
  /// In en, this message translates to:
  /// **'Round {completed} / {total}'**
  String tableRoundProgress(int completed, int total);

  /// No description provided for @recommendedAction.
  ///
  /// In en, this message translates to:
  /// **'Recommended: {action}'**
  String recommendedAction(String action);

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @tableCountPrompt.
  ///
  /// In en, this message translates to:
  /// **'What is the running count?'**
  String get tableCountPrompt;

  /// No description provided for @tableSessionComplete.
  ///
  /// In en, this message translates to:
  /// **'Five-round session complete'**
  String get tableSessionComplete;

  /// No description provided for @strategyAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Strategy {percent}%'**
  String strategyAccuracy(int percent);

  /// No description provided for @countAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Count {percent}%'**
  String countAccuracy(int percent);

  /// No description provided for @startAnotherSession.
  ///
  /// In en, this message translates to:
  /// **'Another session'**
  String get startAnotherSession;

  /// No description provided for @strategyReasonSplitPair.
  ///
  /// In en, this message translates to:
  /// **'Splitting this pair creates the stronger long-run play.'**
  String get strategyReasonSplitPair;

  /// No description provided for @strategyReasonStandPair.
  ///
  /// In en, this message translates to:
  /// **'This pair should stay together against this dealer card.'**
  String get strategyReasonStandPair;

  /// No description provided for @strategyReasonDoublePair.
  ///
  /// In en, this message translates to:
  /// **'Play these cards as a hard ten and double against this dealer card.'**
  String get strategyReasonDoublePair;

  /// No description provided for @strategyReasonHitPair.
  ///
  /// In en, this message translates to:
  /// **'This pair is stronger when played as a regular hand.'**
  String get strategyReasonHitPair;

  /// No description provided for @strategyReasonSurrenderHard.
  ///
  /// In en, this message translates to:
  /// **'Late surrender loses less than playing this weak hard total.'**
  String get strategyReasonSurrenderHard;

  /// No description provided for @strategyReasonDoubleSoft.
  ///
  /// In en, this message translates to:
  /// **'The soft total has enough upside to double against this dealer card.'**
  String get strategyReasonDoubleSoft;

  /// No description provided for @strategyReasonStandSoft.
  ///
  /// In en, this message translates to:
  /// **'This soft total is already strong enough to stand.'**
  String get strategyReasonStandSoft;

  /// No description provided for @strategyReasonHitSoft.
  ///
  /// In en, this message translates to:
  /// **'The ace protects the hand while another card can improve it.'**
  String get strategyReasonHitSoft;

  /// No description provided for @strategyReasonDoubleHard.
  ///
  /// In en, this message translates to:
  /// **'This hard total has an advantage against the dealer\'s up-card.'**
  String get strategyReasonDoubleHard;

  /// No description provided for @strategyReasonStandHard.
  ///
  /// In en, this message translates to:
  /// **'The dealer is more likely to break; avoid taking another card.'**
  String get strategyReasonStandHard;

  /// No description provided for @strategyReasonHitHard.
  ///
  /// In en, this message translates to:
  /// **'Standing is too weak here; take another card.'**
  String get strategyReasonHitHard;

  /// No description provided for @strategyReasonFallback.
  ///
  /// In en, this message translates to:
  /// **'The preferred move is unavailable, so use the safest legal fallback.'**
  String get strategyReasonFallback;

  /// No description provided for @standardRulesName.
  ///
  /// In en, this message translates to:
  /// **'Standard six-deck · S17 · DAS · late surrender · 3:2'**
  String get standardRulesName;

  /// No description provided for @practiceUnits.
  ///
  /// In en, this message translates to:
  /// **'Practice unit'**
  String get practiceUnits;

  /// No description provided for @dealingCards.
  ///
  /// In en, this message translates to:
  /// **'Dealing cards...'**
  String get dealingCards;

  /// No description provided for @dealerTurn.
  ///
  /// In en, this message translates to:
  /// **'Dealer is resolving the round.'**
  String get dealerTurn;

  /// No description provided for @hiddenCard.
  ///
  /// In en, this message translates to:
  /// **'Hidden card'**
  String get hiddenCard;

  /// No description provided for @handTotal.
  ///
  /// In en, this message translates to:
  /// **'Total {total}'**
  String handTotal(int total);

  /// No description provided for @resultUnits.
  ///
  /// In en, this message translates to:
  /// **'{outcome} · {units} units'**
  String resultUnits(String outcome, String units);

  /// No description provided for @outcomeBlackjack.
  ///
  /// In en, this message translates to:
  /// **'Blackjack'**
  String get outcomeBlackjack;

  /// No description provided for @outcomeWin.
  ///
  /// In en, this message translates to:
  /// **'Win'**
  String get outcomeWin;

  /// No description provided for @outcomePush.
  ///
  /// In en, this message translates to:
  /// **'Push'**
  String get outcomePush;

  /// No description provided for @outcomeLoss.
  ///
  /// In en, this message translates to:
  /// **'Loss'**
  String get outcomeLoss;

  /// No description provided for @outcomeSurrender.
  ///
  /// In en, this message translates to:
  /// **'Surrender'**
  String get outcomeSurrender;

  /// No description provided for @reshuffled.
  ///
  /// In en, this message translates to:
  /// **'The shoe was reshuffled at 75% penetration.'**
  String get reshuffled;

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'Your progress'**
  String get progressTitle;

  /// No description provided for @progressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Motivation and mastery are measured separately.'**
  String get progressSubtitle;

  /// No description provided for @xpLabel.
  ///
  /// In en, this message translates to:
  /// **'XP'**
  String get xpLabel;

  /// No description provided for @streakLabel.
  ///
  /// In en, this message translates to:
  /// **'day streak'**
  String get streakLabel;

  /// No description provided for @masteryLabel.
  ///
  /// In en, this message translates to:
  /// **'Lesson accuracy'**
  String get masteryLabel;

  /// No description provided for @experienceSettingTitle.
  ///
  /// In en, this message translates to:
  /// **'Experience level'**
  String get experienceSettingTitle;

  /// No description provided for @experienceSettingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change your recommended starting point without deleting progress.'**
  String get experienceSettingSubtitle;

  /// No description provided for @lessonsCompleted.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} lessons completed'**
  String lessonsCompleted(int completed, int total);

  /// No description provided for @privacyChoicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy choices'**
  String get privacyChoicesTitle;

  /// No description provided for @privacyChoicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional collection stays off unless you enable it.'**
  String get privacyChoicesSubtitle;

  /// No description provided for @privacyNote.
  ///
  /// In en, this message translates to:
  /// **'Telemetry follows your separate opt-in choices. Answer text, card sequences, and personal data are not collected.'**
  String get privacyNote;

  /// No description provided for @educationDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Training simulation only. Skill does not guarantee gambling profit.'**
  String get educationDisclaimer;

  /// No description provided for @proComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Pro course coming later'**
  String get proComingSoon;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @resetProgress.
  ///
  /// In en, this message translates to:
  /// **'Reset progress'**
  String get resetProgress;

  /// No description provided for @resetConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Reset all lesson progress and XP?'**
  String get resetConfirmation;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @loadFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'The training content could not be loaded'**
  String get loadFailureTitle;

  /// No description provided for @loadFailureBody.
  ///
  /// In en, this message translates to:
  /// **'Restart the app. If the problem continues, reinstall the app.'**
  String get loadFailureBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
