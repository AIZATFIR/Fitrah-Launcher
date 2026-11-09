import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_launcher_service.dart';

class DefaultHomeStatusControl extends ConsumerStatefulWidget {
  const DefaultHomeStatusControl({super.key});

  @override
  ConsumerState<DefaultHomeStatusControl> createState() =>
      _DefaultHomeStatusControlState();
}

class _DefaultHomeStatusControlState
    extends ConsumerState<DefaultHomeStatusControl> {
  bool _pending = false;
  String? _failure;

  Future<void> _choose(bool held) async {
    if (_pending) return;
    setState(() {
      _pending = true;
      _failure = null;
    });
    var dispatched = false;
    try {
      final service = ref.read(appLauncherServiceProvider);
      dispatched = await (held
          ? service.openHomeSettings()
          : service.requestDefaultHome());
    } catch (_) {
      dispatched = false;
    }
    if (!mounted) return;
    setState(() {
      _pending = false;
      if (!dispatched) {
        _failure = 'Pilihan launcher tidak dapat dibuka. Coba lagi.';
      }
    });
    // Also refresh if a platform request returns without a lifecycle transition.
    ref.invalidate(defaultHomeStatusProvider);
  }

  @override
  Widget build(BuildContext context) {
    final supported = ref.watch(appLauncherServiceProvider).isSupported;
    final status = supported ? ref.watch(defaultHomeStatusProvider) : null;
    final loading = status?.isLoading ?? false;
    final failed = status?.hasError ?? false;
    final held = !loading && !failed && status?.value == true;
    final message = !supported
        ? 'Launcher default hanya tersedia di Android.'
        : loading
        ? 'Memeriksa launcher default…'
        : failed
        ? 'Status launcher default belum dapat diperiksa.'
        : held
        ? 'Fitrah adalah launcher default Android.'
        : 'Fitrah belum menjadi launcher default Android.';
    final style = TextButton.styleFrom(
      minimumSize: const Size(48, 48),
      foregroundColor: Colors.white,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Default Launcher',
            style: TextStyle(color: Colors.white, fontSize: 17),
          ),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Colors.white70)),
          if (_failure != null) ...[
            const SizedBox(height: 8),
            Text(_failure!, style: const TextStyle(color: Colors.white70)),
          ],
          if (supported) ...[
            const SizedBox(height: 8),
            if (failed)
              TextButton(
                style: style,
                onPressed: _pending
                    ? null
                    : () => ref.invalidate(defaultHomeStatusProvider),
                child: const Text('Periksa lagi'),
              ),
            TextButton(
              style: style,
              onPressed: loading || _pending ? null : () => _choose(held),
              child: Text(
                _pending
                    ? 'Membuka pilihan Android…'
                    : held
                    ? 'Ubah launcher default'
                    : 'Pilih launcher default',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
