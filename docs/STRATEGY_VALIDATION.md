# Независимая проверка доступности действий

## Soft 18: итерация 2, 2026-09-05

Профиль: `standard_6d_s17_das_ls_peek_3to2`. Это total-dependent basic strategy, без TC/deviations и без нового rule profile.

Независимый источник: [Wizard of Odds — 4-Deck to 8-Deck Blackjack Strategy](https://wizardofodds.com/games/blackjack/strategy/4-decks/), разделы Basic Strategy in Text, Double, Hit or Stand. Источник явно описывает S17 с surrender и порядок применения правил. Проверен 2026-09-05. Текст уроков и графика источника не копировались.

| Условие | Ожидаемое действие | Основание |
| --- | --- | --- |
| Soft 18 против 3, 4, 5, 6; Double доступен | Double | Применяется строка удвоения soft 17/18 |
| Soft 18 против 3, 4, 5, 6; доступны только Hit/Stand | Stand | После недоступного удвоения используется правило Hit/Stand для soft 18 |

`test/domain/strategy_engine_test.dart` проверяет все четыре dealer ranks: четыре случая доступного Double и двенадцать случаев без Double. Представления: A+7, A+2+5, A+A+6. Последнее защищает оценку нескольких тузов. Ожидаемые ответы записаны из внешнего правила, не вычислены production-движком.

До исправления все двенадцать Stand-проверок упали: фактический ответ был Hit. Четыре Double-проверки проходили. Исправление сохраняет preferred Double, а только для soft 18 без него возвращает Stand с существующим `unavailableActionFallback`. Другие double-or-hit totals не изменены.

`test/viewmodels/table_view_model_test.dart` воспроизводит реальную последовательность: A+2 против 6 → Hit → 5 → soft 18 с тремя картами → Stand. Double уже недоступен; Stand засчитывается как правильное решение. Исходный Hit оценивается отдельно и остаётся ошибкой стратегии. UI Table не меняется.

Граница доказательства: эти тесты не подтверждают произвольные rules, индексы, composition-dependent оптимальность или всю матрицу ограниченных действий. Полная базовая fixture и существующие engine/learning/UI тесты выполняются как регрессия. Матрица ограничений добавлена отдельно в итерации 3.

## Матрица ограничений действий: итерация 3, 2026-09-05

Профиль остаётся `standard_6d_s17_das_ls_peek_3to2`. Проверка не добавляет новый профиль, composition-dependent strategy или deviations.

Независимые источники:

- [Wizard of Odds — 4-Deck to 8-Deck Blackjack Strategy](https://wizardofodds.com/games/blackjack/strategy/4-decks/) задаёт порядок Surrender → Split → Double → Hit/Stand, S17-решения, DAS-строки пар и правило разыгрывать пару как hard total при недоступном повторном split;
- [Wizard of Odds — Blackjack rules](https://wizardofodds.com/games/blackjack/basics/) фиксирует Surrender только на первых двух картах, обычный Double после split при DAS, лимит до четырёх рук и одну карту для каждой split ace;
- [Wizard of Odds — Surrender](https://wizardofodds.com/games/blackjack/surrender/) отдельно подтверждает late surrender после проверки dealer blackjack и total-dependent решения для четырёх и более колод: hard 15 против 10, hard 16 против 9, 10 или A, но не 8+8 при доступном Split.

Все источники проверены 2026-09-05. Формулировки и графика не копировались. Ожидания независимо транскрибированы в `test/fixtures/standard_strategy_action_constraints.json`, production-код не используется как oracle.

Матрица содержит 25 состояний и проверяет:

- fallback всех семейств hard/soft Double на многокарточной руке, включая Stand для soft 18;
- Surrender на исходных hard 15/16 и Hit после того, как Surrender недоступен;
- Split 8+8 раньше Surrender, затем Surrender или Hit при недоступном Split;
- DAS-зависимые Split для 2+2, 4+4 и 6+6, а также fallback пар к hard total;
- отсутствие ложной обычной причины: если предпочтительное действие недоступно, возвращается `unavailableActionFallback`.

Сценарные engine-тесты дополнительно проверяют точные наборы legal actions для исходной, многокарточной и парной руки, запрет Surrender после split, Double после split при DAS и предел четырёх рук. Проверка DAS проходит через фактическую последовательность 4+4 → Split → 4+5 против 6 → Double.

Граница доказательства: текущий engine выдаёт split aces по одной карте и сразу завершает обе руки, поэтому состояние с решением после split aces не существует и явно исключено из fixture. Непроверенные сочетания rules, hit/resplit split aces и будущие учебные генераторы не активируются. Следующая работа по roadmap — карта навыков и материалов итерации 4.
