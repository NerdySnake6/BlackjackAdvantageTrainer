# Среда разработки

Статус документа: подтверждённый локальный снимок на 2026-08-02. Продуктовые ограничения описаны в [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md), устройство кода — в [ARCHITECTURE.md](ARCHITECTURE.md).

## Основная рабочая папка

Единственный основной корень проекта:

```text
/Users/nerdysnake6/Documents/BlackjackAdvantageTrainer
```

Все Flutter-команды запускаются из этого каталога. Не открывайте отдельно `android/` как основной проект и не создавайте вторую копию репозитория для обычной разработки.

## Подтверждённые версии

| Компонент | Версия на 2026-08-02 |
| --- | --- |
| Flutter | 3.44.8 stable |
| Dart | 3.12.2 |
| Android Studio | 2026.1.3 |
| Android SDK platform | API 36 |
| Android SDK build-tools | 36.0.0 |
| Android Emulator | 37.1.11 |
| AVD | `blackjack_pixel_7_api_36` |
| Android Studio JBR/OpenJDK | 25.0.2 |
| Xcode | 16.4, build 16F6 |
| iOS Simulator runtime | 18.6 |
| CocoaPods | 1.17.0 |

Версия в этой таблице — воспроизводимый снимок, а не требование всегда обновляться до newest. После намеренного обновления SDK сначала прогоняются все проверки и обе platform builds, затем этот документ обновляется.

Минимальная поддерживаемая версия iOS — 15.0. Это требование текущих Firebase Flutter-плагинов при использовании Swift Package Manager.

## Локальные пути

| Назначение | Путь |
| --- | --- |
| Репозиторий | `/Users/nerdysnake6/Documents/BlackjackAdvantageTrainer` |
| Flutter CLI | `/opt/homebrew/bin/flutter` |
| Flutter SDK, используемый проектом | `/opt/homebrew/share/flutter` |
| Homebrew Flutter installation | `/opt/homebrew/Caskroom/flutter/3.44.8/flutter` |
| Dart CLI | `/opt/homebrew/bin/dart` |
| Android Studio | `/Applications/Android Studio.app` |
| Android Studio JBR | `/Applications/Android Studio.app/Contents/jbr/Contents/Home` |
| Android SDK, используемый проектом | `/opt/homebrew/share/android-commandlinetools` |
| Android API 36 | `/opt/homebrew/share/android-commandlinetools/platforms/android-36` |
| Android build-tools 36.0.0 | `/opt/homebrew/share/android-commandlinetools/build-tools/36.0.0` |
| Xcode | `/Applications/Xcode-16.4.0.app` |
| Selected Xcode developer directory | `/Applications/Xcode-16.4.0.app/Contents/Developer` |

`android/local.properties` хранит машинные пути к Flutter и Android SDK. Этот файл локальный и не коммитится.

## Что означает каждый инструмент

- **Dart** — язык, runtime и базовые инструменты анализа/форматирования. Pure-Dart domain можно тестировать без UI.
- **Flutter** — UI framework, engine и CLI, который собирает общее Dart-приложение под платформы.
- **Android SDK** — Android APIs, build-tools, platform-tools и другие инструменты платформы.
- **JDK/JBR** — Java runtime для Gradle и Android build. JBR — сборка OpenJDK, поставляемая с Android Studio.
- **Android Emulator** — программа, запускающая виртуальное Android-устройство.
- **AVD** — сохранённая конфигурация конкретного виртуального устройства; здесь это `blackjack_pixel_7_api_36`.
- **Xcode** — Apple toolchain, SDK, simulator management и signing UI.
- **iOS Simulator runtime** — образ конкретной версии iOS для Simulator; это не Xcode и не приложение.
- **Swift Package Manager (SPM)** — основной менеджер native iOS dependencies в текущем Flutter 3.44 проекте.
- **CocoaPods** — compatibility fallback для плагинов или окружений без SPM; установленная версия сама по себе не означает, что проект сейчас использует pods.

## Android Studio

1. Запустите Android Studio.
2. Выберите **Open**.
3. Откройте корень `/Users/nerdysnake6/Documents/BlackjackAdvantageTrainer`.
4. Дождитесь индексации и синхронизации Gradle/Flutter.
5. Выберите AVD `blackjack_pixel_7_api_36` и конфигурацию Flutter для `lib/main.dart`.

Flutter plugin для Android Studio нужно установить через Settings → Plugins, если он отсутствует. Plugin обычно предлагает Dart plugin как зависимость. Наличие Flutter SDK на диске не означает, что IDE plugin уже установлен.

## Xcode

Открывайте workspace, а не отдельный `.xcodeproj`:

```sh
open ios/Runner.xcworkspace
```

Текущая интеграция использует SPM и локальный `FlutterGeneratedPluginSwiftPackage`. CocoaPods остаётся compatibility fallback. Если конкретный плагин требует pods, выполняйте migration осознанно и проверяйте, что dependency не подключён одновременно через SPM и CocoaPods.

App Store signing и provisioning не считаются настроенными. Подтверждена только debug-сборка устройства без codesign.

## Базовые команды

Из корня проекта:

```sh
flutter pub get
dart format lib test
flutter analyze
flutter test
```

Запуск на выбранном устройстве:

```sh
flutter devices
flutter run
```

Запуск подготовленного Android AVD из Flutter:

```sh
flutter emulators --launch blackjack_pixel_7_api_36
flutter run
```

Debug APK:

```sh
flutter build apk --debug
```

Debug iOS device build без подписи:

```sh
flutter build ios --debug --no-codesign
```

Для UI, lifecycle, purchases, orientation, restore и store behavior эмулятора недостаточно: перед выпуском нужны проверки на реальных Android и iOS устройствах.

## Идентификаторы приложения

- Android namespace: `com.blackjackadvantage.trainer`
- Android application ID: `com.blackjackadvantage.trainer`
- iOS Runner bundle ID: `com.blackjackadvantage.trainer`
- iOS tests bundle ID: `com.blackjackadvantage.trainer.RunnerTests`
- Dart package name: `blackjack_advantage_trainer`

Snake case в Dart package name правилен и не должен заменяться bundle ID.

## Перед коммитом

Минимум для Dart/UI change: форматирование изменённых Dart-файлов, `flutter analyze` и `flutter test`. Изменения platform config требуют соответствующей platform build; изменения общих runtime boundaries или release configuration — обеих сборок. Не коммитьте `build/`, `.dart_tool/`, `.idea/`, `.serena/`, `local.properties` или секреты.
