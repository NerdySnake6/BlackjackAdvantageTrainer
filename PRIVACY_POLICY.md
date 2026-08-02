# Privacy Policy for Blackjack Advantage Trainer

Effective date: August 2, 2026

Last updated: August 2, 2026

Blackjack Advantage Trainer is an educational blackjack training simulation. This policy describes the privacy practices of the current prototype identified as `com.blackjackadvantage.trainer` on Android and iOS.

## Summary

The current prototype works without an account and does not send personal data or training activity to the developer or to third-party analytics, advertising, or crash-reporting services. Learning progress is stored locally on the user's device.

## Information stored on the device

The app stores the following information locally so that learning can resume between sessions:

- the selected experience level;
- lesson scores and unfinished lesson positions;
- XP, streak length, and the last activity date;
- whether introductory guidance has already been acknowledged.

This information is stored in the operating system's local application storage using Flutter's `shared_preferences` plugin. The current app does not ask for a name, email address, phone number, account credentials, payment information, or other direct identifiers.

Blackjack rounds and count-drill activity may be held temporarily in memory while the app is running. The current prototype does not upload this activity or maintain a remote session history.

## Data collection, sharing, and tracking

The current prototype:

- does not operate a developer-controlled server or cloud database;
- does not include advertising or an advertising identifier SDK;
- does not include production analytics or crash-reporting SDKs;
- does not track users across apps or websites;
- does not sell or share personal data;
- does not access the camera, microphone, location, contacts, photos, or a live casino table;
- does not provide user accounts, real-money wagering, or production in-app purchases.

The source code contains interfaces for possible future analytics and store purchases, but the current implementations do not transmit data and do not complete purchases. If a later version enables analytics, crash reporting, purchases, accounts, or another external service, this policy and the relevant app-store disclosures must be updated before that version is distributed.

## Platform services and backups

Apple, Google, the device manufacturer, or the operating system may independently process information related to downloading the app, device diagnostics, store activity, or device backups under their own terms and privacy policies. Depending on the user's device and backup settings, locally stored app progress may be included in an operating-system backup. Blackjack Advantage Trainer does not control those platform services and does not receive a copy of that backup data.

## Retention and deletion

Local progress remains on the device until the user resets progress inside the app, clears the app's storage, or uninstalls the app. Copies included in an operating-system backup are retained and deleted according to the user's Apple or Google backup settings and the applicable platform policy.

Because the current prototype does not keep user data on a developer-controlled server, the developer has no remote profile or training history to retrieve or delete.

## Security

Local progress is protected by the security controls of the user's device and operating system. Users should keep their device software and access controls up to date. No method of storage can be guaranteed to be completely secure.

## Children

The app is an educational simulation about blackjack strategy and is not designed or marketed for children. The current prototype does not knowingly collect personal data from children or adults.

## Changes to this policy

This policy may be updated when the app's features or data practices change. The effective date and last-updated date at the top of this document will be revised when a material change is made.

## Contact

For privacy questions about the current repository or prototype, contact the project maintainer through the [NerdySnake6 GitHub profile](https://github.com/NerdySnake6). An active public support contact and a publicly accessible copy of this policy must be configured before public app-store distribution.
