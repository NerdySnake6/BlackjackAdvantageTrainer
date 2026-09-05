# Карта навыков и материалов курса

Статус: утверждённая карта итерации 4, а не опубликованный учебный контент.
Машиночитаемый источник — [COURSE_SKILL_MAP.json](COURSE_SKILL_MAP.json). Он
описывает полный план из 26 Free и 32 Pro уроков, но новые уроки не появляются
в приложении до своей итерации реализации и проверки. В итерации 9 активированы
три зарезервированные пары: `hard-12` / `strategy.hard_12`,
`soft-18` / `strategy.soft_18`, `hi-lo-cancellation` /
`counting.cancellation`. Они хранятся отдельно от старого MCQ-банка.

## Поля карты

Каждый урок содержит:

- `id` и `skillId` — стабильные ключи; шесть уже опубликованных пар совпадают с
  `assets/content/en/lessons.json` и `assets/content/ru/lessons.json`;
- `prerequisiteLessonIds` и `placementMayBypass` — учебные зависимости, а не
  обещание конкретного UI-lock; диагностика может разрешить опытному игроку
  пропустить вводные темы;
- `outcome`, `misconceptions`, `anchorExample` — конкретный результат,
  заблуждения для coaching и один короткий пример;
- `sourceRefs` — математическое или продуктовое основание из реестра источников;
  `solver-review-gate` и `expert-review-gate` запрещают считать будущие Pro
  числа проверенными заранее;
- `transferCheck` — новая задача/серия, на которой проверяется перенос, а не
  воспроизведение anchor-примера.

## Разбиение

| Доступ | Раздел | Уроков | Последовательность |
| --- | --- | ---: | --- |
| Free | Foundations | 4 | quick-start → card-values → hard-and-soft → player-actions |
| Free | Basic Strategy | 12 | first-strategy → ... → basic-strategy-checkpoint |
| Free | Math & Reality | 4 | house-edge-reality → expected-value → variance → advantage-play-conditions |
| Free | Hi-Lo / Running Count | 6 | hi-lo-intro → ... → running-count-speed |
| Pro | Deck Estimation | 5 | concept → whole → half → quarter → checkpoint |
| Pro | True Count | 5 | concept → positive → negative → speed → checkpoint |
| Pro | Playing Deviations | 8 | baseline → stand/hit → double → split → insurance → surrender → checkpoint |
| Pro | Betting & Risk | 5 | edge/units → spreads → downswings → bankroll → risk of ruin |
| Pro | Game Selection | 4 | rule impact → penetration → conditions → checkpoint |
| Pro | Full-Shoe Certification | 5 | guided → practice → pressure → exam → certification |

## Границы проверки

Источники в карте нужны для направления будущей работы, а не для копирования
текста, таблиц или упражнений. Basic strategy и action constraints уже имеют
reference fixtures в `test/fixtures/`; для deck estimation, TC, deviations и
risk production-утверждения блокируются до независимого solver comparison и
review специалистом по математике блэкджека. Insurance, I18 и Fab 4 не получают
числовых индексов из этой карты.

`test/data/course_skill_map_test.dart` проверяет JSON-синтаксис, 58 уникальных
lesson/skill IDs, баланс 26/32, обязательные поля, существование ссылок на
реестр источников, порядок prerequisites и неизменность шести legacy IDs.

Следующий шаг — итерация 5: реальные материалы набора участников и журнал
отзывов; карта не заменяет поиск и согласие реальных тестировщиков.
