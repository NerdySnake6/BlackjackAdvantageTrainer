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
  /// **'6-lesson validation build'**
  String get prototypeBuild;

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
  /// **'Accuracy unlocks the next node. Mastery still requires repetition.'**
  String get lessonCompleteSubtitle;

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
  /// **'Tap a seat to cycle Human → Bot → Empty. Keep at least one Human.'**
  String get configureSeatsHint;

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
  /// **'Path mastery'**
  String get masteryLabel;

  /// No description provided for @lessonsCompleted.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} prototype lessons completed'**
  String lessonsCompleted(int completed, int total);

  /// No description provided for @privacyNote.
  ///
  /// In en, this message translates to:
  /// **'Analytics and crash reporting are off in this prototype.'**
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
  /// **'Reset prototype progress'**
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
  /// **'Restart the app. If the problem continues, reinstall this prototype.'**
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
