# Архитектура Blackjack Advantage Trainer

Статус документа: каноническое описание текущей структуры и утверждённых границ изменений на 2026-09-05. Продуктовые решения находятся в [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md), последовательность работ — в [COURSE_ROADMAP.md](COURSE_ROADMAP.md), локальная среда — в [DEVELOPMENT_SETUP.md](DEVELOPMENT_SETUP.md).

## Принципы и направление зависимостей

Проект использует MVVM-подобное разделение:

```text
View (Flutter widgets)
        ↓
ViewModel / application state (ChangeNotifier)
        ↓
Repository / gateway / service contracts
        ↓
Pure-Dart domain and immutable/value types
```

View отвечает за отображение и пользовательский ввод. ViewModel готовит состояние и координирует сценарий. Repository или gateway изолирует хранение, assets, аналитику и store API. Domain содержит правила блэкджека, обучение и scoring.

Ключевой инвариант: `lib/domain/` — чистый Dart без импорта Flutter. Зависимости направлены внутрь; domain не знает о widgets, `BuildContext`, platform plugins или `shared_preferences`.

Текущая реализация использует:

- `provider` и `ChangeNotifier` для внедрения и наблюдаемого состояния;
- `go_router` для навигации;
- `shared_preferences` через `SharedPreferencesAsync` для локального прогресса;
- ARB и Flutter `gen-l10n` для UI-локализации;
- locale-specific JSON assets для учебного контента.

## Фактическая структура

| Путь | Статус и ответственность |
| --- | --- |
| `lib/presentation/` | **Реализовано.** Views для onboarding/consent, learning path, lesson, Quick Review, count drill, Guided/Practice table и progress. |
| `lib/viewmodels/` | **Реализовано.** `AppState`, `LessonViewModel`, `QuickReviewViewModel`, `CountDrillViewModel`, `TableViewModel`. |
| `lib/data/` | **Реализовано.** Загрузка locale-specific English/Russian content и локальное хранение прогресса. |
| `lib/core/` | **Реализовано.** Контракты persistence, consent-aware analytics и crash-reporting boundaries. |
| `lib/domain/blackjack_engine/` | **Реализовано.** Pure-Dart cards, hands, shoe, counting, strategy и round engine. |
| `lib/domain/learning/` | **Частично реализовано.** Content/progress models, session scoring и базовый review schedule. |
| `lib/domain/purchase/` | **Граница реализована.** Store API пока заменён `FakePurchaseGateway`. |
| `assets/content/en/`, `assets/content/ru/` | **Реализовано для прототипа.** Versioned lessons, glossary и manifest. |
| `lib/l10n/` | **Реализовано для English/Russian.** ARB и generated localizations. |
| `test/` | **Реализовано для vertical slice.** Domain, content и widget tests. |

## Blackjack domain

### Реализовано

- `BlackjackEngine` управляет одной автономной раздачей, пятью местами, действиями игрока/ботов, dealer play, split и settlement.
- `Shoe` создаёт и перемешивает карты для `GameRulesProfile`, контролирует остаток и penetration; `Shoe.scripted` задаёт точную последовательность для сценарных тестов.
- `HandEvaluator` вычисляет total, soft/hard, bust и natural blackjack; состояние руки представляет `BlackjackHand`.
- `StrategyEngine` рекомендует действие для единственного проверенного standard profile, возвращает `StrategyRecommendation` с локализуемым `StrategyReason` и сохраняет совместимую обёртку `recommend()`.
- Полная таблица standard profile сверена с Wizard of Odds и независимо подтверждена публичной S17-таблицей Blackjack Apprenticeship 2026-09-02. Fixture хранит обе ссылки, дату и результат проверки; wording и графика источников не копировались.
- Базовая fixture проверяет предпочтительные действия при полном наборе доступных действий. Дополнительная fixture ограничений фиксирует 25 независимо сверенных состояний: двух- и многокарточные руки, недоступные Double/Split/Surrender, приоритет Split над Surrender и DAS. Для каждого недоступного предпочтительного действия `StrategyEngine` возвращает корректный Hit/Stand/Surrender и `unavailableActionFallback`.
- `BlackjackEngine.availableActions` разрешает Double и Surrender только на первых двух картах, запрещает Surrender после split, сохраняет Double после split при DAS и ограничивает split четырьмя руками. Split aces получают ровно одну карту и автоматически завершаются; решение после них не генерируется. Непроверенные profiles и варианты hit/resplit split aces не входят в production или учебные генераторы.
- `docs/COURSE_SKILL_MAP.json` фиксирует карту всех 58 плановых уроков: prerequisite, skill, misconception, anchor example, source и transfer check. Это плановый слой, не новый runtime-каталог; полнота, порядок зависимостей и legacy IDs защищены `test/data/course_skill_map_test.dart`.
- `CountingEngine` ведёт running count, оценивает оставшиеся колоды и делегирует true-count conversion политике.
- `TrueCountPolicy` — интерфейс политики округления; текущая `NearestWholeTrueCountPolicy` использует ближайшее целое. Поведение отрицательных значений должно оставаться явно протестированным.

