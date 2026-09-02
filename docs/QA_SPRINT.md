# QA-спринт перед Android beta

Статус документа: план спринта и журнал верификации. Составлен 2026-09-02,
обновлён 2026-09-03 после сверки с `origin/main`. Релизная процедура остаётся в
[BETA_RELEASE.md](BETA_RELEASE.md), среда — в
[DEVELOPMENT_SETUP.md](DEVELOPMENT_SETUP.md).

Заморожено на время спринта: новые уроки, IAP, реклама, дополнительные rule
profiles. Русская локализация была в заморозке, но пришла на `main`
коммитом `6ece657` вместе с переключением языка, поэтому попадает в scope
проверки.

## 0. Состояние на 2026-09-03

Исходный план писался на срез 2026-09-02 (53 теста, 66,5% покрытия). За сутки
на `main` пришли три коммита, закрывшие значительную часть разделов 1, 2 и 4.
Актуальный срез:

| Метрика | 2026-09-02 | 2026-09-03 |
| --- | --- | --- |
| Тестов проходит | 53 | 105 |
| domain | 94,5% | **97,6%** (цель 95%) |
| viewmodels + data + core/persistence | 56,4% | **91,2%** (цель 85%) |
| Всего | 68,2% | **88,3%** (цель 75%) |

Все три порога покрытия из раздела 1 взяты. Проценты считаются на знаменателе с
исключениями (см. 1.2), поэтому не сравнимы напрямую с исходными 66,5%.

Единственный файл, который не видит ни один тест, —
`lib/data/firebase_telemetry.dart`. `tool/check_coverage.sh` из-за него
намеренно возвращает 1.

### 0.1 Физическое устройство: подключено 2026-09-03

| Параметр | Значение |
| --- | --- |
| Устройство | Redmi Note 8 Pro (`begonia`) |
| Android | 13, API 33 |
| ABI | arm64-v8a |
| Экран | 1080×2340 @ 440dpi (393×851 dp) |
| Локаль | ru-RU (`system_locales` = `ru-RU,en-US`) |

По USB устройство ядром не перечислялось вообще (`lsusb` пуст), поэтому
используется беспроводная отладка: `adb pair <ip>:<порт> <код>`, дальше adb сам
поднимает `_adb-tls-connect._tcp`.

Проверено на устройстве 2026-09-03 (build 1.0.0+4, debug, arm64):

- Сборка `flutter build apk --debug --target-platform android-arm64` — 43 с.
- Чистая установка и запуск: `Displayed +4s725ms`, ни одного `FATAL` или
  `AndroidRuntime` в logcat. Firebase инициализировался.
- Маршрут 1 integration suite вручную: fresh install → «I'm new to blackjack»
  → оба переключателя telemetry выключены по умолчанию → «Save and continue»
  → Learning path с первым уроком. Проходит.
- Пункт 3.6, обновление поверх: установка новой сборки без удаления сохранила
  onboarding, приложение открылось сразу на Learning path.
- Отказ от telemetry сохраняется корректно: в
  `files/datastore/FlutterSharedPreferences.preferences_pb` после отказа лежит
  `analyticsConsent.isGranted = false` и `crashReportsConsent.isGranted = false`.
- Локаль ru-RU: на момент прогона ru-пакет контента грузился, но текст в нём
  был английский (scaffold). Полный русский перевод и переключение языка
  пришли позже тем же днём (`6ece657`), поэтому прогон на устройстве надо
  повторить: русский UI на реальном экране ещё не видели ни разу. Дрейф ID и
  полнота перевода покрыты `test/data/content_locale_test.dart`.

Что это меняет: устройство закрывает внешний gate раздела 5 (smoke-тест на
физическом Android) и делает возможными lifecycle-проверки пункта 3.6. Оно
**не** заменяет эмуляторы API 24 и API 36: API 33 лежит между ними и не
проверяет ни минимальную, ни целевую версию.

### 0.2 Android-эмуляторы: по-прежнему отсутствуют

`DEVELOPMENT_SETUP.md` описывает macOS-машину и AVD
`blackjack_pixel_7_api_36`. Текущая машина — Linux, и на ней:

- `~/android-dev/sdk/system-images` содержит только `android-34/android-wear/x86_64`;
- единственный AVD — `wear_test`, телефонных AVD нет;
- platforms 34/35/36 и build-tools 34/35/36 установлены, upload key на месте
  (`~/android-dev/keystores/blackjack-advantage-trainer-upload.jks`).

Создание матрицы эмуляторов остаётся самостоятельной задачей. Физическое
устройство из 0.1 её не снимает.

