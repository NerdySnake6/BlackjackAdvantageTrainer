# Контекст продукта Blackjack Advantage Trainer

Статус документа: канонический долговечный продуктовый контекст. Снимок решений — 2026-08-02. Этот файл сохраняет решения исходного ChatGPT-проекта и должен обновляться вместе с одобренными изменениями продукта. Текущее состояние реализации отдельно отмечено ниже и подробнее описано в [ARCHITECTURE.md](ARCHITECTURE.md).

## Продукт и позиционирование

Blackjack Advantage Trainer — англоязычная кроссплатформенная школа блэкджека в стиле Duolingo и Mimo. Приложение обучает через короткие уроки, упражнения и полностью автономную симуляцию стола. Оно не считывает реальную игру и не является помощником во время игры в казино.

Основная ценность — довести до автоматизма три навыка: точность решений basic strategy, скорость счёта и совмещение стратегии со счётом в условиях полноценного стола. Обучение должно честно объяснять дисперсию, преимущество заведения и условия, при которых математическое преимущество вообще возможно. Продукт не обещает гарантированный выигрыш.

## Гипотеза и критерии прототипа

Первую гипотезу проверяем на 30–50 тестировщиках. Прототип считается перспективным, если:

- не менее 60% тестировщиков заканчивают первый урок;
- не менее 25% выполняют пять учебных сессий за первую неделю;
- удержание D7 не ниже 15%.

Направление и onboarding нужно пересмотреть, если первый урок заканчивают менее 40% пользователей или к третьей тренировке возвращаются менее 15%.

Эти показатели оценивают понятность и учебную ценность, а не финансовые результаты симуляции.

## Полный учебный путь

План курса содержит 76 уроков: 44 бесплатных и 32 Pro.

| Доступ | Раздел | Уроков |
| --- | --- | ---: |
| Free | Quick Start | 1 |
| Free | Rules & Hands | 5 |
| Free | Basic Strategy | 16 |
| Free | Math & Reality | 4 |
| Free | Hi-Lo Foundations | 5 |
| Free | Running Count | 7 |
| Free | Table Integration | 6 |
|  | **Всего Free** | **44** |
| Pro | Deck Estimation | 5 |
| Pro | True Count | 5 |
| Pro | Playing Deviations | 8 |
| Pro | Betting & Risk | 5 |
| Pro | Game Selection | 4 |
| Pro | Full-Shoe Certification | 5 |
|  | **Всего Pro** | **32** |
|  | **Всего** | **76** |

Текущий прототип реализует только первые шесть оригинальных уроков, а не весь путь.

## Формат обучения

- Первый урок занимает 5–7 минут, остальные — 10–15 минут.
- Типичный урок строится в пропорции 20/60/20: повторение, новый материал, применение.
- Quick Review занимает 3–5 минут и не блокирует основной путь.
- Placement Test позволяет опытному ученику подтвердить уже освоенные навыки, но не отменяет экзаменационные критерии.
- Интервальное повторение использует интервалы 1, 3, 7, 14 и 30 дней.
- Тренировочный стол доступен всегда, независимо от продвижения по пути.
- В продукте нет hearts, energy и leagues: ограничители вовлечения не должны мешать осознанной практике.

## Mastery и сертификация

Прогресс определяется точностью и воспроизводимостью навыка:

- урок завершён при результате не ниже 80%;
- checkpoint требует 90–95% в зависимости от навыка;
- basic strategy: 100 последовательных правильных решений;
- running count: три полные колоды без ошибки, последовательно на уровнях 60, 45 и 30 секунд на колоду;
- true count: точность не ниже 95%;
- финальная сертификация: 100% basic strategy, точный running count, не менее 95% true count и 100% ключевых playing deviations.

Случайный денежный итог раздачи или сессии не влияет на mastery. Правильное решение может проиграть из-за дисперсии, а неправильное — случайно выиграть.

## Симулятор стола и правила

Стол имеет пять мест. Каждое место настраивается как `Human`, `Bot` или `Empty`; требуется хотя бы одно `Human`. Один человек может занять все пять мест. Конфигурация по умолчанию — один человек и четыре бота. На одном месте допускается не более четырёх рук после split.

Единственный стандартный профиль, разрешённый сейчас:

- 6 колод;
- blackjack 3:2;
- dealer stands on soft 17 (S17);
- double after split (DAS);
- late surrender;
- dealer peek;
- penetration 75%, то есть около 234 из 312 карт.

Режимы проверки счёта в полном продукте:

