import '../providers/launcher_settings_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InstalledApp {
  final String appName;
  final String packageName;
  final bool isSystem;
  final bool isFavorite;

  const InstalledApp({
    required this.appName,
    required this.packageName,
    this.isSystem = false,
    this.isFavorite = false,
  });

  InstalledApp copyWith({
    String? appName,
    String? packageName,
    bool? isSystem,
    bool? isFavorite,
  }) {
    return InstalledApp(
      appName: appName ?? this.appName,
      packageName: packageName ?? this.packageName,
      isSystem: isSystem ?? this.isSystem,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  String get firstLetter {
    if (appName.isEmpty) return '#';
    final char = appName[0].toUpperCase();
    if (RegExp(r'[A-Z]').hasMatch(char)) return char;
    return '#';
  }
}

class AppLauncherService {
  static const MethodChannel _channel = MethodChannel('fitrah_launcher/apps');

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<List<InstalledApp>> getInstalledApps() async {
    if (!isSupported) {
      throw UnsupportedError('Android app capabilities unavailable');
    }

    final rawApps = await _channel.invokeMethod<Object?>('getInstalledApps');
    if (rawApps is! List) {
      throw const FormatException('Invalid installed app list');
    }
    final apps = <String, InstalledApp>{};
    for (final item in rawApps) {
      if (item is! Map ||
          item['appName'] is! String ||
          (item['appName'] as String).trim().isEmpty ||
          item['packageName'] is! String ||
          (item['packageName'] as String).trim().isEmpty ||
          (item['isSystem'] != null && item['isSystem'] is! bool)) {
        throw const FormatException('Invalid installed app');
      }
      final package = (item['packageName'] as String).trim();
      apps.putIfAbsent(
        package,
        () => InstalledApp(
          appName: item['appName'] as String,
          packageName: package,
          isSystem: item['isSystem'] as bool? ?? false,
        ),
      );
    }
    return apps.values.toList()..sort(
      (a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()),
    );
  }

  // A true result means Android accepted dispatch, not that the destination opened.
  Future<bool> _invokeAction(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<Object?>(method, arguments) == true;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> launchApp(String packageName) =>
      _invokeAction('launchApp', {'packageName': packageName});

  Future<bool> launchSadar() => launchApp('com.aizatfir.sadar');

  Future<bool> launchFocusClock() => launchApp('com.aizatfir.focusclock');

  Future<bool> openAppDetails(String packageName) =>
      _invokeAction('openAppDetails', {'packageName': packageName});

  Future<bool> openHomeSettings() => _invokeAction('openHomeSettings');

  Future<bool> openNotificationListenerSettings() =>
      _invokeAction('openNotificationListenerSettings');

  Future<bool> launchClock() => _invokeAction('launchClock');

  Future<bool> launchCalendar() => _invokeAction('launchCalendar');

  Future<bool> launchDialer() => _invokeAction('launchDialer');

  Future<bool> launchCamera() => _invokeAction('launchCamera');

  Future<bool> uninstallApp(String packageName) =>
      _invokeAction('uninstallApp', {'packageName': packageName});

  Future<bool> expandNotificationsPanel() =>
      _invokeAction('expandNotificationsPanel');

  void clearIconCache() {
    _iconGeneration++;
    _iconCache.clear();
  }

  int _iconGeneration = 0;

  final Map<String, Uint8List?> _iconCache = {};

  Future<Uint8List?> getAppIcon(String packageName) async {
    if (_iconCache.containsKey(packageName)) {
      return _iconCache[packageName];
    }
    if (!isSupported) return null;
    final generation = _iconGeneration;
    try {
      final dynamic raw = await _channel.invokeMethod('getAppIcon', {
        'packageName': packageName,
      });
      if (raw != null) {
        final bytes = raw as Uint8List;
        if (generation == _iconGeneration) _iconCache[packageName] = bytes;
        return bytes;
      }
      return null;
    } catch (e) {
      debugPrint('AppLauncherService getAppIcon error: $e');
      return null;
    }
  }
}

final appLauncherServiceProvider = Provider<AppLauncherService>((ref) {
  return AppLauncherService();
});

final installedAppsFutureProvider = FutureProvider<List<InstalledApp>>((
  ref,
) async {
  final service = ref.watch(appLauncherServiceProvider);
  final listener = AppLifecycleListener(onResume: ref.invalidateSelf);
  ref.onDispose(listener.dispose);
  service.clearIconCache();
  return service.getInstalledApps();
});

final favoritePackagesProvider = Provider<Set<String>>(
  (ref) => ref.watch(launcherSettingsProvider).favoritePackages,
);

final hiddenPackagesProvider = Provider<Set<String>>(
  (ref) => ref.watch(launcherSettingsProvider).hiddenPackages,
);

final appIconProvider = FutureProvider.family<Uint8List?, String>((
  ref,
  packageName,
) async {
  ref.watch(installedAppsFutureProvider);
  final service = ref.watch(appLauncherServiceProvider);
  return service.getAppIcon(packageName);
});
