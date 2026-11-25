import 'dart:async';

import 'package:fitrah_launcher/features/launcher/models/launcher_settings.dart';
import 'package:fitrah_launcher/features/launcher/providers/launcher_settings_provider.dart';
import 'package:fitrah_launcher/services/secure_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

class NoteStorage extends SecureStorageService {
  String? raw;
  bool failRead = false;
  bool failWrite = false;
  Completer<void>? gate;

  @override
  Future<String?> readCustomKey(String key) async {
    if (failRead) throw StateError('read');
    return raw;
  }

  @override
  Future<void> writeCustomKey(String key, String value) async {
    final wait = gate;
    gate = null;
    if (wait != null) await wait.future;
    if (failWrite) throw StateError('write');
    raw = value;
  }
}

void main() {
  test('notes persist by date and concurrent updates serialize', () async {
    final store = NoteStorage();
    final notifier = LauncherSettingsNotifier(store);
    final gate = Completer<void>();
    store.gate = gate;
    final first = notifier.setDailyNote('2026-11-07', 'first');
    final palette = notifier.setThemePalette('sky_blue');
    final second = notifier.setDailyNote('2026-11-08', 'second');
    gate.complete();
    expect(await first, isTrue);
    expect(await palette, isTrue);
    expect(await second, isTrue);
    final saved = LauncherSettings.fromJson(store.raw!);
    expect(saved.dailyNotes, {'2026-11-07': 'first', '2026-11-08': 'second'});
    expect(saved.themePalette, 'sky_blue');
    final reopened = LauncherSettingsNotifier(store);
    await reopened.reload();
    expect(reopened.state.dailyNotes, saved.dailyNotes);
  });

  test(
    'failed reads do not write defaults and failed drafts can retry',
    () async {
      final store = NoteStorage()
        ..raw = LauncherSettings(focusGoal: 'keep').toJson()
        ..failRead = true;
      final notifier = LauncherSettingsNotifier(store);
      expect(await notifier.setDailyNote('2026-11-07', 'draft'), isFalse);
      expect(LauncherSettings.fromJson(store.raw!).focusGoal, 'keep');
      expect(notifier.noteDrafts['2026-11-07'], 'draft');
      store.failRead = false;
      store.failWrite = true;
      expect(await notifier.setDailyNote('2026-11-07', 'draft'), isFalse);
      store.failWrite = false;
      expect(await notifier.setDailyNote('2026-11-07', 'draft'), isTrue);
      expect(LauncherSettings.fromJson(store.raw!).focusGoal, 'keep');
      expect(
        LauncherSettings.fromJson(store.raw!).dailyNotes['2026-11-07'],
        'draft',
      );
      expect(notifier.noteDrafts, isEmpty);
    },
  );

  test(
    'restore runs between queued writes and preserves a failed draft',
    () async {
      final store = NoteStorage();
      final notifier = LauncherSettingsNotifier(store);
      store.failWrite = true;
      expect(await notifier.setDailyNote('2026-11-07', 'draft'), isFalse);
      store.failWrite = false;
      final gate = Completer<void>();
      final started = Completer<void>();
      final restoring = notifier.restoreWithReload(() async {
        started.complete();
        await gate.future;
        store.raw = LauncherSettings(focusGoal: 'restored').toJson();
      });
      await started.future;
      final saving = notifier.setDailyNote('2026-11-08', 'new day');
      gate.complete();
      await restoring;
      expect(await saving, isTrue);
      expect(LauncherSettings.fromJson(store.raw!).focusGoal, 'restored');
      expect(notifier.noteDrafts['2026-11-07'], 'draft');
    },
  );

  test('export waits for pending writes and rejects failed drafts', () async {
    final store = NoteStorage();
    final notifier = LauncherSettingsNotifier(store);
    final gate = Completer<void>();
    store.gate = gate;
    final saving = notifier.setDailyNote('2026-11-07', 'pending');
    final exported = notifier.exportAfterWrites(() async => store.raw!);
    gate.complete();
    expect(await saving, isTrue);
    expect(
      LauncherSettings.fromJson(await exported).dailyNotes['2026-11-07'],
      'pending',
    );
    store.failWrite = true;
    expect(await notifier.setDailyNote('2026-11-07', 'failed'), isFalse);
    var called = false;
    await expectLater(
      notifier.exportAfterWrites(() async {
        called = true;
      }),
      throwsStateError,
    );
    expect(called, isFalse);
  });

  test('settings own their note map', () {
    final source = {'2026-11-07': 'original'};
    final settings = LauncherSettings(dailyNotes: source);
    source.clear();
    expect(settings.dailyNotes['2026-11-07'], 'original');
    expect(() => settings.dailyNotes.clear(), throwsUnsupportedError);
  });
}
