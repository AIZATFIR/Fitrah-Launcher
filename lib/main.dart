import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'data/isar_service.dart';
import 'features/launcher/fitrah_launcher_shell.dart';
import 'features/launcher/providers/launcher_settings_provider.dart';
import 'providers/providers.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  late final IsarService isarService;
  try {
    isarService = await IsarService.open();
  } catch (e) {
    debugPrint('IsarService fallback: $e');
    isarService = IsarService.fallback();
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
        isarProvider.overrideWithValue(isarService.isar),
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
      home: const FitrahLauncherShell(),
    );
  }
}
