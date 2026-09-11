import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/secure_storage_service.dart';
import '../models/launcher_settings.dart';

class LauncherSettingsNotifier extends StateNotifier<LauncherSettings> {
  LauncherSettingsNotifier(this._storage) : super(const LauncherSettings()) {
    _loadSettings();
  }

  final SecureStorageService _storage;
  static const _storageKey = 'fitrah_launcher_settings_v1';

  Future<void> _loadSettings() async {
    try {
      final jsonStr = await _storage.readCustomKey(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        state = LauncherSettings.fromJson(jsonStr);
      }
    } catch (_) {
      // Keep default settings on error
    }
  }

  Future<void> _saveSettings() async {
    try {
      await _storage.writeCustomKey(_storageKey, state.toJson());
    } catch (_) {}
  }

  Future<void> updateSettings(LauncherSettings newSettings) async {
    state = newSettings;
    await _saveSettings();
  }

  Future<void> setWallpaperType(String type, {String? customUrl}) async {
    state = state.copyWith(
      wallpaperType: type,
      customImageUrl: customUrl ?? state.customImageUrl,
    );
    await _saveSettings();
  }

  Future<void> setWallpaperDimming(double dimming) async {
    state = state.copyWith(wallpaperDimming: dimming.clamp(0.0, 0.9));
    await _saveSettings();
  }

  Future<void> setWallpaperBlur(double blur) async {
    state = state.copyWith(wallpaperBlur: blur.clamp(0.0, 20.0));
    await _saveSettings();
  }

  Future<void> setClockFormat({bool? is24h, bool? showSeconds, bool? showDate}) async {
    state = state.copyWith(
      is24h: is24h ?? state.is24h,
      showSeconds: showSeconds ?? state.showSeconds,
      showDate: showDate ?? state.showDate,
    );
    await _saveSettings();
  }

  Future<void> toggleWidget({bool? showHero, bool? showAgenda, bool? showHabits}) async {
    state = state.copyWith(
      showHeroEvent: showHero ?? state.showHeroEvent,
      showAgendaWidget: showAgenda ?? state.showAgendaWidget,
      showHabitsWidget: showHabits ?? state.showHabitsWidget,
    );
    await _saveSettings();
  }

  Future<void> togglePrayerTimes(bool enabled) async {
    state = state.copyWith(showPrayerTimes: enabled);
    await _saveSettings();
  }

  Future<void> setPrayerTime(String prayerKey, String time) async {
    switch (prayerKey.toLowerCase()) {
      case 'subuh':
        state = state.copyWith(prayerSubuh: time);
        break;
      case 'syuruq':
        state = state.copyWith(prayerSyuruq: time);
        break;
      case 'dzuhur':
        state = state.copyWith(prayerDzuhur: time);
        break;
      case 'ashar':
        state = state.copyWith(prayerAshar: time);
        break;
      case 'maghrib':
        state = state.copyWith(prayerMaghrib: time);
        break;
      case 'isya':
        state = state.copyWith(prayerIsya: time);
        break;
    }
    await _saveSettings();
  }

  Future<void> setDockPackage(int slotIndex, String packageName) async {
    if (slotIndex < 0 || slotIndex >= 4) return;
    final updated = List<String>.from(state.dockPackages);
    while (updated.length < 4) {
      updated.add('com.android.browser');
    }
    updated[slotIndex] = packageName;
    state = state.copyWith(dockPackages: updated);
    await _saveSettings();
  }
}

final launcherSettingsProvider =
    StateNotifierProvider<LauncherSettingsNotifier, LauncherSettings>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  return LauncherSettingsNotifier(storage);
});
