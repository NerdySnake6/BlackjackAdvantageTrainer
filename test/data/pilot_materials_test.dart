import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pilot materials expose only the approved anonymized log schema', () {
    final recruitment = File('docs/PILOT_RECRUITMENT.md').readAsStringSync();
    final lines = File(
      'docs/PILOT_FEEDBACK_LOG.csv',
    ).readAsStringSync().trim().split('\n');

    expect(recruitment, contains('реальные участники ещё не набраны'));
    expect(recruitment, contains('исследование, analytics и crash reports'));
    expect(recruitment, contains('48–72 часа'));
    expect(recruitment, contains('16–20 Android-тестировщиков'));
    expect(lines, hasLength(1));
    expect(
      lines.single,
      'participant_code,cohort,session_type,session_number,started_at_utc,'
      'app_build,locale,device_model,android_version,research_consent,'
      'analytics_opt_in,crash_opt_in,completed,help_requests,'
      'first_answer_accuracy,hints_used,median_response_seconds,'
      'delayed_follow_up_due,format_preference,top_friction,bug_severity,'
      'issue_id,redacted_note,follow_up_status',
    );
    expect(lines.single.toLowerCase(), isNot(contains('email')));
    expect(lines.single.toLowerCase(), isNot(contains('phone')));
    expect(lines.single.toLowerCase(), isNot(contains('name')));
  });
}
