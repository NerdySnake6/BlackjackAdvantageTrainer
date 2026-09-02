# Сборка release-бандла для Google Play

Инструкция для текущей Linux-машины. Проверена целиком 2026-09-02 на Flutter 3.44.8 / Dart 3.12.2.
`DEVELOPMENT_SETUP.md` описывает старый macOS-снимок и здесь не применим.

## Что нужно один раз

| Что | Где | Статус |
| --- | --- | --- |
| Flutter SDK | `~/android-dev/flutter` | есть, в PATH через `env.sh` |
| JDK 17 | `~/android-dev/jdk/jdk-17.0.19+10` | есть |
| Android SDK | `~/android-dev/sdk` | есть |
| Скрипт окружения | `~/android-dev/env.sh` | есть |
| Upload keystore | `~/android-dev/keystores/blackjack-advantage-trainer-upload.jks` | есть, вне репозитория |
| Пароли подписи | `android/key.properties` | есть, в `.gitignore` |

Системная Java на этой машине - 25, Gradle с ней не собирает. `env.sh` переключает на JDK 17
и подключается из `~/.bashrc`, поэтому в новом терминале всё уже готово.

`android/key.properties` содержит `storePassword`, `keyPassword`, `keyAlias=upload` и абсолютный `storeFile`.
Файл не коммитится. Если он пропадёт, `android/app/build.gradle.kts` молча подпишет release debug-ключом,
и Play отклонит загрузку. Поэтому подпись проверяется отдельным шагом ниже.

## Окружение

Ничего делать не нужно: `~/.bashrc` подключает `~/android-dev/env.sh`, который проставляет
`JAVA_HOME` на JDK 17, `ANDROID_HOME` и кладёт в PATH flutter, dart, adb и cmdline-tools.

Проверка в новом терминале:

```sh
java -version     # 17.0.19
flutter --version # 3.44.8
```

Если что-то из этого не так, `source ~/android-dev/env.sh` вручную. Повторный source безопасен,
PATH не дублируется.

## Версия

Источник истины - поле `version` в `pubspec.yaml`, формат `versionName+versionCode`:

```yaml
version: 1.0.0+1
```

`flutter build` переписывает `flutter.versionName` и `flutter.versionCode` в `android/local.properties`
из этого поля, поэтому руками `local.properties` править не нужно. Устаревшие значения оттуда попадут в сборку
только если вызывать `./gradlew bundleRelease` напрямую в обход `flutter build`.

Play отклоняет повторный `versionCode`. Каждая новая загрузка требует увеличить число после `+`.

## Сборка

Из корня репозитория:

```sh
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build appbundle --release
```

Первые четыре команды - тот же gate, что и в CI (`.github/workflows/android-build.yml`).
Собирать с незакоммиченными изменениями в рабочем дереве не следует: артефакт перестаёт быть воспроизводимым.

Результат:

```text
build/app/outputs/bundle/release/app-release.aab
```

`.aab` - формат для Play. `flutter build apk` даёт APK для ручной установки и в Play не загружается.

## Проверка артефакта перед загрузкой

Подпись:

```sh
jarsigner -verify -verbose:summary -certs build/app/outputs/bundle/release/app-release.aab | grep -E 'jar verified|CN='
```

Должно быть `jar verified` и `CN=Anton Zlobin, OU=Development, O=Blackjack Advantage Trainer`.
`CN=Android Debug` означает, что `key.properties` не подхватился - загружать нельзя.

Версия и SDK в собранном манифесте:

```sh
grep -oE 'android:(versionCode|versionName|targetSdkVersion|minSdkVersion)="[^"]*"' \
  build/app/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml | sort -u
```

Ожидается `minSdkVersion=24`, `targetSdkVersion=36`, `versionCode`/`versionName` из `pubspec.yaml`.

Предупреждения `jarsigner` вида `signed in JarFile but is not signed in JarInputStream` относятся к
`BUNDLE-METADATA/*` и нормальны для AAB.

## Что дальше

`.aab` загружается в Play Console вручную. Ключ в `keystores` - upload key: его потеря требует
процедуры сброса через поддержку Play, поэтому keystore и `key.properties` бэкапятся отдельно от репозитория.

Требования к самому релизу (privacy policy, Data Safety, метрики beta) - в [BETA_RELEASE.md](BETA_RELEASE.md).

## Типичные ошибки Play Console

**«Невозможно внедрить эту версию, поскольку она не позволяет существующим пользователям обновить наборы App Bundle»**
вместе с **«Этот выпуск не добавляет и не удаляет наборы App Bundle»**.

Два разных источника, оба не связаны с ключами:

1. `versionCode` уже присутствует в этом треке. Набор бандлов в релизе не изменился, обновляться некуда.
   Увеличить число после `+` в `pubspec.yaml`, пересобрать, загрузить заново.
2. Бандл не прикрепился к релизу: ушёл в App bundle library или в другой трек. Черновик релиза пустой,
   и первая ошибка следует из этого. Пересборка не поможет, нужно проверить трек и саму загрузку.

Различаются по списку бандлов в релизе: есть там versionCode или нет.

Проблемы с ключом выглядят иначе - Play явно пишет про несовпадение отпечатка upload-сертификата.