Поправка к исходному тексту: на x86_64 Linux ARM64-образ API 24 запускается
через полную эмуляцию инструкций и практически непригоден. Берём
`system-images;android-24;google_apis;x86_64` (или API 26 x86_64, если образ 24
не поднимается), а не ARM64.

`minSdk` подтверждён: `flutter.minSdkVersion` = 24.

### 0.3 Журнал дефектов

| ID | Место | Класс | Состояние |
| --- | --- | --- | --- |
| QA-1 | `lib/data/local_progress_repository.dart` | P0 | `jsonDecode` без `try/catch`: повреждённое значение бросало исключение до `runApp`, постоянный crash-loop. **Исправлено на `main`** (`646cd41`). |
| QA-2 | `lib/app/router.dart`, `lib/domain/learning/models.dart:49` | P1 | `lessonById` использует `firstWhere` без `orElse`; неизвестный `lessonId` бросал `StateError` во время build. **Исправлено на `main`** guard-редиректом маршрута `/lesson/:lessonId`. |
| QA-3 | `android/app/src/main/AndroidManifest.xml` | P0 (compliance) | В собранном APK присутствовали `com.google.android.gms.permission.AD_ID`, `ACCESS_ADSERVICES_AD_ID` и `ACCESS_ADSERVICES_ATTRIBUTION` из `firebase_analytics`, при том что `PRIVACY_POLICY.md:43` заявляет отсутствие advertising identifier SDK. **Исправлено 2026-09-03.** |
| QA-4 | `lib/main.dart` | P1 | `Firebase.initializeApp` без `try/catch`. **Исправлено на `main`**, вынесено в `lib/data/telemetry_bootstrap.dart`. |

Проверка QA-1 на живом устройстве 2026-09-03. В
`FlutterSharedPreferences.preferences_pb` первый байт JSON заменён на `[`
(та же длина, поэтому protobuf остаётся валидным, а JSON — нет). После
запуска: процесс жив, `FATAL` и `E/flutter` в logcat нет, битый блок лежит под
recovery-ключом, исходный ключ удалён. То есть исправление не только не падает,
но и не теряет данные.

Проверка QA-3 на артефакте: `aapt2 dump permissions app-debug.apk` до
исправления показывал все три разрешения, после — ни одного.

Неподтверждённое наблюдение: в самом первом прогоне на устройстве в хранилище
оказалось `isGranted: true` для обоих каналов, хотя переключатели были
выключены. Три последующих чистых прогона дали `false`, код
(`AppState.setTelemetryConsent`) присваивает значение напрямую. Воспроизвести не
удалось, дефект не заводится. Пересмотреть при проверке четырёх режимов consent
(пункт 4.6).

---

## 1. Расширение автоматических тестов

| # | Пункт | Статус |
| --- | --- | --- |
| 1.1 | Подключить `integration_test` | **Сделано** |
| 1.2 | Зафиксировать список исключений lcov | **Сделано**, `tool/check_coverage.sh` |
| 1.3 | Общее покрытие ≥75% | **Сделано**, 88,2% |
| 1.4 | Порог domain ≥95% | **Сделано**, 97,6% |
| 1.5 | Порог ViewModel/persistence ≥85% | **Сделано**, 91,0% |
| 1.6 | Без обязательного процента для UI | **Сделано** |
| 1.7 | Тесты Quick Review | **Сделано**, `test/presentation/quick_review_screen_test.dart` |
| 1.8 | Тесты Drill | **Сделано**, `count_drill_widget_test.dart` + `viewmodels/learning_flows_test.dart` |
| 1.9 | Тесты Lesson | **Сделано**, `viewmodels/learning_flows_test.dart` |
| 1.10 | Тесты Progress | **Сделано**, `test/presentation/progress_screen_test.dart` |
| 1.11 | Тесты `LocalProgressRepository` | **Сделано**, `test/data/local_progress_repository_test.dart` |
| 1.12 | Тесты router | **Сделано**, `test/app/router_test.dart`, 6 случаев |

Исключения lcov: `lib/l10n/**` и `lib/firebase_options.dart` (генерируются),
`lib/main.dart` (bootstrap, покрывается integration-тестами) и
`lib/core/persistence/progress_repository.dart` (голый интерфейс без
исполняемых строк, lcov его не эмитит в принципе).
`lib/data/firebase_telemetry.dart` **не исключён** — его надо покрыть.

