import 'package:blackjack_advantage_trainer/data/content_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'ru package loads and keeps the English lesson and exercise ids',
    () async {
      final repository = ContentRepository();
      final english = await repository.loadCatalog();
      final russian = await repository.loadCatalog(localeCode: 'ru');

      expect(_ids(russian), _ids(english));
      expect(_ids(english), isNotEmpty);
    },
  );

  test('unknown locale falls back to English instead of throwing', () async {
    final repository = ContentRepository();
    final fallback = await repository.loadCatalog(localeCode: 'xx');

    expect(_ids(fallback), _ids(await repository.loadCatalog()));
  });

  test('throws when even the fallback package is missing', () async {
    final repository = ContentRepository(bundle: _EmptyBundle());

    expect(repository.loadCatalog(), throwsStateError);
  });
}

List<String> _ids(Object catalog) {
  final dynamic c = catalog;
  return [
    for (final section in c.sections)
      for (final lesson in section.lessons) ...[
        lesson.id as String,
        for (final exercise in lesson.exercises) exercise.id as String,
      ],
  ];
}

class _EmptyBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => throw FlutterError('missing $key');
}