- **Guided** — частые подсказки и проверки;
- **Practice** — редкие контрольные точки;
- **Exam** — результат раскрывается после законченной сессии.

Профили на 1, 2, 6 и 8 колод, H17/S17, DAS, surrender и выплаты 3:2/6:5 добавляются только после математической проверки solver/reference и автоматических reference-тестов. Нельзя экстраполировать таблицу одного профиля на другой.

## Free, Pro и покупки

Free включает путь до running count включительно и стандартный стол. Pro в первой версии — lifetime unlock с ценовым ориентиром USD 7.99 и стабильным product ID `pro_lifetime_v1`.

Pro открывает:

- deck estimation и true count;
- Illustrious 18 и Fab 4;
- betting, bankroll и risk of ruin;
- проверенные rule profiles;
- расширенную статистику и Full-Shoe Certification.

В продукте нет постоянного bankroll, покупаемых фишек или внутренней валюты. Раздел Betting & Risk использует только абстрактные betting units внутри математических упражнений и отдельных учебных сессий. Эти units нельзя купить, вывести, обменять или сохранить как пользовательский денежный баланс; у них нет реальной стоимости.

I18 и Fab 4 нельзя копировать вместе с индексами, таблицами, формулировками или упражнениями из коммерческих материалов. Каждый используемый индекс должен быть независимо рассчитан или проверен, иметь зафиксированный provenance и, если он получен из внешнего набора данных, явную совместимую лицензию.

В v1 нет рекламы, аккаунтов, подписок, мультиплеера и реальных денег. Store-независимая граница состоит из `PurchaseGateway`, `FakePurchaseGateway`, восстановления покупок через `restorePurchases()` и `FeatureAccessPolicy`. Реальные адаптеры App Store и Google Play запланированы, но не реализованы.

Lifetime-покупка восстанавливается в рамках соответствующего магазина. Покупка iOS не переносится автоматически на Android и наоборот без отдельного аккаунта и серверной entitlement-системы, которых в v1 нет.

## Безопасность и App Store

Приложение — educational simulation. Запрещены:

- камера, микрофон и распознавание реальных карт;
- ручной или автоматический ввод состояния внешнего реального стола;
- real-time overlays и подсказки поверх других приложений;
- казино-интеграции, партнёрские казино-ссылки и переходы к реальной игре;
- функции, инструкции или режимы, помогающие обходить наблюдение казино.

