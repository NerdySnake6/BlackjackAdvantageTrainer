// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Blackjack Advantage';

  @override
  String get learnTab => 'Обучение';

  @override
  String get drillTab => 'Тренажёр';

  @override
  String get tableTab => 'Стол';

  @override
  String get profileTab => 'Прогресс';

  @override
  String get learningPath => 'Путь обучения';

  @override
  String get learningPathSubtitle =>
      'Сначала доведите решения до автоматизма, затем наращивайте скорость.';

  @override
  String get prototypeBuild => 'Базовый курс: 6 уроков';

  @override
  String get experienceLevelTitle => 'С чего начнём?';

  @override
  String get experienceLevelSubtitle =>
      'Выберите начальную точку под ваш опыт в блэкджеке. Любой пройденный урок можно повторить в любой момент.';

  @override
  String get beginnerLevelTitle => 'Я новичок в блэкджеке';

  @override
  String get beginnerLevelDescription =>
      'Начните с правил, первой руки и основных решений за столом.';

  @override
  String get basicsLevelTitle => 'Я знаю основы';

  @override
  String get basicsLevelDescription =>
      'Пропустите введение и перейдите сразу к жёстким и мягким рукам.';

  @override
  String get experiencedLevelTitle => 'У меня есть опыт';

  @override
  String get experiencedLevelDescription =>
      'Сразу переходите к типовым решениям базовой стратегии, используя предыдущие уроки для повторения.';

  @override
  String get experienceLevelNote =>
      'Это изменит рекомендуемую точку старта, но не сбросит сохранённый прогресс.';

  @override
  String get telemetryConsentTitle => 'Помогите улучшить приложение';

  @override
  String get telemetryConsentBody =>
      'Выберите отдельно, хотите ли вы делиться анонимными данными об использовании и техническими отчётами о сбоях.';

  @override
  String get usageAnalyticsTitle => 'Аналитика использования';

  @override
  String get usageAnalyticsDescription =>
      'Отправка анонимных идентификаторов уроков, типов сессий и агрегированной точности. Тексты ответов и карты никогда не отправляются.';

  @override
  String get crashReportsTitle => 'Отчёты о сбоях';

  @override
  String get crashReportsDescription =>
      'Отправка технических отчётов о критических ошибках. Данные игрового процесса и личные профили не прикрепляются.';

  @override
  String get telemetryOptionalNote =>
      'Оба пункта опциональны. Отказ не ограничивает работу приложения, и настройки всегда можно изменить в разделе «Прогресс».';

  @override
  String get saveAndContinue => 'Сохранить и продолжить';

  @override
  String get recommendedStart => 'Начать здесь';

  @override
  String minutesShort(int minutes) {
    return '$minutes мин';
  }

  @override
  String get mastered => 'Освоено';

  @override
  String get inProgress => 'В процессе';

  @override
  String get freeLabel => 'БЕСПЛАТНО';

  @override
  String get proLabel => 'PRO';

  @override
  String get startLesson => 'Начать урок';

  @override
  String get continueLesson => 'Продолжить урок';

  @override
  String get lockedLesson => 'Завершите предыдущий урок, чтобы открыть';

  @override
  String get lessonComplete => 'Урок пройден';

  @override
  String get lessonCompleteSubtitle =>
      'Точность позволила открыть следующий шаг. Повторяйте материал, чтобы закрепить навык.';

  @override
  String get lessonNeedsReview => 'Урок завершён — требуется повторение';

  @override
  String get lessonNeedsReviewSubtitle =>
      'Наберите не менее 80% правильных ответов, чтобы открыть следующий урок.';

  @override
  String get retryLesson => 'Повторить попытку';

  @override
  String lessonResult(int correct, int total) {
    return '$correct из $total правильно';
  }

  @override
  String get correctAnswer => 'Верно';

  @override
  String get incorrectAnswer => 'Не совсем так';

  @override
  String get next => 'Далее';

  @override
  String get finish => 'Завершить';

  @override
  String get backToPath => 'К обучению';

  @override
  String get quickReviewTitle => 'Быстрое повторение';

  @override
  String get quickReviewReadyLater =>
      'Здесь появятся упражнения для повторения и закрепления слабых мест.';

  @override
  String quickReviewDue(int count) {
    return '$count упражнений готово к повторению · около 3–5 мин';
  }

  @override
  String quickReviewProgress(int current, int total) {
    return 'Повторение $current из $total';
  }

  @override
  String get quickReviewEmptyTitle => 'Пока нечего повторять';

  @override
  String get quickReviewEmptyBody =>
      'Пройдите несколько упражнений в уроках, а затем вернитесь для закрепления.';

  @override
  String get quickReviewComplete => 'Повторение завершено';

  @override
  String quickReviewResult(int correct, int total) {
    return '$correct из $total правильно. График повторений обновлён.';
  }

  @override
  String get countdownTitle => 'Текущий счёт';

  @override
  String get countdownSubtitle =>
      'Считайте по системе Hi-Lo по мере открытия каждой карты.';

  @override
  String get countDrillIntroTitle => 'Перед первым подсчётом';

  @override
  String get countDrillIntroBody =>
      'Система Hi-Lo отслеживает открытые карты в текущем башмаке. Начните с 0 и ведите один текущий счёт.';

  @override
  String get countDrillIntroLowCards => '2–6  →  +1';

  @override
  String get countDrillIntroNeutralCards => '7–9  →  0';

  @override
  String get countDrillIntroHighCards => '10, В, Д, К, Т  →  −1';

  @override
  String get countDrillIntroDeckNote =>
      'Все 52 карты полной колоды в сумме дают 0 по Hi-Lo. В многоколодном башмаке любые 52 карты — лишь смешанный сегмент: ведите счёт до перемешивания башмака.';

  @override
  String get countDrillIntroKnown => 'Я знаю правила — больше не показывать';

  @override
  String get countDrillIntroContinue => 'Понятно';

  @override
  String get startDrill => 'Начать тренировку (1 колода)';

  @override
  String get nextCard => 'Следующая карта';

  @override
  String get submitCount => 'Проверить счёт';

  @override
  String get yourCount => 'Ваш счёт';

  @override
  String cardsSeen(int count) {
    return 'Карт открыто: $count';
  }

  @override
  String get checkpoint => 'Контрольная точка';

  @override
  String get countCorrect => 'Счёт верный. Продолжайте.';

  @override
  String countIncorrect(int count) {
    return 'Точный счёт: $count.';
  }

  @override
  String get drillComplete => 'Колода завершена';

  @override
  String get drillCompleteSubtitle =>
      'Полная колода по Hi-Lo всегда возвращается в ноль.';

  @override
  String get restartDrill => 'Сдать ещё одну колоду';

  @override
  String get revealInstruction =>
      'Запомните счёт, затем откройте следующую карту.';

  @override
  String get adjustCountInstruction =>
      'Укажите текущий счёт, который вы насчитали.';

  @override
  String get newRound => 'Новый раунд';

  @override
  String get hit => 'Ещё';

  @override
  String get stand => 'Хватит';

  @override
  String get doubleAction => 'Дабл';

  @override
  String get split => 'Сплит';

  @override
  String get surrender => 'Сдаться';

  @override
  String get dealer => 'Дилер';

  @override
  String seat(int number) {
    return 'Бокс $number';
  }

  @override
  String get human => 'Игрок';

  @override
  String get bot => 'Бот';

  @override
  String get empty => 'Пусто';

  @override
  String get configureSeats => 'Настройка боксов';

  @override
  String get configureSeatsHint =>
      'Выберите Игрок, Бот или Пусто для каждого бокса. Изменения во время раунда вступят в силу со следующего раунда. Оставьте хотя бы одного игрока.';

  @override
  String get seatChangesPending =>
      'Изменения мест вступят в силу в следующем раунде.';

  @override
  String get done => 'Готово';

  @override
  String currentCount(int count) {
    return 'Текущий счёт: $count';
  }

  @override
  String shoeStatus(int dealt, int total) {
    return 'Сдано карт: $dealt / $total';
  }

  @override
  String get turnPrompt => 'Выберите оптимальное действие';

  @override
  String get roundComplete => 'Раунд завершён';

  @override
  String get startFirstRound => 'Сдать первый раунд';

  @override
  String get guidedMode => 'ОБУЧАЮЩИЙ СТОЛ';

  @override
  String get practiceMode => 'ПРАКТИЧЕСКИЙ СТОЛ';

  @override
  String get guidedModeName => 'Обучающий';

  @override
  String get practiceModeName => 'Практика';

  @override
  String tableRoundProgress(int completed, int total) {
    return 'Раунд $completed / $total';
  }

  @override
  String recommendedAction(String action) {
    return 'Рекомендовано: $action';
  }

  @override
  String get continueAction => 'Продолжить';

  @override
  String get tableCountPrompt => 'Какой сейчас текущий счёт?';

  @override
  String get tableSessionComplete => 'Сессия из пяти раундов завершена';

  @override
  String strategyAccuracy(int percent) {
    return 'Стратегия: $percent%';
  }

  @override
  String countAccuracy(int percent) {
    return 'Счёт: $percent%';
  }

  @override
  String get startAnotherSession => 'Ещё сессия';

  @override
  String get strategyReasonSplitPair =>
      'Сплит этой пары даёт наибольшее математическое преимущество на дистанции.';

  @override
  String get strategyReasonStandPair =>
      'Эту пару выгоднее оставить цельной против данной открытой карты дилера.';

  @override
  String get strategyReasonDoublePair =>
      'Разыгрывайте эти карты как жёсткие 10 и удваивайте против этой карты дилера.';

  @override
  String get strategyReasonHitPair =>
      'Эту пару выгоднее играть как обычную руку.';

  @override
  String get strategyReasonSurrenderHard =>
      'Поздняя сдача теряет меньше, чем розыгрыш этой слабой жёсткой руки.';

  @override
  String get strategyReasonDoubleSoft =>
      'Мягкая комбинация имеет достаточный потенциал для удвоения против этой карты дилера.';

  @override
  String get strategyReasonStandSoft =>
      'Эта мягкая комбинация уже достаточно сильна, чтобы остановиться.';

  @override
  String get strategyReasonHitSoft =>
      'Туз страхует руку от перебора, пока дополнительная карта может её усилить.';

  @override
  String get strategyReasonDoubleHard =>
      'Эта жёсткая сумма имеет преимущество против открытой карты дилера.';

  @override
  String get strategyReasonStandHard =>
      'У дилера высокая вероятность перебора; не берите лишнюю карту.';

  @override
  String get strategyReasonHitHard =>
      'Останавливаться здесь невыгодно; возьмите ещё карту.';

  @override
  String get strategyReasonFallback =>
      'Предпочтительное действие недоступно, используйте безопасную альтернативу по правилам.';

  @override
  String get standardRulesName =>
      'Стандартные правила: 6 колод · S17 · DAS · саррендер · 3:2';

  @override
  String get practiceUnits => 'Тренировочные фишки';

  @override
  String get dealingCards => 'Раздача карт...';

  @override
  String get dealerTurn => 'Дилер завершает раунд.';

  @override
  String get hiddenCard => 'Закрытая карта';

  @override
  String handTotal(int total) {
    return 'Очков: $total';
  }

  @override
  String resultUnits(String outcome, String units) {
    return '$outcome · $units фишек';
  }

  @override
  String get outcomeBlackjack => 'Блэкджек';

  @override
  String get outcomeWin => 'Победа';

  @override
  String get outcomePush => 'Ничья';

  @override
  String get outcomeLoss => 'Поражение';

  @override
  String get outcomeSurrender => 'Сдался';

  @override
  String get reshuffled => 'Башмак перемешан при 75% срезки.';

  @override
  String get progressTitle => 'Ваш прогресс';

  @override
  String get progressSubtitle =>
      'Мотивация и мастерство оцениваются раздельно.';

  @override
  String get xpLabel => 'XP';

  @override
  String get streakLabel => 'дн. подряд';

  @override
  String get masteryLabel => 'Точность в уроках';

  @override
  String get experienceSettingTitle => 'Уровень опыта';

  @override
  String get experienceSettingSubtitle =>
      'Измените рекомендуемую точку старта без сброса прогресса.';

  @override
  String lessonsCompleted(int completed, int total) {
    return '$completed из $total уроков пройдено';
  }

  @override
  String get privacyChoicesTitle => 'Конфиденциальность';

  @override
  String get privacyChoicesSubtitle =>
      'Сбор отключён, пока вы не включите его самостоятельно.';

  @override
  String get privacyNote =>
      'Телеметрия собирается только по вашему отдельному согласию. Тексты ответов, карты и личные данные не собираются.';

  @override
  String get educationDisclaimer =>
      'Только образовательный тренажёр. Навыки игры не гарантируют выигрыш в азартных играх.';

  @override
  String get proComingSoon => 'PRO-курс появится позже';

  @override
  String get settings => 'Настройки';

  @override
  String get resetProgress => 'Сбросить прогресс';

  @override
  String get resetConfirmation => 'Сбросить прогресс уроков и XP?';

  @override
  String get cancel => 'Отмена';

  @override
  String get reset => 'Сбросить';

  @override
  String get loadFailureTitle => 'Не удалось загрузить учебный контент';

  @override
  String get loadFailureBody =>
      'Перезапустите приложение. Если проблема не решится, переустановите приложение.';

  @override
  String get languageLabel => 'Язык';

  @override
  String get systemDefault => 'Как в системе';

  @override
  String get englishLanguage => 'English';

  @override
  String get russianLanguage => 'Русский';
}
