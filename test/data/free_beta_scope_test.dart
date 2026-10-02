import 'dart:convert';
import 'dart:io';

import 'package:blackjack_advantage_trainer/data/content_repository.dart';
import 'package:blackjack_advantage_trainer/domain/learning/mastery_check.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'all 26 planned Free learning units are available in EN/RU, including the existing checkpoint',
    () async {
      final plan =
          jsonDecode(File('docs/COURSE_SKILL_MAP.json').readAsStringSync())
              as Map;
      final planned = (plan['sections'] as List)
          .where((s) => s['access'] == 'free')
          .expand((s) => s['lessons'] as List)
          .map((l) => l['id'] as String)
          .toSet();
      expect(planned, hasLength(26));
      for (final locale in ['en', 'ru']) {
        final catalog = await ContentRepository().loadCatalog(
          localeCode: locale,
        );
        final playable = catalog.playableLessons.map((l) => l.id).toSet();
        expect(playable, hasLength(25));
        expect({...playable, 'basic-strategy-checkpoint'}, planned);
        expect(MasteryCheckBank.supports('mixed-basic-strategy'), isTrue);
        for (var form = 0; form < 2; form++) {
          expect(
            MasteryCheckBank.tasks('mixed-basic-strategy', form),
            hasLength(100),
          );
        }
      }
    },
  );
}
