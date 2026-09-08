// Independent reference: enumerate all ace assignments instead of using the
// production evaluator's running-sum algorithm. Rules reviewed 2026-09-08:
// https://wizardofodds.com/games/blackjack/basics/ (Rules 2, 3, 8).
(int, bool) referenceHand(List<String> ranks) {
  var choices = <(int, bool)>[(0, false)];
  for (final rank in ranks) {
    final values = rank == 'A' ? [1, 11] : [int.tryParse(rank) ?? 10];
    choices = [
      for (final previous in choices)
        for (final value in values)
          (previous.$1 + value, previous.$2 || value == 11),
    ];
  }
  final live = choices.where((entry) => entry.$1 <= 21).toList()
    ..sort((a, b) => b.$1.compareTo(a.$1));
  choices.sort((a, b) => a.$1.compareTo(b.$1));
  return live.isEmpty ? choices.first : live.first;
}
