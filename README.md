# Blackjack Advantage Trainer

An English-first Flutter prototype for learning blackjack basic strategy and the
Hi-Lo running count. It is an offline training simulation, not a live casino
assistant and not a real-money game.

## Start here

These documents are the canonical project context for contributors, reviewers,
and Codex. Read them before changing the product or code:

- [Product context and durable decisions](docs/PROJECT_CONTEXT.md)
- [Architecture and implementation status](docs/ARCHITECTURE.md)
- [Development environment and commands](docs/DEVELOPMENT_SETUP.md)

## Implemented vertical slice

- A six-node learning path with 54 original exercises.
- Resume-safe lesson sessions, deterministic answer order, 80% completion threshold, XP, streak, and lesson accuracy.
- A one-deck Hi-Lo countdown drill with checkpoints every eight exposed cards.
- A six-deck, five-seat blackjack table with Guided and Practice modes,
  strategy feedback, per-round count checks, and five-round summaries. Each
  seat can be Human, Bot, or Empty; one person can occupy all five seats.
- Standard reference-tested profile: 6D, S17, DAS, late surrender, dealer peek, 3:2,
  and 75% penetration.
- Pure-Dart hand evaluation, shoe, counting, basic-strategy, and round engines.
- English ARB UI localization and versioned English lesson/glossary assets.
- Spaced-review state plus a Quick Review session of up to ten due or weak exercises.
- Firebase Analytics and Crashlytics behind store- and vendor-independent
  gateways, with separate consent choices and collection disabled by default.
- Unit and widget tests for the critical mathematical and learning behavior.

The rest of the 76-lesson commercial plan, real in-app purchases, additional
validated rule profiles, Russian content, and store submission are intentionally
later stages. See the
[closed-beta release checklist](docs/BETA_RELEASE.md).

## Privacy

The app stores learning progress in local app storage and has no accounts, ads,
server gameplay history, or sensitive device permissions. Android and iOS builds
offer separate optional usage-analytics and crash-report choices; both are off
by default and never include answer text or card sequences. See the
full [Privacy Policy](PRIVACY_POLICY.md).

Before an external beta or store release, publish the current policy at a
publicly accessible URL and verify that the
[App Store privacy details](https://developer.apple.com/app-store/app-privacy-details/)
and [Google Play Data safety form](https://support.google.com/googleplay/android-developer/answer/10787469)
match the exact build and every included third-party SDK.

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

- `lib/domain/blackjack_engine/` — cards, hands, shoe, Hi-Lo, strategy, and round engine.
- `lib/domain/learning/` — content, progress, mastery, and review policies.
- `assets/content/en/` — versioned course content and terminology glossary.
- `lib/l10n/app_en.arb` — localizable interface strings.
- `lib/presentation/` — learning path, lessons, drill, table, and progress UI.
- `test/` — mathematical, content, persistence-model, and UI checks.

## Run locally

Requirements:

1. Flutter stable.
2. Android Studio plus Android SDK for Android builds.
3. Full Xcode for iOS builds. The current project uses Swift Package Manager;
   CocoaPods remains a compatibility fallback.

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

The table switches to landscape while open and returns the app to portrait when
closed.

### Android UI review in a standalone emulator

For manual scrolling and layout checks, use the separate Android Emulator window
instead of Android Studio's embedded device view. The prepared Pixel AVD is
`blackjack_pixel_7_api_36`.

Start the emulator from any terminal:

```sh
flutter emulators --launch blackjack_pixel_7_api_36
```

Wait until the Android home screen is fully loaded. Then open a second terminal
and run the app from the project root (the directory containing `pubspec.yaml`):

```sh
cd /Users/nerdysnake6/Documents/BlackjackAdvantageTrainer
flutter devices
flutter run -d emulator-5554
```

The device ID can change, so use the ID printed by `flutter devices` when it is
different from `emulator-5554`. `flutter run` must be run from the project root;
the emulator itself can be launched from any directory. If Android Studio shows
`Missing system image`, point its Android SDK location to
`/opt/homebrew/share/android-commandlinetools` or install the API 36 Google APIs
ARM64 image through SDK Manager.

### Android build from GitHub Actions

The `Build Android APK` workflow runs automatically for changes to `main` and
for pull requests, and it can also be started manually from the repository's
Actions tab. It checks formatting, runs analysis and all tests, then builds a
debug APK.

After a successful run, open its `Artifacts` section and download the archive
named `blackjack-advantage-trainer-android-debug-<commit SHA>`. GitHub keeps the
artifact for 14 days. The APK uses debug signing and is intended only for
development and testing, not for Google Play distribution.

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
