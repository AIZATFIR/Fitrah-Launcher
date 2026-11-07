import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/window_manager.dart';

import 'core/theme.dart';
import 'data/store/focus_store.dart';
import 'data/store/store_factory.dart';
import 'data/storage_unavailable_app.dart';
import 'features/launcher/fitrah_launcher_shell.dart';
import 'firebase_options.dart';
import 'providers/providers.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init: $e');
  }

  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(440, 840),
      minimumSize: Size(380, 600),
      center: true,
      backgroundColor: AppPalette.bg,
      title: 'Fitrah Launcher',
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

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

class FitrahLauncherApp extends StatelessWidget {
  const FitrahLauncherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitrah Launcher',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppPalette.bg,
        colorScheme: const ColorScheme.dark(
          primary: AppPalette.accent,
          surface: AppPalette.card,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      home: const FitrahLauncherShell(),
    );
  }
}