Основные реализованные types: `PlayingCard`, `CardRank`, `CardSuit`, `HandEvaluation`, `BlackjackHand`, `GameRulesProfile`, `BlackjackPayout`, `SeatConfiguration`, `SeatRole`, `PlayerAction`, `RoundPhase`, `HandOutcome`, `PlayerHandState`, `TableSeat`, `StrategyRecommendation`, `StrategyReason`, `TableTrainingMode`, `TableDecisionAttempt` и `TableSessionSummary`.

В production `Shoe` по умолчанию использует `Random.secure()`. Тесты передают seeded `Random`, чтобы shoe и сценарий были воспроизводимыми. Любая новая случайность должна сохранять такой способ внедрения; нельзя делать математические тесты зависимыми от недетерминированной последовательности.

### Запланировано

- независимая экспертная проверка blackjack-специалистом перед платными математическими заявлениями;
- первым дополнительным пакетом курса будет независимо проверенный 6D H17/DAS/LS/peek/3:2; другие комбинации правил не активируются автоматически;
- profile-specific restrictions для будущих проверенных профилей;
- deviations, включая I18/Fab4, только после математической валидации;
- отдельные session/report types для certification, deck estimation и full-shoe exams.

## Learning domain

### Реализовано

- `CourseCatalog`, `CourseSection`, `LessonDefinition` и `LessonExercise` загружают versioned content.
- `ExerciseAttempt`, `ExerciseReviewState`, `LessonSessionProgress`, consent state и `ProgressSnapshot` представляют результаты, resume, review и настройки telemetry.
- `SessionScorer` вычисляет точность и порог 80% для текущего урока.
- `ReviewScheduler` применяет интервалы 1/3/7/14/30 дней; ошибка сбрасывает серию и назначает следующий review через день.
- Quick Review выбирает до десяти просроченных или слабых упражнений по stable exercise ID.
- Ответы показываются в детерминированном порядке, вычисленном только по stable exercise ID, поэтому resume не меняет правильную позицию.
- `AppState` связывает каталог, progress repository, scoring, analytics и entitlement boundary.

### Запланировано

- `LessonEngine` для последовательности упражнений, branching и единых правил resume;
- `MasteryCalculator` для lesson, checkpoint, skill и certification mastery;
- дальнейшая настройка приоритетов очереди review на данных beta;
- `SessionScorer` для speed, accuracy, streaks ошибок и exam constraints, а не только доли правильных ответов;
- Placement Test и формальные migration policies для будущих `contentVersion`.

### Утверждённая граница игрового курса

Сначала три законченных урока на двух игровых сценах с явным состоянием сессии; универсальные runtime и генераторы расширяются после пользовательского gate. Learn получает теорию Тренера, игровые миссии, объяснения выбранных ошибок, первые/подсказанные ответы и отдельное освоение навыка. Публичные интерфейсы остальных разделов сохраняются.

Оценка игровой миссии использует фактическое число оцениваемых попыток, а не `LessonDefinition.exercises.length`. Адаптер сохраняет совместимые результаты для существующего Progress и экономику XP. Повторная обработка одной сессии не выдаёт награду повторно. Исторический лучший процент не подменяет самостоятельное освоение.

