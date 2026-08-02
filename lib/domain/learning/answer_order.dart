/// Stable answer presentation order derived from a locale-independent ID.
library;

List<int> deterministicAnswerOrder(String exerciseId, int optionCount) {
  if (optionCount < 0) {
    throw ArgumentError.value(
      optionCount,
      'optionCount',
      'Must not be negative',
    );
  }

  final order = List<int>.generate(optionCount, (index) => index);
  var state = _fnv1a32(exerciseId);
  for (var index = order.length - 1; index > 0; index--) {
    state = (1664525 * state + 1013904223) & 0xFFFFFFFF;
    final swapIndex = state % (index + 1);
    final current = order[index];
    order[index] = order[swapIndex];
    order[swapIndex] = current;
  }
  return List.unmodifiable(order);
}

int _fnv1a32(String value) {
  var hash = 0x811C9DC5;
  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}
