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
  runApp(const _LauncherBootstrap());
}

typedef _BootstrapResult = ({
  FocusStore store,
  NotificationService notifications,
});

class _LauncherBootstrap extends StatefulWidget {
  const _LauncherBootstrap();

  @override
  State<_LauncherBootstrap> createState() => _LauncherBootstrapState();
}

class _LauncherBootstrapState extends State<_LauncherBootstrap> {
  late Future<_BootstrapResult> _startup;

  @override
  void initState() {
    super.initState();
    _startup = _open();
  }

  Future<_BootstrapResult> _open() async {
    debugPrint('Opening Focus Clock storage');
    final store = await openFocusStore();
    debugPrint('Focus Clock storage opened');

    final notifications = NotificationService();
    try {
      await notifications.init();
    } catch (e) {
      debugPrint('Notification init: $e');
    }

    return (store: store, notifications: notifications);
  }

  Future<void> _retry() async {
    setState(() => _startup = _open());
    try {
      await _startup;
    } catch (_) {
      // The FutureBuilder shows the same recovery view after a failed retry.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BootstrapResult>(
      future: _startup,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Storage open failed: ${snapshot.error}');
          return StorageUnavailableApp(onRetry: _retry);
        }

        final result = snapshot.data;
        if (result == null) return const _StorageLoadingApp();

        return ProviderScope(
          overrides: [
            focusStoreProvider.overrideWithValue(result.store),
            notificationServiceProvider.overrideWithValue(result.notifications),
          ],
          child: const FitrahLauncherApp(),
        );
      },
    );
  }
}

class _StorageLoadingApp extends StatelessWidget {
  const _StorageLoadingApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Focus Clock',
      debugShowCheckedModeBanner: false,
      theme: buildDarkTheme('full_book'),
      home: Scaffold(
        backgroundColor: AppPalette.bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label: 'Membuka data lokal',
                child: SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              SizedBox(height: 16),
              Text('Membuka Focus Clock…'),
            ],
          ),
        ),
      ),
    );
  }
}

class FitrahLauncherApp extends ConsumerWidget {
  const FitrahLauncherApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(launcherSettingsProvider);
    return MaterialApp(
      title: 'Focus Clock',
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
