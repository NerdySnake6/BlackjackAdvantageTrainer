# Архитектура Blackjack Advantage Trainer

Статус документа: каноническое описание структуры и roadmap на 2026-08-02. Продуктовые решения находятся в [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md), локальная среда — в [DEVELOPMENT_SETUP.md](DEVELOPMENT_SETUP.md).

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
| `lib/data/` | **Реализовано.** Загрузка English content и локальное хранение прогресса. |
| `lib/core/` | **Реализовано.** Контракты persistence, consent-aware analytics и crash-reporting boundaries. |
| `lib/domain/blackjack_engine/` | **Реализовано.** Pure-Dart cards, hands, shoe, counting, strategy и round engine. |
| `lib/domain/learning/` | **Частично реализовано.** Content/progress models, session scoring и базовый review schedule. |
| `lib/domain/purchase/` | **Граница реализована.** Store API пока заменён `FakePurchaseGateway`. |
| `assets/content/en/` | **Реализовано для прототипа.** Versioned English lessons, glossary и manifest. |
| `lib/l10n/` | **Реализовано только для English.** ARB и generated localizations. |
| `test/` | **Реализовано для vertical slice.** Domain, content и widget tests. |

## Blackjack domain

### Реализовано

- `BlackjackEngine` управляет одной автономной раздачей, пятью местами, действиями игрока/ботов, dealer play, split и settlement.
- `Shoe` создаёт и перемешивает карты для `GameRulesProfile`, контролирует остаток и penetration; `Shoe.scripted` задаёт точную последовательность для сценарных тестов.
- `HandEvaluator` вычисляет total, soft/hard, bust и natural blackjack; состояние руки представляет `BlackjackHand`.
- `StrategyEngine` рекомендует действие для единственного проверенного standard profile, возвращает `StrategyRecommendation` с локализуемым `StrategyReason` и сохраняет совместимую обёртку `recommend()`.
- Полная таблица standard profile сверена с Wizard of Odds и независимо подтверждена публичной S17-таблицей Blackjack Apprenticeship 2026-09-02. Fixture хранит обе ссылки, дату и результат проверки; wording и графика источников не копировались.
- `CountingEngine` ведёт running count, оценивает оставшиеся колоды и делегирует true-count conversion политике.
- `TrueCountPolicy` — интерфейс политики округления; текущая `NearestWholeTrueCountPolicy` использует ближайшее целое. Поведение отрицательных значений должно оставаться явно протестированным.

Основные реализованные types: `PlayingCard`, `CardRank`, `CardSuit`, `HandEvaluation`, `BlackjackHand`, `GameRulesProfile`, `BlackjackPayout`, `SeatConfiguration`, `SeatRole`, `PlayerAction`, `RoundPhase`, `HandOutcome`, `PlayerHandState`, `TableSeat`, `StrategyRecommendation`, `StrategyReason`, `TableTrainingMode`, `TableDecisionAttempt` и `TableSessionSummary`.

В production `Shoe` по умолчанию использует `Random.secure()`. Тесты передают seeded `Random`, чтобы shoe и сценарий были воспроизводимыми. Любая новая случайность должна сохранять такой способ внедрения; нельзя делать математические тесты зависимыми от недетерминированной последовательности.

### Запланировано

- независимая экспертная проверка blackjack-специалистом перед платными математическими заявлениями;
- расширенные профили 1/2/6/8 decks, H17/S17, DAS, surrender и 3:2/6:5;
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

Стабильные `lessonId`, `skillId` и exercise IDs — ключи прогресса, а не переводимый текст. Их нельзя переименовывать после публикации.

## Repositories, services и внешние границы

### Реализовано

- `ContentRepository` загружает текущий English catalog из bundle assets.
- `ProgressRepository` задаёт контракт, а `LocalProgressRepository` сохраняет `ProgressSnapshot` в `shared_preferences`.
- `AnalyticsGateway` и `CrashReporterGateway` отделяют приложение от telemetry SDK; consent-aware decorators блокируют передачу до opt-in, Firebase adapters обслуживают Android/iOS, а NoOp implementations сохраняют работу неподключённых платформ.
- `PurchaseGateway` задаёт entitlement, purchase и restore operations.
- `FakePurchaseGateway` возвращает Free/unavailable и позволяет разрабатывать без магазина.
- `FeatureAccessPolicy` централизует проверку Pro entitlement.

### Запланировано

- locale-aware content и glossary repositories вместо жёсткого `loadEnglishCatalog()`;
- store adapters для App Store и Google Play, transaction verification и idempotent restore;
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
