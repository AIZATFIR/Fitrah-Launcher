import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

  Future<List<InstalledApp>> getInstalledApps() async {
    if (kIsWeb || !Platform.isAndroid) {
      return _getDesktopOrWebApps();
    }

    try {
      final List<dynamic>? rawApps = await _channel.invokeMethod('getInstalledApps');
      if (rawApps == null) return _getDesktopOrWebApps();

      final List<InstalledApp> apps = [];
      for (final item in rawApps) {
        if (item is Map) {
          final name = (item['appName'] as String?)?.trim() ?? '';
          final pkg = (item['packageName'] as String?)?.trim() ?? '';
          final isSys = (item['isSystem'] as bool?) ?? false;

          if (name.isNotEmpty && pkg.isNotEmpty) {
            apps.add(InstalledApp(
              appName: name,
              packageName: pkg,
              isSystem: isSys,
            ));
          }
        }
      }

      apps.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
      return apps;
    } catch (e) {
      debugPrint('AppLauncherService getInstalledApps error: $e');
      return _getDesktopOrWebApps();
    }
  }

  Future<bool> launchApp(String packageName) async {
    if (kIsWeb || !Platform.isAndroid) {
      debugPrint('Simulated launch on desktop/web: $packageName');
      return true;
    }

    try {
      final bool? success = await _channel.invokeMethod('launchApp', {'packageName': packageName});
      return success ?? false;
    } catch (e) {
      debugPrint('AppLauncherService launchApp error: $e');
      return false;
    }
  }

  Future<void> openAppDetails(String packageName) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openAppDetails', {'packageName': packageName});
    } catch (e) {
      debugPrint('AppLauncherService openAppDetails error: $e');
    }
  }

  Future<void> openHomeSettings() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openHomeSettings');
    } catch (e) {
      debugPrint('AppLauncherService openHomeSettings error: $e');
    }
  }

  Future<void> openNotificationListenerSettings() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openNotificationListenerSettings');
    } catch (e) {
      debugPrint('AppLauncherService openNotificationListenerSettings error: $e');
    }
  }

  Future<void> launchDialer() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('launchDialer');
    } catch (e) {
      debugPrint('AppLauncherService launchDialer error: $e');
    }
  }

  Future<void> launchCamera() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('launchCamera');
    } catch (e) {
      debugPrint('AppLauncherService launchCamera error: $e');
    }
  }

  Future<void> uninstallApp(String packageName) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('uninstallApp', {'packageName': packageName});
    } catch (e) {
      debugPrint('AppLauncherService uninstallApp error: $e');
    }
  }

  final Map<String, Uint8List?> _iconCache = {};

  Future<Uint8List?> getAppIcon(String packageName) async {
    if (_iconCache.containsKey(packageName)) {
      return _iconCache[packageName];
    }
    if (kIsWeb || !Platform.isAndroid) return null;
    try {
      final dynamic raw = await _channel.invokeMethod('getAppIcon', {
        'packageName': packageName,
      });
      if (raw != null) {
        final bytes = raw as Uint8List;
        _iconCache[packageName] = bytes;
        return bytes;
      }
      _iconCache[packageName] = null;
      return null;
    } catch (e) {
      debugPrint('AppLauncherService getAppIcon error: $e');
      _iconCache[packageName] = null;
      return null;
    }
  }

  Future<void> expandNotificationsPanel() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('expandNotificationsPanel');
    } catch (e) {
      debugPrint('AppLauncherService expandNotificationsPanel error: $e');
    }
  }

  List<InstalledApp> _getDesktopOrWebApps() {
    return const [
      InstalledApp(appName: 'Browser', packageName: 'com.android.browser', isFavorite: true),
      InstalledApp(appName: 'Calculator', packageName: 'com.android.calculator2'),
      InstalledApp(appName: 'Calendar', packageName: 'com.android.calendar', isFavorite: true),
      InstalledApp(appName: 'Camera', packageName: 'com.android.camera', isFavorite: true),
      InstalledApp(appName: 'Clock', packageName: 'com.android.deskclock'),
      InstalledApp(appName: 'Contacts', packageName: 'com.android.contacts'),
      InstalledApp(appName: 'Email', packageName: 'com.android.email'),
      InstalledApp(appName: 'Files', packageName: 'com.android.documentsui'),
      InstalledApp(appName: 'Messages', packageName: 'com.android.mms', isFavorite: true),
      InstalledApp(appName: 'Notes', packageName: 'com.android.notes'),
      InstalledApp(appName: 'Phone', packageName: 'com.android.dialer', isFavorite: true),
      InstalledApp(appName: 'Settings', packageName: 'com.android.settings'),
      InstalledApp(appName: 'Terminal', packageName: 'com.termux'),
    ];
  }
}

final appLauncherServiceProvider = Provider<AppLauncherService>((ref) {
  return AppLauncherService();
});

final installedAppsFutureProvider = FutureProvider<List<InstalledApp>>((ref) async {
  final service = ref.watch(appLauncherServiceProvider);
  return service.getInstalledApps();
});

final favoritePackagesProvider = StateProvider<Set<String>>((ref) {
  return {
    'com.android.dialer',
    'com.android.mms',
    'com.android.browser',
    'com.android.camera',
  };
});

final appIconProvider = FutureProvider.family<Uint8List?, String>((ref, packageName) async {
  final service = ref.watch(appLauncherServiceProvider);
  return service.getAppIcon(packageName);
});
