import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitrah_launcher/data/store/live_model_codec.dart';
import 'package:fitrah_launcher/models/timer_session.dart';
import 'package:fitrah_launcher/models/app_settings.dart';
import '../tool/browser_storage/fixture.dart';

void roundtrip<T>(T value) {
  final encoded = LiveModelCodec.encode(value as Object);
  final decoded = LiveModelCodec.decode<T>(
    jsonDecode(jsonEncode(encoded)) as Map<String, dynamic>,
  );
  expect(LiveModelCodec.encode(decoded as Object), encoded);
  expect(identical(value, decoded), false);
}

void main() {
  test('all nine live model types preserve every writable field', () {
    final fixture = browserFixture();
    roundtrip(fixture.presets.single);
    roundtrip(fixture.activities.single);
    roundtrip(fixture.appSettings.single);
    roundtrip(fixture.tasks.single);
    roundtrip(fixture.habits.single);
    roundtrip(fixture.habitEntries.single);
    roundtrip(fixture.dailyReflections.single);
    roundtrip(fixture.timerSessions.single);
    roundtrip(fixture.intentDocuments.single);
    expect(
      (LiveModelCodec.encode(fixture.appSettings.single)['data'] as Map).length,
      27,
    );
  });
  test(
    'live configuration and raw running session are not portable-sanitized',
    () {
      final fixture = browserFixture();
      final timer = fixture.timerSessions.single
        ..sourceKindIndex = 999
        ..status = TimerStateStatus.running
        ..startedAt = DateTime.utc(2026, 11, 6, 23, 59, 59)
        ..runningSince = DateTime.utc(2026, 11, 7, 0, 0, 1)
        ..attributionLocalDate = '2026-11-06';
      roundtrip(timer);
      final settings = LiveModelCodec.decode<AppSettings>(
        jsonDecode(
              jsonEncode(LiveModelCodec.encode(fixture.appSettings.single)),
            )
            as Map<String, dynamic>,
      );
      expect(settings.aiApiKey, 'SYNTHETIC-NON-SECRET');
    },
  );
  test('corrupt records and unsafe IDs fail explicitly', () {
    final fixture = browserFixture();
    final encoded = LiveModelCodec.encode(fixture.timerSessions.single);
    expect(
      () => LiveModelCodec.decode<TimerSession>({...encoded, 'version': 2}),
      throwsFormatException,
    );
    final invalid = jsonDecode(jsonEncode(encoded)) as Map<String, dynamic>;
    invalid['data']['targetSeconds'] = '67';
    expect(
      () => LiveModelCodec.decode<TimerSession>(invalid),
      throwsFormatException,
    );
    expect(
      () => LiveModelCodec.validateId(9007199254740992),
      throwsFormatException,
    );
    invalid['data']['targetSeconds'] = 67;
    invalid['data']['id'] = 9007199254740992;
    expect(
      () => LiveModelCodec.decode<TimerSession>(invalid),
      throwsFormatException,
    );
  });
}
