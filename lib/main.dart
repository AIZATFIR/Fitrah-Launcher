import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'data/store/focus_store.dart';
import 'data/store/store_factory.dart';
import 'data/storage_unavailable_app.dart';
import 'features/launcher/fitrah_launcher_shell.dart';
import 'features/launcher/providers/launcher_settings_provider.dart';
import 'providers/providers.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  late final FocusStore store;
  try {
    store = await openFocusStore();
  } catch (e) {
    debugPrint('Storage open failed: $e');
    runApp(StorageUnavailableApp(onRetry: main));
    return;
  }

  final notifier = NotificationService();
  try {
    await notifier.init();
  } catch (e) {
    debugPrint('Notification init: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        focusStoreProvider.overrideWithValue(store),
        notificationServiceProvider.overrideWithValue(notifier),
      ],
      child: const FitrahLauncherApp(),
    ),
  );
}

class FitrahLauncherApp extends ConsumerWidget {
  const FitrahLauncherApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(launcherSettingsProvider);
    return MaterialApp(
      title: 'Focus Clock Launcher',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: buildDarkTheme(settings.themePalette),
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
        },
      ),
      home: const FitrahLauncherShell(),
    );
  }
}