`check_coverage.sh` сравнивает `find lib -name '*.dart'` со списком `SF:` в
`lcov.info`: файл, который не импортирует ни один тест, не попадает в отчёт
вообще и молча исчезает из знаменателя вместо того, чтобы получить 0%. Без этой
проверки любой процент недостоверен.

Пороги — храповик: floor поднимается по мере появления тестов и никогда не
опускается. Сейчас floor равен target по всем трём слоям.

Ловушка для новых widget-тестов: `rootBundle.loadString` не резолвится во
втором `testWidgets` в одном файле, тест зависает молча и без вывода. Грузите
каталог один раз в `setUpAll`, как в `test/app/router_test.dart`.

## 2. Углублённая проверка математики Table

| # | Пункт | Статус |
| --- | --- | --- |
| 2.1 | Детерминированные сценарии раздачи | **Сделано**, `blackjack_engine_standard_profile_test.dart` |
| 2.2 | Seeded stress-test на 10 000 раундов | **Сделано**, `blackjack_engine_stress_test.dart` (100 seed × 100 раундов) |

Осталось: сверить фактический список сценариев 2.1 с исходным перечнем
(blackjack против blackjack, surrender до третьей карты и запрет после Hit,
dealer peek с тузом и с десяткой, resplit до четырёх рук, DAS, несколько
человеческих мест, боты со всеми действиями, push/bust/выплаты по каждому
исходу, смена мест во время раунда) и дописать недостающие.

Любое расхождение здесь — P0 и блокирует beta.

## 3. Сквозные UI и платформенные сценарии

| # | Пункт | Статус |
| --- | --- | --- |
| 3.1 | Android integration suite (12 маршрутов) | Не сделано, каталога `integration_test/` нет |
| 3.2 | Матрица API 36 | Не сделано, AVD отсутствует (0.2) |
| 3.3 | Матрица API 24 (или 26) x86_64 | Не сделано, образ не установлен |
| 3.4 | Семь размеров экрана | Покрыто в `layout_test.dart` |
| 3.5 | Text scale 1.0 и 1.3 | Частично: каждый размер на одном scale, не на обоих |
| 3.6 | Airplane mode, сворачивание, kill процесса, обновление сборки | Частично: обновление проверено на устройстве (0.1), остальное нет |
| 3.7 | Accessibility-проверки | Не сделано |
| 3.8 | Golden-тесты | Сознательно не вводим |

По 3.4: `layout_test.dart` проходит все семь размеров (320×568, 360×800,
430×932 portrait; 568×320, 800×360, 844×390, 915×412 landscape), но portrait
проверяется только на Learning path, landscape только на Table, и каждый размер
только на одном text scale. Дополнить cross-product и добавить Drill,
Quick Review, Lesson, Progress.

Маршруты integration suite:

1. Fresh install → Beginner → отказ от telemetry → первый урок.
2. Basics → рекомендованная стартовая точка, ранние уроки не завершаются сами.
3. Experienced → Table и Drill доступны, прогресс ранних уроков не подделывается.
4. Ответ на часть урока → выход → восстановление позиции.
5. Урок ниже 80% → требование повторения.
6. Урок успешно → следующий разблокирован.
7. Полный проход Drill.
8. Guided Table, пять раундов.
9. Practice Table, пять проверок running count.
10. Смена мест Human/Bot/Empty во время раздачи.
11. Создание и завершение Quick Review.
12. Смена уровня и telemetry в Progress без потери прогресса.

Маршрут 1 уже пройден вручную на устройстве (0.1).

Accessibility: минимальные области нажатия, доступные названия кнопок,
`Semantics` для карт, отсутствие критических нарушений contrast и tap-target.

## 4. Firebase и отказоустойчивость

| # | Пункт | Статус |
| --- | --- | --- |
| 4.1 | `setUserProperty` в `AnalyticsGateway` | **Сделано** |
| 4.2 | Allowlist свойств: только `experience_level` | **Сделано**, `_allowedUserProperties` |
| 4.3 | Установка после opt-in, обновление, очистка при отказе | **Сделано** |
| 4.4 | Событие `training_session_completed` | **Сделано** |
| 4.5 | Сохранить существующие детальные события | **Сделано** |
| 4.6 | Проверка четырёх режимов consent на устройстве | Не сделано |
| 4.7 | Firebase init failure → NoOp gateways | **Сделано**, `lib/data/telemetry_bootstrap.dart` |
| 4.8 | Повреждённый прогресс без crash-loop, recovery key | **Сделано**, проверено на устройстве (0.3) |
| 4.9 | Автотесты запрета answer text, card sequences, email | **Сделано**, `test/core/telemetry_gateways_test.dart` |
| 4.10 | Рекламные разрешения не попадают в APK | **Сделано** (QA-3) |

