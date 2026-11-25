import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_launcher_service.dart';

/// Reports failed dispatch only; acceptance does not prove the destination opened.
Future<bool> runLauncherAction(
  BuildContext context,
  AppLauncherService service,
  Future<bool> Function(AppLauncherService service) action,
) async {
  if (!context.mounted) return false;
  var accepted = false;
  try {
    accepted = await action(service);
  } catch (_) {
    accepted = false;
  }
  if (!accepted && context.mounted) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          service.isSupported
              ? 'Tindakan tidak dapat dibuka. Aplikasi atau pengaturan mungkin tidak tersedia. Coba lagi.'
              : 'Membuka aplikasi dan pengaturan perangkat hanya tersedia di Android.',
        ),
      ),
    );
  }
  return accepted;
}

class LauncherAppListFailure extends ConsumerWidget {
  const LauncherAppListFailure({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unsupported =
        error is UnsupportedError ||
        !ref.watch(appLauncherServiceProvider).isSupported;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 48, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              unsupported
                  ? 'Daftar aplikasi perangkat hanya tersedia di Android.'
                  : 'Daftar aplikasi belum dapat dimuat. Pilihan aplikasi tersimpan tetap aman.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            if (!unsupported) ...[
              const SizedBox(height: 12),
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => ref.invalidate(installedAppsFutureProvider),
                child: const Text('Coba lagi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
