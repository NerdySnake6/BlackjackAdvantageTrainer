/// Stable answer presentation order derived from a locale-independent ID.
library;

import 'models.dart';

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

/// Stable answer orders for a sequence without three identical correct slots.
List<List<int>> deterministicAnswerOrders(Iterable<LessonExercise> exercises) {
  final orders = <List<int>>[];
  int? previousCorrectPosition;
  var repeatedPositionCount = 0;

  for (final exercise in exercises) {
    final order = deterministicAnswerOrder(
      exercise.id,
      exercise.options.length,
    ).toList();
    var correctPosition = order.indexOf(exercise.correctIndex);

    if (correctPosition == previousCorrectPosition) {
      repeatedPositionCount++;
    } else {
      repeatedPositionCount = 1;
    }

    if (repeatedPositionCount >= 3 && order.length > 1) {
      final offset =
          1 + _fnv1a32('${exercise.id}:position') % (order.length - 1);
      final replacementPosition = (correctPosition + offset) % order.length;
      final replacedOption = order[replacementPosition];
      order[replacementPosition] = order[correctPosition];
      order[correctPosition] = replacedOption;
      correctPosition = replacementPosition;
      repeatedPositionCount = 1;
    }

    previousCorrectPosition = correctPosition;
    orders.add(List.unmodifiable(order));
  }

  return List.unmodifiable(orders);
}

int _fnv1a32(String value) {
  var hash = 0x811C9DC5;
  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}
