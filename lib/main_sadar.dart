import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/window_manager.dart';

import 'core/theme.dart';
import 'data/isar_service.dart';
import 'features/sadar/sadar_home_screen.dart';
import 'firebase_options.dart';
import 'providers/providers.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (if configured)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init warning: $e');
  }

  // Initialize Desktop Window Manager
  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(820, 720),
      minimumSize: Size(540, 600),
      center: true,
      backgroundColor: AppPalette.bg,
      title: 'Sadar — Way of Life',
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  late final IsarService isarService;
  try {
    isarService = await IsarService.open();
  } catch (e) {
    debugPrint('IsarService init fallback: $e');
    isarService = IsarService.fallback();
  }

  final notifier = NotificationService();
  try {
    await notifier.init();
  } catch (e) {
    debugPrint('NotificationService init error: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isarService.isar),
        notificationServiceProvider.overrideWithValue(notifier),
      ],
      child: const SadarStandaloneApp(),
    ),
  );
}

class SadarStandaloneApp extends StatelessWidget {
  const SadarStandaloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sadar — Way of Life',
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
      home: const SadarHomeScreen(),
    );
  }
}
