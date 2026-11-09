import 'dart:async';
import 'dart:convert';
import 'package:fitrah_launcher/features/launcher/models/launcher_settings.dart';
import 'package:fitrah_launcher/features/launcher/providers/launcher_settings_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'launcher_daily_note_test.dart' show NoteStorage;

void main() {
  test('legacy JSON retains fields and explicit default policy', () {
    final legacy = LauncherSettings.fromMap({
      'focusGoal': 'keep',
      'themePalette': 'sky_blue',
    });
    expect(legacy.focusGoal, 'keep');
    expect(legacy.themePalette, 'sky_blue');
    expect(legacy.favoritePackages, LauncherSettings.defaultFavorites);
    expect(legacy.hiddenPackages, isEmpty);
  });
  test(
    'empty favorites, immutable collections, duplicates and unavailable IDs',
    () {
      final settings = LauncherSettings.fromMap({
        'favoritePackages': [],
        'hiddenPackages': ['org.unavailable.app', 'org.unavailable.app'],
      });
      expect(
        LauncherSettings.fromJson(settings.toJson()).favoritePackages,
        isEmpty,
      );
      expect(settings.hiddenPackages, {'org.unavailable.app'});
      expect(() => settings.hiddenPackages.clear(), throwsUnsupportedError);
      expect(
        () => settings.favoritePackages.add('org.app'),
        throwsUnsupportedError,
      );
      final source = {'org.app'};
      final owned = LauncherSettings(favoritePackages: source);
      source.clear();
      expect(owned.favoritePackages, {'org.app'});
    },
  );
  for (final key in ['favoritePackages', 'hiddenPackages']) {
    for (final invalid in [
      null,
      'org.app',
      5,
      [3],
      [''],
      ['org.bad-name'],
      [' org.app'],
      ['org..app'],
    ]) {
      test(
        'malformed $key $invalid fails visibly without overwriting',
        () async {
          final raw = jsonEncode({'focusGoal': 'keep', key: invalid});
          final store = NoteStorage()..raw = raw;
          final notifier = LauncherSettingsNotifier(store);
          await notifier.hydration;
          expect(notifier.isLoaded, isFalse);
          expect(notifier.loadFailed, isTrue);
          expect(await notifier.setHiddenPackage('org.app', true), isFalse);
          expect(await notifier.setFavoritePackage('org.app', true), isFalse);
          expect(store.raw, raw);
          notifier.dispose();
        },
      );
    }
  }
  test(
    'queue commits independent mutations and fresh hydration restores them',
    () async {
      final store = NoteStorage()
        ..raw = LauncherSettings(favoritePackages: {}).toJson();
      final notifier = LauncherSettingsNotifier(store);
      await notifier.hydration;
      store.gate = Completer<void>();
      final gate = store.gate!;
      final favorite = notifier.setFavoritePackage('org.unavailable.app', true);
      final hide = notifier.setHiddenPackage('org.unavailable.app', true);
      final palette = notifier.setThemePalette('sky_blue');
      final note = notifier.setDailyNote('2026-11-07', 'keep');
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.favoritePackages, isEmpty);
      gate.complete();
      expect(await favorite, isTrue);
      expect(await hide, isTrue);
      await palette;
      expect(await note, isTrue);
      final reopened = LauncherSettingsNotifier(store);
      await reopened.hydration;
      expect(reopened.state.favoritePackages, {'org.unavailable.app'});
      expect(reopened.state.hiddenPackages, {'org.unavailable.app'});
      expect(reopened.state.themePalette, 'sky_blue');
      expect(reopened.state.dailyNotes, {'2026-11-07': 'keep'});
      expect(
        await reopened.setFavoritePackage('org.unavailable.app', true),
        isTrue,
      );
      expect(
        await reopened.setHiddenPackage('org.unavailable.app', false),
        isTrue,
      );
      expect(reopened.state.favoritePackages, {'org.unavailable.app'});
      expect(reopened.state.hiddenPackages, isEmpty);
      notifier.dispose();
      reopened.dispose();
    },
  );
  test('failed reads and commits never publish; retry recovers', () async {
    final store = NoteStorage()
      ..raw = LauncherSettings(focusGoal: 'keep', favoritePackages: {}).toJson()
      ..failRead = true;
    final notifier = LauncherSettingsNotifier(store);
    expect(await notifier.setFavoritePackage('org.app', true), isFalse);
    store.failRead = false;
    store.failWrite = true;
    expect(await notifier.setHiddenPackage('org.app', true), isFalse);
    expect(notifier.state.hiddenPackages, isEmpty);
    expect(await notifier.setFavoritePackage('org.app', true), isFalse);
    expect(notifier.state.favoritePackages, isEmpty);
    store.failWrite = false;
    expect(await notifier.setHiddenPackage('org.app', true), isTrue);
    expect(await notifier.setFavoritePackage('org.app', true), isTrue);
    expect(notifier.state.focusGoal, 'keep');
    final before = store.raw;
    expect(await notifier.setHiddenPackage('bad package', true), isFalse);
    expect(store.raw, before);
    notifier.dispose();
  });
}
