import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!keyboardOnly)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Show App Icons'),
            value: settings.showAppIcons,
            onChanged: notifier.drawerSaving
                ? null
                : (value) async {
                    await notifier.setShowAppIcons(value);
                  },
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Auto Open Keyboard on Apps'),
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
                'Gagal menyimpan preferensi. ${failure.key == 'icons' ? 'Show App Icons' : 'Auto Open Keyboard on Apps'}',
              ),
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
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
    );
  }
}
