# Blackjack Advantage Trainer

An English-first Flutter prototype for learning blackjack basic strategy and the
Hi-Lo running count. It is an offline training simulation, not a live casino
assistant and not a real-money game.

## Implemented vertical slice

- A six-node learning path with 52 original exercises.
- Resume-safe lesson sessions, 80% completion threshold, XP, streak, and mastery.
- A one-deck Hi-Lo countdown drill with checkpoints every eight exposed cards.
- A six-deck, five-seat blackjack table. Each seat can be Human, Bot, or Empty;
  one person can occupy all five seats.
- Standard validated profile: 6D, S17, DAS, late surrender, dealer peek, 3:2,
  and 75% penetration.
- Pure-Dart hand evaluation, shoe, counting, basic-strategy, and round engines.
- English ARB UI localization and versioned English lesson/glossary assets.
- Store-independent purchase interfaces and disabled-by-default analytics boundary.
- Unit and widget tests for the critical mathematical and learning behavior.

The rest of the 76-lesson commercial plan, real in-app purchases, Firebase,
additional validated rule profiles, Russian content, and store submission are
intentionally later stages.

## Architecture

```text
Presentation widgets
        ↓
ChangeNotifier view models
        ↓
Repositories and gateways
        ↓
Pure Dart blackjack + learning domain
```

The blackjack domain does not import Flutter. Randomness is injectable, so tests
use deterministic shoes while production uses `Random.secure()`.

Important locations:

- `lib/domain/blackjack/` — cards, hands, shoe, Hi-Lo, strategy, and round engine.
- `lib/domain/learning/` — content, progress, mastery, and review policies.
- `assets/content/en/` — versioned course content and terminology glossary.
- `lib/l10n/app_en.arb` — localizable interface strings.
- `lib/presentation/` — learning path, lessons, drill, table, and progress UI.
- `test/` — mathematical, content, persistence-model, and UI checks.

## Run locally

Requirements:

1. Flutter stable.
2. Android Studio plus Android SDK for Android builds.
3. Full Xcode plus CocoaPods for iOS builds.

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

The table switches to landscape while open and returns the app to portrait when
closed.

## Adding a language

1. Copy `lib/l10n/app_en.arb` to a locale-specific ARB file such as
   `app_ru.arb` and translate every value without changing its key.
2. Add a complete locale directory under `assets/content/<locale>/` with the
   same stable lesson and skill IDs.
3. Have a fluent blackjack reviewer approve the terminology and mathematical
   meaning.
4. Add locale tests for long text, plurals, layouts, and unchanged progress.
5. Do not advertise a locale until its UI, course, disclaimers, purchases, store
   listing, and screenshots are complete.

## Mathematical provenance

The prototype targets only `standard_6d_s17_das_ls_peek_3to2`. Its decisions
must continue to be tested against independent references before release:

- [Wizard of Odds basic-strategy calculator](https://wizardofodds.com/games/blackjack/strategy/calculator/)
- [Wizard of Odds Hi-Lo introduction](https://wizardofodds.com/games/blackjack/card-counting/high-low/)
- [Blackjack Apprenticeship S17 chart](https://www.blackjackapprenticeship.com/wp-content/uploads/2024/09/S17-Basic-Strategy.pdf)

Do not copy lesson wording, charts, or proprietary drills. New rule profiles must
ship only with independently validated strategy data and automated reference
tests.

## First developer study sprint

Target: understand enough Dart and Flutter to explain and safely modify one
lesson without touching the blackjack engine.

1. Read the [Dart language tour](https://dart.dev/language), focusing on enums,
   classes, null safety, collections, and async functions.
2. Complete the [Flutter first-app codelab](https://docs.flutter.dev/get-started/codelab).
3. Read `lib/domain/learning/models.dart` and trace how
   `assets/content/en/lessons.json` becomes a lesson screen.
4. Add one new exercise to `card-values`, run `flutter analyze` and
   `flutter test`, then explain why stable `lessonId` and `skillId` values must
   not be translated.

Completion criterion: all checks pass and the new exercise appears after
restarting the app.

## Product safety boundary

The app must not accept an external table state, scan real cards, provide an
overlay, connect to a casino, or claim guaranteed profit. App Store guideline
5.3.4 explicitly disallows illegal gambling aids, including card counters, so
the product remains a self-contained educational simulation and still requires
careful review before submission.