При миграции допускается однократный сброс несовместимых учебных scores/sessions/review states с объяснением пользователю; XP, streak, language, experience и consent сохраняются. Stable IDs не переименовываются. Сессия хранит версию контента, порядок/seed, текущую фазу и первые ответы, включая подсказки.

Quick Review сохраняет старый совместимый банк и существующий сценарий. Игровые и Pro-задания не добавляются туда автоматически. Повторение новых навыков и диагностика живут в Learn. Карта Learn должна поддержать несколько разделов вместо текущего `sections.first`.

Pro использует отдельную политику floor TC только с совместимым проверенным набором индексов. Текущая `NearestWholeTrueCountPolicy` других разделов не меняется. Пакет profile связывает правила, стратегию, индексы, provenance и тесты; непроверенный пакет нельзя активировать.

Комплексная учебная сессия переиспользует чистый blackjack engine, но не TableViewModel. Новый второй движок раздачи не создаётся. Объяснения авторские, заранее проверенные; runtime LLM и новые внешние сервисы для курса не нужны.

Стабильные `lessonId`, `skillId` и exercise IDs — ключи прогресса, а не переводимый текст. Их нельзя переименовывать после публикации.

## Repositories, services и внешние границы

### Реализовано

- `ContentRepository.loadCatalog(localeCode:)` загружает English/Russian catalog из bundle assets с English fallback для отсутствующего locale package.
- `ProgressRepository` задаёт контракт, а `LocalProgressRepository` сохраняет `ProgressSnapshot` в `shared_preferences`.
- `AnalyticsGateway` и `CrashReporterGateway` отделяют приложение от telemetry SDK; consent-aware decorators блокируют передачу до opt-in, Firebase adapters обслуживают Android/iOS, а NoOp implementations сохраняют работу неподключённых платформ.
- `PurchaseGateway` задаёт entitlement, purchase и restore operations.
- `FakePurchaseGateway` возвращает Free/unavailable и позволяет разрабатывать без магазина.
- `FeatureAccessPolicy` централизует проверку Pro entitlement.

### Запланировано

- typed validation для игровых locale packages и glossary;
- store adapters, transaction verification и idempotent restore — отдельный этап после учебного Pro, не реализация текущих 70 итераций;
- versioned repository migrations и резервное восстановление повреждённого progress;
- отдельные services для profile catalog, session history, statistics и certification.

## Контент, provenance и профили

Каждый locale package должен иметь manifest со следующими обязательными понятиями:

- `contentVersion` для миграций и совместимости;
- `locale` и `sourceLocale`;
- provenance математических решений и происхождение текста;
- license для каждого внешнего или собственного набора материалов;
- точный список поддержанных rule profiles;
- ссылки на lesson file и glossary.

Текущий `assets/content/en/manifest.json` уже хранит эти базовые поля и разрешает только `standard_6d_s17_das_ls_peek_3to2`. В roadmap manifest должен получить typed validation, completeness checks, hashes/versioning при необходимости и проверку, что урок не ссылается на неподдержанный профиль.

Нельзя копировать коммерческий учебный контент. Reference source подтверждает математику, но не становится источником wording или дизайна упражнения.

## iOS native dependency management

Текущий iOS-проект интегрирован через Swift Package Manager: Xcode project содержит локальный `FlutterGeneratedPluginSwiftPackage`, а shared scheme запускает Flutter prepare step. Открывать проект следует через `ios/Runner.xcworkspace`.

Для Flutter 3.44 SPM является основным путём. CocoaPods 1.17.0 установлен и рассматривается только как compatibility fallback для плагина или окружения, которое ещё не поддерживает SPM. Нельзя одновременно вручную подключать один и тот же native dependency двумя менеджерами.

## Как добавлять функциональность

1. Сначала определить domain types и инварианты без Flutter.
2. Добавить repository/service contract для platform или persistence boundary.
3. Реализовать ViewModel, не перенося UI state в domain.
4. Подключить View через `provider` и локализованные строки.
5. Добавить deterministic domain tests, widget tests и, по риску, integration/real-device checks.
6. Для математики приложить независимый provenance и reference validation.

Не создавать слой только ради названия. Новая абстракция нужна, когда отделяет изменяемую границу, делает сценарий тестируемым или предотвращает нарушение направления зависимостей.
