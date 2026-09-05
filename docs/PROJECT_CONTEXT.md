# Контекст продукта Blackjack Advantage Trainer

Статус документа: канонический продуктовый контракт, обновлён 2026-09-05 по утверждённому плану игрового курса. Порядок работ и критерии итераций находятся в [COURSE_ROADMAP.md](COURSE_ROADMAP.md). Этот план заменяет прежний roadmap на 76 уроков; реализация отдельно описана ниже и в [ARCHITECTURE.md](ARCHITECTURE.md).

## Продукт и позиционирование

Blackjack Advantage Trainer — двуязычный мобильный игровой тренер для взрослого игрока, который знает правила блэкджека и хочет подготовить навыки для advantage play. Основное обещание — находить свои ошибки, исправлять их с Тренером и видеть измеримое улучшение на новых задачах. Начальные уроки доступны новичкам, но не обязательны для знающего игрока. Приложение работает как автономная учебная симуляция.

Основная ценность — довести до автоматизма три навыка: точность решений basic strategy, скорость счёта и совмещение стратегии со счётом в условиях полноценного стола. Обучение должно честно объяснять дисперсию, преимущество заведения и условия, при которых математическое преимущество вообще возможно. Продукт не обещает гарантированный выигрыш.

## Границы утверждённого изменения

Перерабатывается только курс в Learn. Сценарии и интерфейсы Table, Drill, Quick Review и Progress сохраняются. Необходимые изменения общих моделей, хранения и математической корректности допустимы с регрессионной проверкой остальных разделов. Существующие stable lessonId, skillId и exercise IDs сохраняются.

Приоритет выпуска — Android. Публикация iOS отложена по бюджету; ждать Apple review для Android не требуется. Разработка Pro включает контент и контроль доступа, но не billing. Набор тестировщиков начинается до завершения курса. Каждая итерация проходит проверку, отдельный commit и успешный push до перехода к следующей.

## Гипотеза и критерии прототипа

Сначала проверяем три законченных урока на восьми целевых игроках: новые задания до и после обучения, повторная проверка через 48–72 часа. Пороги и решения при неуспехе определены в [COURSE_ROADMAP.md](COURSE_ROADMAP.md). До прохождения этого gate массовое производство курса не начинается.

Затем Free-beta проверяем на 30–50 целевых тестировщиках. Прототип считается перспективным, если:

- не менее 60% тестировщиков заканчивают первый урок;
- не менее 25% выполняют пять учебных сессий за первую неделю;
- удержание D7 не ниже 15%.

Направление и onboarding нужно пересмотреть, если первый урок заканчивают менее 40% пользователей или к третьей тренировке возвращаются менее 15%.

Эти показатели оценивают понятность и учебную ценность, а не финансовые результаты симуляции.

D7 означает учебную активность на седьмой день после первого занятия. Организованные тестовые заходы и самостоятельные возвращения учитываются отдельно. Длительность сессии — диагностическая метрика; основная цель — самостоятельное решение незнакомых задач и полезные возвращения.

## Полный учебный путь

Утверждённый план содержит 58 уроков: 26 бесплатных и 32 Pro. Итерации разработки и уроки — разные единицы.

| Доступ | Раздел | Уроков |
| --- | --- | ---: |
| Free | Необязательные вводные уроки | 4 |
| Free | Basic Strategy | 12 |
| Free | Math & Reality | 4 |
| Free | Hi-Lo и Running Count | 6 |
|  | **Всего Free** | **26** |
| Pro | Deck Estimation | 5 |
| Pro | True Count | 5 |
| Pro | Playing Deviations | 8 |
| Pro | Betting & Risk | 5 |
| Pro | Game Selection | 4 |
| Pro | Full-Shoe Certification | 5 |
|  | **Всего Pro** | **32** |
|  | **Всего** | **58** |

Текущий прототип содержит шесть исходных MCQ-уроков и три игровых пилотных
урока hard 12 / soft 18 / Hi-Lo cancellation. Остальной путь ещё не реализован.

## Формат обучения

- Обычная игровая сессия занимает ориентировочно 5–8 минут.
- Перед каждым уроком Тренер объясняет одну идею, показывает пример и важное исключение. Теория Free обычно занимает 45–90 секунд; длинные темы Pro разбиваются. Уже изученную теорию можно свернуть.
- Затем следуют 2–4 ознакомительных действия без оценки и 10 оцениваемых ситуаций: пять тренировочных и пять более самостоятельных.
- После ошибки Тренер объясняет выбранное неверное действие, выделяет существенный признак и даёт контрастный пример. Исправление после подсказки не заменяет первый ответ.
- Объяснения авторские и заранее проверенные; генеративный ИИ во время занятия не нужен.
- Таймер останавливается во время объяснений и при сворачивании приложения. В Exam подробный разбор выдаётся после завершения самостоятельной проверки.
- Quick Review занимает 3–5 минут и не блокирует основной путь.
- Диагностика внутри Learn рекомендует стартовую тему и позволяет пропустить вводные уроки; она не является сертификацией и не меняет общий onboarding.
- Интервальное повторение использует интервалы 1, 3, 7, 14 и 30 дней.
- Тренировочный стол доступен всегда, независимо от продвижения по пути.
- В продукте нет hearts, energy и leagues: ограничители вовлечения не должны мешать осознанной практике.
- Удержание строится на личных целях, звёздах, освоенных приёмах и исправлении ошибок. Пропуск дня не отнимает освоенный навык; количество попыток не ограничивается. Существующий streak продолжает работать по прежним правилам.

