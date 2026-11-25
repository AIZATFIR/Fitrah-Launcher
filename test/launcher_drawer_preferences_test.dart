import 'dart:async';
import 'dart:convert';
import 'package:fitrah_launcher/features/launcher/models/launcher_settings.dart';
import 'package:fitrah_launcher/features/launcher/providers/launcher_settings_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'launcher_daily_note_test.dart' show NoteStorage;

void main() {
  test(
    'icon preference defaults true and exact boolean survives copies and JSON',
    () {
      expect(LauncherSettings.fromMap({}).showAppIcons, isTrue);
      for (final value in [false, true]) {
        final settings = LauncherSettings(
          showAppIcons: value,
        ).copyWith(focusGoal: 'keep');
        expect(settings.showAppIcons, value);
        expect(
          LauncherSettings.fromJson(settings.toJson()).showAppIcons,
          value,
        );
      }
    },
  );
  for (final invalid in [null, 'false', 0, []]) {
    test('invalid icon preference $invalid fails without overwrite', () async {
      final raw = jsonEncode({'showAppIcons': invalid});
      final store = NoteStorage()..raw = raw;
      final notifier = LauncherSettingsNotifier(store);
      await notifier.hydration;
      expect(notifier.loadFailed, isTrue);
      expect(await notifier.setShowAppIcons(false), isFalse);
      expect(await notifier.setAutoFocusSearch(true), isFalse);
      expect(store.raw, raw);
      notifier.dispose();
    });
  }
  test(
    'drawer saves commit before publish and retain independent queued mutations',
    () async {
      final store = NoteStorage();
      final notifier = LauncherSettingsNotifier(store);
      await notifier.hydration;
      final gate = Completer<void>();
      store.gate = gate;
      final icons = notifier.setShowAppIcons(false);
      final keyboard = notifier.setAutoFocusSearch(true);
      final note = notifier.setDailyNote('2026-11-09', 'keep');
      final favorite = notifier.setFavoritePackage('org.alpha', true);
      await Future<void>.delayed(Duration.zero);
      expect(notifier.drawerSaving, isTrue);
      expect(notifier.state.showAppIcons, isTrue);
      expect(notifier.state.autoFocusSearch, isFalse);
      gate.complete();
      expect(await icons, isTrue);
      expect(await keyboard, isTrue);
      expect(await note, isTrue);
      expect(await favorite, isTrue);
      final reopened = LauncherSettingsNotifier(store);
      await reopened.hydration;
      expect(reopened.state.showAppIcons, isFalse);
      expect(reopened.state.autoFocusSearch, isTrue);
      expect(reopened.state.dailyNotes['2026-11-09'], 'keep');
      expect(reopened.state.favoritePackages, contains('org.alpha'));
      store.failWrite = true;
      expect(await notifier.setShowAppIcons(true), isFalse);
      expect(notifier.state.showAppIcons, isFalse);
      expect(notifier.drawerFailedValues['icons'], isTrue);
      store.failWrite = false;
      expect(await notifier.setShowAppIcons(true), isTrue);
      expect(notifier.drawerFailedValues, isEmpty);
      reopened.dispose();
      notifier.dispose();
    },
  );

  test(
    'keyboard failure preserves committed value and a later success clears retry',
    () async {
      final store = NoteStorage();
      final notifier = LauncherSettingsNotifier(store);
      await notifier.hydration;
      store.failWrite = true;
      expect(await notifier.setAutoFocusSearch(true), isFalse);
      expect(notifier.state.autoFocusSearch, isFalse);
      expect(notifier.drawerFailedValues['keyboard'], isTrue);
      store.failWrite = false;
      expect(await notifier.setAutoFocusSearch(true), isTrue);
      expect(notifier.state.autoFocusSearch, isTrue);
      expect(notifier.drawerFailedValues, isEmpty);
      final reopened = LauncherSettingsNotifier(store);
      await reopened.hydration;
      expect(reopened.state.autoFocusSearch, isTrue);
      reopened.dispose();
      notifier.dispose();
    },
  );

  test('legacy JSON retains fields and explicit default policy', () {
    final legacy = LauncherSettings.fromMap({
      'focusGoal': 'keep',
      'themePalette': 'sky_blue',
    });
    expect(legacy.focusGoal, 'keep');
    expect(legacy.themePalette, 'sky_blue');
    expect(legacy.favoritePackages, LauncherSettings.defaultFavorites);
    expect(legacy.hiddenPackages, isEmpty);
    expect(legacy.widgetDisplayMode, 'focus_clock');
  });

  test(
    'legacy prayer times are not assumed verified for the device location',
    () {
      final legacy = LauncherSettings.fromMap({
        'showPrayerTimes': true,
        'widgetDisplayMode': 'prayer',
        'prayerDzuhur': '11:52',
      });

      expect(legacy.toMap()['prayerTimesVerified'], isFalse);
      expect(
        LauncherSettings.fromMap({
          ...legacy.toMap(),
          'prayerTimesVerified': true,
        }).toMap()['prayerTimesVerified'],
        isTrue,
      );
    },
  );
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
      expect(await palette, isTrue);
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
