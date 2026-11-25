import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../services/app_launcher_service.dart';

class DefaultHomeStatusControl extends ConsumerStatefulWidget {
  const DefaultHomeStatusControl({super.key});

  @override
  ConsumerState<DefaultHomeStatusControl> createState() =>
      _DefaultHomeStatusControlState();
}

/// Small first-run shortcut for the Home goal card. The detailed status stays
/// in Settings; this only appears when Android confirms Fitrah is not Home.
class DefaultHomeQuickAction extends ConsumerStatefulWidget {
  const DefaultHomeQuickAction({super.key});

  @override
  ConsumerState<DefaultHomeQuickAction> createState() =>
      _DefaultHomeQuickActionState();
}

class _DefaultHomeQuickActionState
    extends ConsumerState<DefaultHomeQuickAction> {
  bool _pending = false;
  String? _failure;

  Future<void> _choose() async {
    if (_pending) return;
    setState(() {
      _pending = true;
      _failure = null;
    });
    var dispatched = false;
    try {
      dispatched = await ref
          .read(appLauncherServiceProvider)
          .requestDefaultHome();
    } catch (_) {
      dispatched = false;
    }
    if (!mounted) return;
    setState(() {
      _pending = false;
      if (!dispatched) {
        _failure = 'Tidak dapat membuka pilihan Android. Coba lagi.';
      }
    });
    ref.invalidate(defaultHomeStatusProvider);
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(appLauncherServiceProvider);
    if (!service.isSupported) return const SizedBox.shrink();
    final status = ref.watch(defaultHomeStatusProvider);
    if (status.isLoading || status.hasError || status.value == true) {
      return const SizedBox.shrink();
    }
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: colors.primary,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          onPressed: _pending ? null : _choose,
          icon: _pending
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.home_outlined, size: 18),
          label: Text(_pending ? 'Membuka pilihan…' : 'Jadikan layar utama'),
        ),
        if (_failure != null)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              _failure!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
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
    final theme = Theme.of(context);

    return Card(
      color: AppPalette.card,
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppPalette.stroke),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Status Beranda', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message, style: theme.textTheme.bodyMedium),
            if (_failure != null) ...[
              const SizedBox(height: 8),
              Text(
                _failure!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            if (supported) ...[
              const SizedBox(height: 8),
              if (loading || failed)
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: AppPalette.accent,
                  ),
                  onPressed: _pending
                      ? null
                      : () => ref.invalidate(defaultHomeStatusProvider),
                  child: const Text('Periksa lagi'),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    backgroundColor: AppPalette.accent,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: loading || _pending ? null : () => _choose(held),
                  child: Text(
                    _pending
                        ? 'Membuka pilihan Android…'
                        : held
                        ? 'Ubah launcher default'
                        : 'Pilih Fitrah sebagai launcher default',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
