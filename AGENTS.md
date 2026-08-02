# Repository instructions

## Required context

Before any work in this repository, read all of the following files:

1. [README.md](README.md)
2. [docs/PROJECT_CONTEXT.md](docs/PROJECT_CONTEXT.md)
3. [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
4. [docs/DEVELOPMENT_SETUP.md](docs/DEVELOPMENT_SETUP.md)

Treat these documents as the canonical project context for both people and coding agents. Keep them consistent with any approved product, architecture, or toolchain change.

## Product and domain invariants

- Keep `lib/domain/` pure Dart. It must not import Flutter, platform plugins, widgets, or presentation code.
- Put every user-visible string through the localization system. Do not add hard-coded UI copy.
- Add a blackjack rule profile only after its strategy and math have been checked against an independent solver or reference and protected by automated tests.
- Do not add real-money wagering, casino integrations or links, external live-table input, camera or microphone card recognition, real-time overlays, or features intended to evade casino observation.
- Never change an existing stable `lessonId` or `skillId`. These identifiers are locale-independent persistence keys.
- Preserve the existing architecture and dependency direction unless an explicitly approved change requires otherwise.

## Verification

Before committing, run the checks appropriate to the change:

1. `dart format` on changed Dart files.
2. `flutter analyze`.
3. `flutter test`.
4. A platform build proportional to risk: Android, iOS, or both when platform configuration or shared runtime behavior changes.

Mathematical changes require focused deterministic tests and comparison with an independent reference in addition to the standard checks.

## Repository hygiene

Do not commit generated build output, local IDE or agent state, machine-specific SDK configuration, or secrets. In particular, never commit:

- `build/`
- `.dart_tool/`
- `.idea/`
- `.serena/`
- `local.properties`
- API keys, signing keys, provisioning profiles, credentials, tokens, or secret configuration