[Apple App Review Guideline 5.3.4](https://developer.apple.com/app-store/review/guidelines/) прямо создаёт риск для приложений, которые могут рассматриваться как card-counter aids. В review note нужно честно описывать автономную симуляцию, отсутствие внешнего ввода и невозможность применения поверх реального стола. Нельзя скрывать функциональность от review. Сценарий Android-first допустим только после честной апелляции Apple и документированного решения review.

Допустимая маркетинговая формулировка: “find mathematical advantage in suitable conditions”. Недопустимая: “guaranteed beat casino”. Любые заявления о преимуществе должны сопровождаться условиями и объяснением риска.

## Локализация и контент

v1 публикуется на английском. Следующий язык — русский; далее порядок Spanish, Brazilian Portuguese, German и French уточняется по данным спроса и удержания.

Интерфейс использует ARB и Flutter `gen-l10n`. Учебный контент хранится отдельными locale packages в `assets/content/<locale>/`. У всех переводов сохраняются одинаковые стабильные `lessonId`, `skillId` и exercise IDs, чтобы прогресс не зависел от языка. Каждый locale package содержит glossary и метаданные версии.

Перевод проходит проверку носителем языка, который понимает терминологию блэкджека. Язык публикуется только при 100% completeness: UI, уроки, пояснения, glossary, disclaimers, покупки, store listing и screenshots.

## Стабильность и crash-free цели

Рабочее определение crash-free users для проекта: `1 - crashed installations / active installations` за выбранный период. В числителе учитываются только fatal crashes. Отдельно отслеживаются:

- crash-free sessions;
- nonfatal errors;
- Android ANR;
- версия приложения, ОС и модель устройства.

Стартовые цели на rolling 7 days: не менее 99.5% crash-free users и не менее 99.8% crash-free sessions. После стабилизации цель crash-free users повышается до 99.8%. Периоды нельзя смешивать при сравнении метрик.

## Дорожная карта при 8–12 часах в неделю

| Месяцы | Результат |
| --- | --- |
| 1–2 | Dart, Flutter и clean domain |
| 3–4 | Сквозной vertical prototype |
| 5–8 | Engine, Free path, review, mastery и analytics |
| 9–11 | Pro math, validated profiles и certification |
| 12–14 | Purchases, restore, closed beta и fixes |
| 15–16 | Publication и stabilization |
| После English v1 | Russian localization за ориентировочно 1–2 месяца |

Итоговый ориентир для English commercial v1 — 12–16 месяцев при загрузке 8–12 часов в неделю. Сроки являются рабочей оценкой, а не обещанием. Математическая проверка и store review могут увеличить этап.

## Обучение разработчика

Обучение идёт вместе с roadmap, а не отдельным теоретическим курсом. На каждом этапе обязателен один и тот же цикл:

1. Выбрать и пройти 2–4 материала из списка этапа.
2. Кратко объяснить изученное на русском своими словами, включая связь с текущей архитектурой проекта.
3. Выполнить практическое задание на небольшом, проверяемом изменении.
4. Подтвердить критерий перехода тестами или работающим сценарием.
5. Провести review написанного кода до перехода к следующему этапу; автор должен уметь объяснить каждое решение и исправить замечания.

### Этап 1. Dart и clean domain

Материалы:

- [Stepik: Основы программирования на Dart](https://stepik.org/course/109361/promo)
- [Dart language](https://dart.dev/language)
- [Flutter: introduction to unit testing](https://docs.flutter.dev/cookbook/testing/unit/introduction)

Краткое объяснение на русском должно покрывать types, null safety, collections, functions, classes, enums, async/await и причину, по которой domain не импортирует Flutter. Практическое задание — изменить или добавить небольшое pure-Dart поведение и deterministic unit tests без UI. Критерий перехода: код отформатирован, `flutter analyze` и focused/full tests проходят, а разработчик может объяснить dependency direction. Review проверяет API, naming, edge cases и достаточность тестов.

### Этап 2. Flutter foundation и vertical flow

Материалы:

- [Flutter install](https://docs.flutter.dev/install/quick)
- [Flutter first app](https://docs.flutter.dev/get-started/codelab)

Краткое объяснение на русском должно покрывать widgets, state, rebuild, navigation, assets и hot reload. Практическое задание — проследить один поток от locale asset через ViewModel до View и внести небольшое локализованное UI-изменение. Критерий перехода: сценарий работает на целевой платформе, видимые строки локализованы, state переживает ожидаемые rebuild. Review проверяет отсутствие business logic во View и соответствие существующему UI-паттерну.

### Этап 3. Архитектура и тестируемые границы

Материалы:

- [Flutter guide to app architecture](https://docs.flutter.dev/app-architecture/guide)
- [Flutter testing overview](https://docs.flutter.dev/testing/overview)

Краткое объяснение на русском должно различать View, ViewModel, Repository, Service и Domain, а также unit, widget и integration tests. Практическое задание — провести небольшую функцию через существующие слои с fake repository или gateway и тестами. Критерий перехода: зависимости направлены внутрь, platform boundary заменяется fake, UI и domain тестируются отдельно. Review проверяет необходимость каждой абстракции и отсутствие лишнего слоя.

### Этап 4. Математика блэкджека

Материалы:

- [Wizard of Odds: blackjack rules and basics](https://wizardofodds.com/games/blackjack/basics/)
- [Wizard of Odds: basic-strategy calculator](https://wizardofodds.com/games/blackjack/strategy/calculator/)
- [Wizard of Odds: Hi-Lo introduction](https://wizardofodds.com/games/blackjack/card-counting/high-low/)
- [MIT OpenCourseWare 18.05: Introduction to Probability and Statistics](https://ocw.mit.edu/courses/18-05-introduction-to-probability-and-statistics-spring-2022/)

Краткое объяснение на русском должно связывать rules, conditional strategy, expected value, variance, running count и true count. Практическое задание — создать независимые reference fixtures и deterministic tests для ограниченного набора уже поддержанных правил, не добавляя новый profile. Критерий перехода: QA-инварианты выполняются, полный Hi-Lo shoe заканчивается на нуле, а reference не использует production-алгоритм как собственное доказательство. Review проходят разработчик и независимый специалист по математике блэкджека.

### Этап 5. Risk, purchases и выпуск

Материалы:

- [Wizard of Odds: risk of ruin](https://wizardofodds.com/games/blackjack/risk-of-ruin/)
- [Flutter IAP codelab](https://codelabs.developers.google.com/codelabs/flutter-in-app-purchases)
- [Flutter in_app_purchase plugin](https://pub.dev/packages/in_app_purchase)

Краткое объяснение на русском должно различать variance, risk of ruin, абстрактные betting units, non-consumable purchase, entitlement, verification и restore. Практическое задание — пройти purchase lifecycle сначала через `FakePurchaseGateway`, затем в store sandbox для `pro_lifetime_v1`, не добавляя subscriptions, покупаемые фишки или постоянный bankroll. Критерий перехода: success, pending, cancel, failure и restore проверены на обеих платформах, а entitlement не выдаётся без подтверждения. Review проверяет store requirements, безопасность, idempotency и отсутствие реальных денег.

## Математические и QA-инварианты

Перед платными заявлениями и расширением rule profiles должны быть проверены:

- трактовка ace, soft/hard hands и natural blackjack;
- split, resplit, split aces, ограничение числа рук;
- double, DAS, surrender и допустимость действий;
- dealer peek, hole card, S17/H17 и порядок settlement;
- выплаты blackjack 3:2/6:5, push, bust и surrender;
- conservation of cards во всех раздачах и shuffle boundaries;
- нулевой итог Hi-Lo после полного сбалансированного shoe;
- явно выбранная и одинаково применяемая политика округления отрицательного true count;
- корректная penetration и момент reshuffle;
- все комбинации пяти мест и многократные splits;
- сравнение strategy/deviation tables с независимыми reference tables или solver;
- resume незавершённого урока, review scheduling и миграции `contentVersion`;
- переключение locale без потери прогресса;
- покупка, pending, cancel, failure и restore на обеих платформах;
- реальные устройства, ориентации, жизненный цикл и interrupted sessions.

До платных математических обещаний продукт должен независимо проверить эксперт по блэкджеку. Тесты с тем же алгоритмом, что и production, не считаются независимой валидацией.

## Текущий реализованный vertical slice

На 2026-08-02 в репозитории реализованы:

- шесть английских уроков и 52 оригинальных упражнения;
- one-deck Hi-Lo drill с контрольными точками;
- стандартный five-seat table с конфигурациями `Human`/`Bot`/`Empty`;
- pure-Dart engines для карт, hands, shoe, Hi-Lo, basic strategy и раунда;
- локальный progress и восстановление незавершённого урока;
- английская UI-локализация и versioned English content/glossary;
- fake purchase boundary и отключённая по умолчанию analytics boundary;
- unit и widget tests критической математики и учебного потока.

Не реализованы полный 76-урочный курс, реальные IAP, Firebase/Crashlytics, дополнительные rule profiles, production analytics, русская локализация, store signing и публикация.

## Источники и provenance

Источники нужны для проверки математики, инженерных решений и требований магазинов. Они не дают права копировать коммерческий текст, таблицы, графику или упражнения. Контент Blackjack Advantage Trainer должен быть оригинальным, а заимствованная математика — независимо проверенной и отражённой в provenance.

### Dart и Flutter

- [Dart testing](https://dart.dev/tools/testing)
- [Flutter testing overview](https://docs.flutter.dev/testing/overview)
- [Flutter guide to app architecture](https://docs.flutter.dev/app-architecture/guide)
- [Flutter internationalization and gen-l10n](https://docs.flutter.dev/ui/internationalization)
- [Flutter in_app_purchase plugin](https://pub.dev/packages/in_app_purchase)
- [Flutter Swift Package Manager for app developers](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers)

### Математика и тренировки

- [Wizard of Odds: blackjack rules and basics](https://wizardofodds.com/games/blackjack/basics/)
- [Wizard of Odds: basic-strategy calculator](https://wizardofodds.com/games/blackjack/strategy/calculator/)
- [Wizard of Odds: Hi-Lo introduction](https://wizardofodds.com/games/blackjack/card-counting/high-low/)
- [Wizard of Odds: risk of ruin](https://wizardofodds.com/games/blackjack/risk-of-ruin/)
- [Blackjack Apprenticeship training drills](https://www.blackjackapprenticeship.com/blackjack-training-drills/)
- [MIT OpenCourseWare 18.05: Introduction to Probability and Statistics](https://ocw.mit.edu/courses/18-05-introduction-to-probability-and-statistics-spring-2022/)

Blackjack Apprenticeship — коммерческий источник и ориентир по структуре практики. Нельзя копировать его wording, charts, videos, proprietary drills или платные материалы.

### Review и качество

- [Apple App Review Guidelines, раздел 5.3](https://developer.apple.com/app-store/review/guidelines/)
- [Firebase Crashlytics: crash-free metrics](https://firebase.google.com/docs/crashlytics/crash-free-metrics)