Не путать два allowlist: `_allowedParameterKeys` фильтрует параметры событий и
содержит `experience_level`; `_allowedUserProperties` — отдельный список из
одного ключа для user properties.

Матрица consent для проверки 4.6:

| Analytics | Crash reports | Ожидание |
| --- | --- | --- |
| Off | Off | Ни событий, ни отчётов |
| On | Off | События есть, crash reports нет |
| Off | On | Событий нет, тестовый crash появляется |
| On | On | Оба канала работают |

Analytics проверяем через DebugView, затем обязательно снимаем debug property.
Crashlytics — временной кнопкой в отдельной debug-ветке; ветку и кнопку в `main`
не сливать. При этой проверке заодно перепроверить неподтверждённое наблюдение
из 0.3.

## 5. CI, ручной прогон и критерий готовности

| # | Пункт | Статус |
| --- | --- | --- |
| 5.1 | PR workflow: format, analyze, tests, Android debug build | **Сделано**, `android-build.yml` |
| 5.2 | Coverage gates в PR workflow | Частично: `tool/check_coverage.sh` готов, в workflow не подключён |
| 5.3 | Nightly/manual workflow с integration tests на эмуляторе | Не сделано |
| 5.4 | Release-кандидат на постоянном upload key | Задокументировано в `PLAY_STORE_RELEASE.md`, key на месте |
| 5.5 | Прогон полного набора проверок для кандидата | Задокументировано в `BETA_RELEASE.md`, не автоматизировано |
| 5.6 | Единый чек-лист ручного QA | Не сделано |

Проверки для каждого кандидата: полный test suite; signed release APK и AAB;
проверка подписи, package ID, versionCode, minSdk/targetSdk и **отсутствия
рекламных разрешений**; iOS debug build без codesign; `git diff --check`.

Чек-лист ручного QA фиксирует для каждого пункта: устройство, build number,
результат, screenshot или видео, issue ID.

Классификация ошибок:

- **P0**: математика, потеря прогресса, crash-loop, невозможность пройти
  основной сценарий, несоответствие privacy policy фактическому поведению.
- **P1**: layout, навигация, неправильный resume, непонятный onboarding.
- **P2**: косметика и пожелания.

Beta build разрешён только при: ноль P0, ноль открытых блокирующих P1, зелёный
CI, успешный полный прогон на API 24/26 и API 36.

Перед приглашением всей группы первый APK получает один технический
тестировщик с физическим Android. Только после его успешного smoke-теста сборка
уходит остальным 3–9 людям.

---

## Что осталось

Разделы 1, 2 и 4 закрыты почти полностью. Оставшийся объём сместился в
платформенную часть:

| Приоритет | Работа |
| --- | --- |
| 1 | Матрица эмуляторов: скачать `android-36;google_apis;x86_64` и `android-24;google_apis;x86_64`, создать AVD, проверить `flutter run`. Обновить `DEVELOPMENT_SETUP.md` под Linux-машину. |
| 2 | Раздел 3: `integration_test/`, 12 маршрутов, прогон на API 36 и API 24/26. |
| 3 | Пункт 4.6: четыре режима consent на устройстве, DebugView, Crashlytics в отдельной debug-ветке. Заодно перепроверить наблюдение из 0.3. |
| 4 | Пункт 5.2 и 5.3: подключить `check_coverage.sh` в `android-build.yml`, добавить nightly workflow с эмулятором. |
| 5 | Пункты 3.5, 3.6, 3.7: cross-product размеров и text scale, lifecycle-сценарии, accessibility. Русский UI добавляет вторую языковую ветку в матрицу: русские строки длиннее английских и первыми ловят overflow. |
| 6 | Пункт 2.1: сверить список детерминированных сценариев, дописать недостающие. |
| 7 | Пункт 5.6: чек-лист ручного QA, сборка кандидата, передача техническому тестировщику. |
| 8 | Покрыть `lib/data/firebase_telemetry.dart`, после чего `check_coverage.sh` станет зелёным. |

## Принятые ограничения

- Спринт тестирует только текущий Android beta-scope, теперь включая русскую
  локализацию.
- iPhone Simulator и iOS build проверяются, но TestFlight и физический iPhone не
  блокируют Android beta.
- Физический Android остаётся обязательным внешним gate. Эмулятор не заменяет
  проверку производительности, lifecycle, установки и обновления на реальном
  устройстве.
- Рост процента покрытия не самоцель: приоритет у математических инвариантов и
  реальных пользовательских путей.
