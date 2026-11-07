import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/secure_storage_service.dart';
import '../models/launcher_settings.dart';

class LauncherSettingsNotifier extends StateNotifier<LauncherSettings> {
  LauncherSettingsNotifier(this._storage) : super(LauncherSettings()) {
    _loadSettings();
  }

  final SecureStorageService _storage;
  static const _storageKey = 'fitrah_launcher_settings_v1';
  Future<void> _queue = Future.value();
  bool _loaded = false;
  bool get isLoaded => _loaded;
  bool get loadFailed => !_loaded && _loadAttempted;
  bool _loadAttempted = false;
  final Map<String, String> noteDrafts = {};
  final Map<String, bool> noteSaving = {};
  final Map<String, int> _noteRevisions = {};

  Future<bool> _readSettings() async {
    try {
      final raw = await _storage.readCustomKey(_storageKey);
      final loaded = raw == null || raw.isEmpty
          ? LauncherSettings()
          : LauncherSettings.fromJson(raw);
      _loaded = true;
      _loadAttempted = true;
      state = loaded;
      return true;
    } catch (_) {
      _loaded = false;
      _loadAttempted = true;
      state = state.copyWith();
      return false;
    }
  }

  Future<void> _loadSettings() async {
    await _enqueue(() async {
      await _readSettings();
    });
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final result = _queue.then((_) => operation());
    _queue = result.catchError((_) {});
    return result;
  }

  Future<void> reload() => _enqueue(() async {
    await _readSettings();
  });

  Future<T> exportAfterWrites<T>(Future<T> Function() export) async {
    late T result;
    await _enqueue(() async {
      if ((!_loaded && !await _readSettings()) || noteDrafts.isNotEmpty) {
        throw StateError(
          'Catatan belum tersimpan. Coba simpan lagi sebelum export.',
        );
      }
      result = await export();
    });
    return result;
  }

  Future<T> restoreWithReload<T>(Future<T> Function() restore) async {
    late T result;
    await _enqueue(() async {
      if (!_loaded && !await _readSettings()) {
        throw StateError('Unable to read launcher settings');
      }
      result = await restore();
      if (!await _readSettings()) {
        throw StateError('Unable to reload launcher settings');
      }
    });
    return result;
  }

  Future<bool> _mutate(
    LauncherSettings Function(LauncherSettings) change, {
    void Function()? onSaved,
    void Function()? onFailed,
  }) async {
    var success = false;
    await _enqueue(() async {
      if (!_loaded && !await _readSettings()) {
        onFailed?.call();
        if (onFailed != null) state = state.copyWith();
        return;
      }
      final updated = change(state);
      try {
        await _storage.writeCustomKey(_storageKey, updated.toJson());
        onSaved?.call();
        state = updated;
        success = true;
      } catch (_) {
        onFailed?.call();
        if (onFailed != null) state = state.copyWith();
      }
    });
    return success;
  }

  Future<void> updateSettings(LauncherSettings value) async {
    await _mutate((_) => value);
  }

  Future<void> setWallpaperType(String type, {String? customUrl}) async {
    await _mutate(
      (s) => s.copyWith(wallpaperType: type, customImageUrl: customUrl),
    );
  }

  Future<void> setWallpaperDimming(double value) async {
    await _mutate((s) => s.copyWith(wallpaperDimming: value.clamp(0.0, 0.9)));
  }

  Future<void> setWallpaperBlur(double value) async {
    await _mutate((s) => s.copyWith(wallpaperBlur: value.clamp(0.0, 20.0)));
  }

  Future<void> setClockFormat({
    bool? is24h,
    bool? showSeconds,
    bool? showDate,
  }) async {
    await _mutate(
      (s) => s.copyWith(
        is24h: is24h,
        showSeconds: showSeconds,
        showDate: showDate,
      ),
    );
  }

  Future<void> toggleWidget({
    bool? showHero,
    bool? showAgenda,
    bool? showHabits,
  }) async {
    await _mutate(
      (s) => s.copyWith(
        showHeroEvent: showHero,
        showAgendaWidget: showAgenda,
        showHabitsWidget: showHabits,
      ),
    );
  }

  Future<void> togglePrayerTimes(bool enabled) async {
    await _mutate((s) => s.copyWith(showPrayerTimes: enabled));
  }

  Future<void> setPrayerTime(String key, String time) async {
    await _mutate((s) {
      switch (key.toLowerCase()) {
        case 'subuh':
          return s.copyWith(prayerSubuh: time);
        case 'syuruq':
          return s.copyWith(prayerSyuruq: time);
        case 'dzuhur':
          return s.copyWith(prayerDzuhur: time);
        case 'ashar':
          return s.copyWith(prayerAshar: time);
        case 'maghrib':
          return s.copyWith(prayerMaghrib: time);
        case 'isya':
          return s.copyWith(prayerIsya: time);
        default:
          return s;
      }
    });
  }

  Future<void> setDockPackage(int slotIndex, String packageName) async {
    if (slotIndex < 0 || slotIndex >= 4) return;
    await _mutate((s) {
      final updated = List<String>.from(s.dockPackages);
      while (updated.length < 4) {
        updated.add('com.android.browser');
      }
      updated[slotIndex] = packageName;
      return s.copyWith(dockPackages: updated);
    });
  }

  Future<void> setWidgetDisplayMode(String mode) async {
    await _mutate((s) => s.copyWith(widgetDisplayMode: mode));
  }

  Future<void> setAutoFocusSearch(bool enabled) async {
    await _mutate((s) => s.copyWith(autoFocusSearch: enabled));
  }

  Future<void> setThemePalette(String palette) async {
    await _mutate((s) => s.copyWith(themePalette: palette));
  }

  Future<bool> setFocusGoal(String goal) =>
      _mutate((s) => s.copyWith(focusGoal: goal.trim()));

  Future<bool> setDailyNote(String date, String value) async {
    final revision = (_noteRevisions[date] ?? 0) + 1;
    _noteRevisions[date] = revision;
    noteDrafts[date] = value;
    noteSaving[date] = true;
    state = state.copyWith();
    return _mutate(
      (s) => s.copyWith(dailyNotes: {...s.dailyNotes, date: value}),
      onSaved: () {
        if (_noteRevisions[date] == revision) {
          noteDrafts.remove(date);
          noteSaving.remove(date);
        }
      },
      onFailed: () {
        if (_noteRevisions[date] == revision) noteSaving[date] = false;
      },
    );
  }
}

final launcherSettingsProvider =
    StateNotifierProvider<LauncherSettingsNotifier, LauncherSettings>((ref) {
      final storage = ref.watch(secureStorageServiceProvider);
      return LauncherSettingsNotifier(storage);
    });
