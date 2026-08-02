/// Supported blackjack rule profiles and table configuration types.
library;

enum BlackjackPayout {
  threeToTwo(1.5),
  sixToFive(1.2);

  const BlackjackPayout(this.profitUnits);

  final double profitUnits;
}

class GameRulesProfile {
  const GameRulesProfile({
    required this.id,
    required this.name,
    required this.deckCount,
    required this.blackjackPayout,
    required this.dealerHitsSoft17,
    required this.doubleAfterSplit,
    required this.lateSurrender,
    required this.dealerPeek,
    required this.penetration,
    this.maxSplitHands = 4,
  }) : assert(deckCount > 0),
       assert(penetration > 0 && penetration <= 1),
       assert(maxSplitHands > 0);

  static const standard = GameRulesProfile(
    id: 'standard_6d_s17_das_ls_peek_3to2',
    name: 'Standard 6D · S17 · DAS · LS · 3:2',
    deckCount: 6,
    blackjackPayout: BlackjackPayout.threeToTwo,
    dealerHitsSoft17: false,
    doubleAfterSplit: true,
    lateSurrender: true,
    dealerPeek: true,
    penetration: 0.75,
  );

  final String id;
  final String name;
  final int deckCount;
  final BlackjackPayout blackjackPayout;
  final bool dealerHitsSoft17;
  final bool doubleAfterSplit;
  final bool lateSurrender;
  final bool dealerPeek;
  final double penetration;
  final int maxSplitHands;
}

enum SeatRole { human, bot, empty }

class SeatConfiguration {
  SeatConfiguration(Iterable<SeatRole> roles)
    : roles = List<SeatRole>.unmodifiable(roles) {
    if (this.roles.length != 5) {
      throw ArgumentError.value(
        roles,
        'roles',
        'Exactly five seats are required.',
      );
    }
    if (!this.roles.contains(SeatRole.human)) {
      throw ArgumentError.value(
        roles,
        'roles',
        'At least one human seat is required.',
      );
    }
  }

  factory SeatConfiguration.standard() => SeatConfiguration([
    SeatRole.human,
    SeatRole.bot,
    SeatRole.bot,
    SeatRole.bot,
    SeatRole.bot,
  ]);

  final List<SeatRole> roles;
}

enum PlayerAction { hit, stand, doubleDown, split, surrender }

enum RoundPhase { waiting, playerTurn, dealerTurn, complete }

enum HandOutcome { blackjack, win, push, loss, surrender }
