import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../providers/launcher_settings_provider.dart';

/// One durable source of values and save feedback across settings surfaces.
class DrawerPreferencesControls extends ConsumerWidget {
  const DrawerPreferencesControls({super.key, this.keyboardOnly = false});
  final bool keyboardOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(launcherSettingsProvider);
    final notifier = ref.read(launcherSettingsProvider.notifier);
    if (!notifier.isLoaded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            notifier.loadFailed
                ? 'Gagal memuat preferensi.'
                : 'Memuat preferensi…',
          ),
          if (notifier.loadFailed)
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: notifier.reload,
              child: const Text('Coba lagi'),
            ),
        ],
      );
    }
    return Card(
      color: AppPalette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppPalette.stroke),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!keyboardOnly)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tampilkan ikon aplikasi'),
                value: settings.showAppIcons,
                onChanged: notifier.drawerSaving
                    ? null
                    : (value) async {
                        await notifier.setShowAppIcons(value);
                      },
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Buka keyboard otomatis'),
              subtitle: const Text('Saat membuka daftar aplikasi.'),
              value: settings.autoFocusSearch,
              onChanged: notifier.drawerSaving
                  ? null
                  : (value) async {
                      await notifier.setAutoFocusSearch(value);
                    },
            ),
            if (notifier.drawerSaving) const Text('Menyimpan…'),
            for (final failure in notifier.drawerFailedValues.entries)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Gagal menyimpan preferensi. ${failure.key == 'icons' ? 'Tampilkan ikon aplikasi' : 'Buka keyboard otomatis'}',
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: notifier.drawerSaving
                        ? null
                        : () async {
                            if (failure.key == 'icons') {
                              await notifier.setShowAppIcons(failure.value);
                            } else {
                              await notifier.setAutoFocusSearch(failure.value);
                            }
                          },
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
