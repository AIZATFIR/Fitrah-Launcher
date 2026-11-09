import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/launcher_settings_provider.dart';
import '../services/app_launcher_service.dart';
import 'launcher_action_feedback.dart';
import 'app_icon_widget.dart';

Future<void> showAppPreferences(BuildContext context, InstalledApp app) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: const Color(0xFF161618),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: Color(0xFF26262B)),
      ),
      builder: (_) => AppPreferencesSheet(app: app, feedbackContext: context),
    );

class AppPreferencesSheet extends ConsumerStatefulWidget {
  const AppPreferencesSheet({
    super.key,
    required this.app,
    this.feedbackContext,
  });
  final InstalledApp app;
  final BuildContext? feedbackContext;
  @override
  ConsumerState<AppPreferencesSheet> createState() =>
      _AppPreferencesSheetState();
}

class _AppPreferencesSheetState extends ConsumerState<AppPreferencesSheet> {
  bool _pending = false;
  String? _error;
  Future<bool> Function()? _retry;
  VoidCallback? _retryCommitted;

  Future<void> _save(
    Future<bool> Function() operation, {
    VoidCallback? onCommitted,
  }) async {
    if (_pending) return;
    setState(() {
      _pending = true;
      _error = null;
      _retry = operation;
      _retryCommitted = onCommitted;
    });
    final success = await operation();
    if (!mounted) return;
    setState(() {
      _pending = false;
      _error = success ? null : 'Gagal menyimpan preferensi.';
    });
    if (success) {
      Navigator.pop(context);
      onCommitted?.call();
    }
  }

  void _nativeAction(Future<bool> Function(AppLauncherService) action) {
    final feedback = widget.feedbackContext ?? context;
    runLauncherAction(feedback, ref.read(appLauncherServiceProvider), action);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(launcherSettingsProvider);
    final notifier = ref.read(launcherSettingsProvider.notifier);
    final app = widget.app;
    final favorite = settings.favoritePackages.contains(app.packageName);
    final hidden = settings.hiddenPackages.contains(app.packageName);
    final feedback = widget.feedbackContext;
    return PopScope(
      canPop: !_pending,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  AppIconWidget(
                    packageName: app.packageName,
                    appName: app.appName,
                    size: 46,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.appName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          app.packageName,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              ListTile(
                enabled: !_pending,
                leading: Icon(
                  favorite ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
                title: Text(
                  favorite ? 'Hapus dari Favorit' : 'Tambah ke Favorit',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () => _save(
                  () => notifier.setFavoritePackage(app.packageName, !favorite),
                ),
              ),
              ListTile(
                enabled: !_pending,
                leading: const Icon(
                  Icons.visibility_off_outlined,
                  color: Colors.white70,
                ),
                title: Text(
                  hidden ? 'Tampilkan Aplikasi' : 'Sembunyikan Aplikasi',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () => _save(
                  () => notifier.setHiddenPackage(app.packageName, !hidden),
                  onCommitted: !hidden && feedback != null
                      ? () => _offerUndo(feedback, notifier, app)
                      : null,
                ),
              ),
              ListTile(
                enabled: !_pending,
                leading: const Icon(Icons.info_outline, color: Colors.white70),
                title: const Text(
                  'App info',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () => _nativeAction(
                  (service) => service.openAppDetails(app.packageName),
                ),
              ),
              if (!app.isSystem)
                ListTile(
                  enabled: !_pending,
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Uninstall app',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () => _nativeAction(
                    (service) => service.uninstallApp(app.packageName),
                  ),
                ),
              if (_pending)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Menyimpan…',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                TextButton(
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: _pending
                      ? null
                      : () => _save(_retry!, onCommitted: _retryCommitted),
                  child: const Text('Coba lagi'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// The legacy stream and active drawer share the same durable undo path.
void _offerUndo(
  BuildContext context,
  LauncherSettingsNotifier notifier,
  InstalledApp app,
) {
  if (!context.mounted) return;
  var pending = false;
  Future<void> undo() async {
    if (pending) return;
    pending = true;
    final success = await notifier.setHiddenPackage(app.packageName, false);
    pending = false;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '${app.appName} ditampilkan'
              : 'Gagal menyimpan preferensi.',
        ),
        action: success
            ? null
            : SnackBarAction(label: 'Coba lagi', onPressed: undo),
      ),
    );
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('${app.appName} disembunyikan'),
      action: SnackBarAction(label: 'URUNGKAN', onPressed: undo),
    ),
  );
}

Future<void> showHiddenApps(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  enableDrag: false,
  backgroundColor: const Color(0xFF161618),
  builder: (_) => const HiddenAppsSheet(),
);

class HiddenAppsSheet extends ConsumerStatefulWidget {
  const HiddenAppsSheet({super.key});
  @override
  ConsumerState<HiddenAppsSheet> createState() => _HiddenAppsSheetState();
}

class _HiddenAppsSheetState extends ConsumerState<HiddenAppsSheet> {
  String? _pending;
  String? _failed;

  Future<void> _restore(String package) async {
    if (_pending != null) return;
    setState(() {
      _pending = package;
      _failed = null;
    });
    final success = await ref
        .read(launcherSettingsProvider.notifier)
        .setHiddenPackage(package, false);
    if (!mounted) return;
    setState(() {
      _pending = null;
      _failed = success ? null : package;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(launcherSettingsProvider);
    final notifier = ref.read(launcherSettingsProvider.notifier);
    final apps = ref.watch(installedAppsFutureProvider).valueOrNull ?? [];
    final names = {for (final app in apps) app.packageName: app.appName};
    return PopScope(
      canPop: _pending == null,
      child: SafeArea(
        child: FractionallySizedBox(
          heightFactor: .8,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Aplikasi tersembunyi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!notifier.isLoaded) ...[
                Text(
                  notifier.loadFailed
                      ? 'Gagal memuat preferensi.'
                      : 'Memuat preferensi…',
                  style: const TextStyle(color: Colors.white70),
                ),
                if (notifier.loadFailed)
                  TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: notifier.reload,
                    child: const Text('Coba lagi'),
                  ),
              ] else if (settings.hiddenPackages.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Tidak ada aplikasi tersembunyi.',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              else
                for (final package in settings.hiddenPackages) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      names[package] ?? package,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  if (names[package] == null)
                    const Text(
                      'Saat ini tidak terpasang atau tidak tersedia',
                      style: TextStyle(color: Colors.white54),
                    ),
                  TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: _pending == null
                        ? () => _restore(package)
                        : null,
                    child: Text(
                      _pending == package
                          ? 'Menyimpan…'
                          : 'Tampilkan ${names[package] ?? package}',
                    ),
                  ),
                  if (_failed == package) ...[
                    const Text(
                      'Gagal menyimpan preferensi.',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      onPressed: _pending == null
                          ? () => _restore(package)
                          : null,
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ],
            ],
          ),
        ),
      ),
    );
  }
}