## Mastery и сертификация

Прогресс определяется точностью и воспроизводимостью навыка:

- обычный игровой урок завершён при результате не ниже 80% первых ответов; подсказки учитываются отдельно;
- освоение подтверждается новыми самостоятельными задачами и checkpoint, а не лучшим историческим процентом или XP;
- звёзды обычного урока соответствуют 8/10, 9/10, 10/10; высшая отметка требует самостоятельности;
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

Free включает путь до running count включительно и существующий стандартный стол. Pro — отдельное учебное дополнение. Lifetime unlock с ориентиром USD 7.99 и ID `pro_lifetime_v1` остаётся гипотезой для последующей интеграции покупок, а не текущим предложением оплаты. Интерес проверяется до производства всего Pro; законченный блок deck estimation + TC проходит отдельный gate.

Pro открывает:

- deck estimation и true count;
- Illustrious 18 и Fab 4;
- betting, bankroll и risk of ruin;
- проверенные rule profiles;
- учебные результаты внутри Learn и Full-Shoe Certification; переделка отдельного Progress в этот план не входит.

Insurance index входит в Pro deviations. Deck estimation, TC, deviations, betting spread, bankroll, risk of ruin и дополнительные rule profiles преподаются в Pro. Отсутствие гарантированного выигрыша объясняется уже в Free и подробнее разбирается через риск в Pro.

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

[Apple App Review Guideline 5.3.4](https://developer.apple.com/app-store/review/guidelines/) создаёт риск для приложений, которые могут рассматриваться как card-counter aids. При возвращении к публикации iOS нужно повторно проверить актуальные требования и честно описать автономную симуляцию. Нельзя скрывать функциональность от review. Android-first утверждён независимо от отложенной публикации iOS.

Допустимая маркетинговая формулировка: “find mathematical advantage in suitable conditions”. Недопустимая: “guaranteed beat casino”. Любые заявления о преимуществе должны сопровождаться условиями и объяснением риска.

## Локализация и контент

Текущий прототип уже содержит English и Russian UI и контент. Новые материалы сначала авторизуются на английском, затем переводятся и проверяются на русском; Free/Pro-beta требует EN/RU completeness. Новые языки не входят в текущий план.

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

Последовательность: три законченных игровых урока → целевой пилот → расширение Free → Free-beta → проверка интереса к Pro → проверенный Pro-фрагмент → дальнейший Pro. Полный порядок 70 итераций находится в [COURSE_ROADMAP.md](COURSE_ROADMAP.md).

На первые три урока и пилот выделяется ориентир 60–100 часов. При превышении сокращаются декор и универсальность инфраструктуры, но сохраняются теория, разбор ошибок и проверка обучения. Сроки полного курса пересчитываются по фактической стоимости урока и механики после пилота. Старый календарь 12–16 месяцев больше не является действующим обещанием. Free не ждёт завершения Pro, billing или iOS.

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

На 2026-09-05 в репозитории реализованы:

- шесть уроков и 54 оригинальных упражнения в English и Russian;
- три дополнительных игровых пилотных урока в Learn: EN/RU теория,
  два ознакомительных примера, пять тренировочных и пять самостоятельных
  задач на урок, разбор выбранной ошибки, исправление, сохранение и итог;
- one-deck Hi-Lo drill с контрольными точками;
- Quick Review до десяти просроченных или слабых упражнений;
- стандартный five-seat table с конфигурациями `Human`/`Bot`/`Empty`, режимами Guided/Practice, проверкой running count и пятираундовым summary;
- pure-Dart engines для карт, hands, shoe, Hi-Lo, basic strategy и раунда;
- локальный progress, review state и восстановление незавершённого урока;
- English/Russian UI-локализация и versioned locale content/glossary;
- fake purchase boundary, Firebase Analytics/Crashlytics adapters для Android/iOS, отдельные consent-aware boundaries и opt-in UI;
- scripted shoes, полный standard strategy fixture и сценарные domain/layout/widget tests.

README содержит ссылки на beta APK и unsigned IPA. В QA_SPRINT зафиксировано прохождение интеграционных маршрутов на Android API 24 и 36; это исторический отчёт, а не проверка будущих изменений. Наличие beta-артефактов не подтверждает production access в Google Play или App Store signing. Не реализованы новый игровой курс 26/32, реальные IAP и дополнительные rule profiles. Firebase-проект и SDK настроены; отправку событий после opt-in нужно подтверждать на целевой сборке и в Firebase Console.

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
