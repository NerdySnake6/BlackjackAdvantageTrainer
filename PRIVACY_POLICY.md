# Privacy Policy for Blackjack Advantage Trainer

Effective date: August 2, 2026

Last updated: August 2, 2026

Blackjack Advantage Trainer is an educational blackjack training simulation. This policy describes the privacy practices of the current prototype identified as `com.blackjackadvantage.trainer` on Android and iOS.

## Summary

The app works without an account. Learning progress is stored locally on the user's device. A beta build may offer two separate, optional choices: anonymous usage analytics and technical crash reports. Both are off by default, declining either choice does not restrict the app, and the choices can be changed later in Progress.

## Information stored on the device

The app stores the following information locally so that learning can resume between sessions:

- the selected experience level;
- lesson scores and unfinished lesson positions;
- XP, streak length, and the last activity date;
- whether introductory guidance has already been acknowledged;
- spaced-review attempts, successful-review streaks, and next review dates;
- the selected analytics and crash-reporting consent versions.

This information is stored in the operating system's local application storage using Flutter's `shared_preferences` plugin. The current app does not ask for a name, email address, phone number, account credentials, payment information, or other direct identifiers.

Blackjack rounds and count-drill activity may be held temporarily in memory while the app is running. The app does not upload answer text or card sequences and does not maintain a remote gameplay history.

## Optional usage analytics

If the user enables usage analytics in a Firebase-enabled beta build, the app may send stable lesson or exercise IDs, the selected experience level, training-session type, whether a decision or count check was correct, and aggregate session results. It does not send answer wording, card sequences, a name, an email address, or a user-authored profile.

Google Analytics for Firebase may also process automatically generated app-instance identifiers and technical information about the app, device, operating system, approximate region, and event timing. The project uses this information to measure completion, return behavior, and feature reliability. Collection remains disabled unless the user opts in.

## Optional crash reports

If the user separately enables crash reports in a Firebase-enabled beta build, Firebase Crashlytics may receive stack traces, crash state, app and operating-system versions, device model, and related technical diagnostics. The app does not intentionally attach gameplay content, answer text, card sequences, contact information, or a custom user identifier. Crash-report collection remains disabled unless the user opts in.

## Data sharing and tracking

The app:

- does not operate a developer-controlled server or cloud database;
- does not include advertising or an advertising identifier SDK;
- does not track users across apps or websites;
- does not sell or share personal data;
- does not access the camera, microphone, location, contacts, photos, or a live casino table;
- does not provide user accounts, real-money wagering, or production in-app purchases.

Local development builds use no-op telemetry gateways unless Firebase has been explicitly configured. Store purchases, accounts, advertising, and server-side gameplay storage are not part of the beta.

## Platform services and backups

Apple, Google, the device manufacturer, or the operating system may independently process information related to downloading the app, device diagnostics, store activity, or device backups under their own terms and privacy policies. Depending on the user's device and backup settings, locally stored app progress may be included in an operating-system backup. Blackjack Advantage Trainer does not control those platform services and does not receive a copy of that backup data.

## Retention and deletion

Local progress remains on the device until the user resets progress inside the app, clears the app's storage, or uninstalls the app. Copies included in an operating-system backup are retained and deleted according to the user's Apple or Google backup settings and the applicable platform policy.

Disabling analytics or crash reports stops future collection through the app. Data already processed by Firebase follows Google's configured retention and deletion controls. Because the app has no account or custom user identifier, the developer may not be able to associate a particular remote diagnostic record with an individual request. Local progress can be removed from inside the app or by uninstalling it.

## Security

Local progress is protected by the security controls of the user's device and operating system. Users should keep their device software and access controls up to date. No method of storage can be guaranteed to be completely secure.

## Children

The app is an educational simulation about blackjack strategy and is not designed or marketed for children. The current prototype does not knowingly collect personal data from children or adults.

## Changes to this policy

This policy may be updated when the app's features or data practices change. The effective date and last-updated date at the top of this document will be revised when a material change is made.

## Contact

For privacy questions about the current repository or prototype, contact the project maintainer through the [NerdySnake6 GitHub profile](https://github.com/NerdySnake6). An active public support contact and a publicly accessible copy of this policy must be configured before public app-store distribution.
