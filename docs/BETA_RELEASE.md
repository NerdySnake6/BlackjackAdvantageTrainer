# Подготовка закрытой beta

Документ фиксирует воспроизводимый выпуск beta для 30–50 тестировщиков. Внешняя раздача не начинается, пока математические тесты, обе платформенные сборки и проверки на реальных устройствах не завершены.

## Границы beta

- Android и iOS, английский язык.
- Уроки, one-deck Drill, Quick Review и пятираундовый Table в режимах Guided/Practice.
- Один профиль `standard_6d_s17_das_ls_peek_3to2`.
- Без рекламы, IAP, аккаунтов, реальных денег, новых rule profiles, True Count и Exam.

## Локальный release gate

Полная basic-strategy fixture для standard profile сверена с Wizard of Odds и
независимо подтверждена публичной S17-таблицей Blackjack Apprenticeship
2026-09-02. Обе ссылки и результат проверки хранятся в
`test/fixtures/standard_strategy_s17_das_ls.json`. Перед внешней beta остаётся
ручной smoke-test на реальном Android; перед платными математическими
заявлениями также нужна независимая проверка blackjack-специалистом.

```sh
dart format <changed Dart files>
flutter analyze
flutter test
flutter build apk --release
flutter build ios --release --no-codesign
git diff --check
```

Дополнительно пройти приложение на одном реальном Android и одном реальном iPhone. Проверить onboarding и отказ от обоих consent, первый урок, resume, Drill, Quick Review, пять раундов Guided и Practice, изменение experience level и consent в Progress.

## Firebase: конфигурация и оставшаяся проверка

Проект `blackjack-advantage-trainer`, Android/iOS приложения с ID `com.blackjackadvantage.trainer`, FlutterFire platform configuration и Firebase Analytics/Crashlytics adapters настроены. Native defaults остаются `false`; включение выполняется только после сохранённого opt-in. Сгенерированные platform IDs не являются секретами и хранятся в репозитории, но service-account keys, CLI tokens и другие credentials коммитить нельзя.

Перед beta остаётся проверить в Firebase Console связь с Google Analytics и на реальных устройствах подтвердить, что до согласия нет analytics/crash upload, а после согласия отправляются только разрешённые события. Для Crashlytics нужен контролируемый тестовый сбой в отдельной debug/beta сборке; оставлять кнопку или автоматический сбой в production нельзя.

Разрешённые custom-параметры: stable IDs, experience level, session type, correctness и агрегированные итоги. Запрещены тексты ответов, card sequences, email, имя, произвольный user ID и другие персональные данные.

## Android: Firebase App Distribution

После настройки Firebase и сборки подписанного beta APK:

```sh
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app <FIREBASE_ANDROID_APP_ID> \
  --group-alias closed-beta \
  --release-notes-file docs/beta/android-release-notes.txt
```

Не коммитить список email тестировщиков. Группа должна включать минимум по 10 Beginner, Basics и Experienced.

## iOS: TestFlight

Нужны Apple Developer membership, signing, App Store Connect app record и публичный privacy URL. Первый внешний build проходит TestFlight App Review.

Review note:

> Blackjack Advantage Trainer is a self-contained educational simulation. All cards and decisions are generated inside the app. It does not use the camera, microphone, external table input, overlays, casino links, or real-money wagering. Guided and Practice modes teach basic strategy and a running count only within the simulated shoe. The app is not intended for use during live casino play.

Если review отклоняет приложение по card-counting policy, функции не скрываются: подаётся честная апелляция, Android beta продолжается отдельно.

## Privacy и store disclosures

Канонический текст находится в [PRIVACY_POLICY.md](../PRIVACY_POLICY.md), а статическая страница — в [docs/privacy/index.html](privacy/index.html). Workflow GitHub Pages требует один раз включить Pages с источником GitHub Actions в настройках репозитория.

Перед раздачей Firebase-enabled build синхронизировать:

- App Store Privacy: usage data/app interactions и diagnostics/crash data, только при opt-in; identifiers/technical metadata указать согласно фактической конфигурации Firebase;
- Google Play Data Safety: analytics и diagnostics, optional collection, no sale, no ads, encrypted in transit согласно фактическому SDK;
- Firebase retention, data-sharing и Analytics settings с формулировками privacy policy.

## Метрики и решение после beta

Training session — завершённый урок, Drill, пятираундовая Table-сессия или Quick Review.

- первый урок завершает не менее 60%;
- не менее 25% выполняют пять sessions за первую неделю;
- D7 не менее 15%;
- crash-free users не менее 99,5%, sessions не менее 99,8%;
- при математическом расхождении выпуск блокируется;
- при completion ниже 40% или возврате к третьей тренировке ниже 15% сначала пересматриваются onboarding и учебный цикл, а не строятся IAP и полный курс.
