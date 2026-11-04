import 'package:flutter/material.dart';

class StorageUnavailableApp extends StatefulWidget {
  const StorageUnavailableApp({required this.onRetry, super.key});

  final Future<void> Function() onRetry;

  @override
  State<StorageUnavailableApp> createState() => _StorageUnavailableAppState();
}

class _StorageUnavailableAppState extends State<StorageUnavailableApp> {
  bool _retrying = false;

  Future<void> _retry() async {
    setState(() => _retrying = true);
    await widget.onRetry();
    if (mounted) setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Focus Clock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.storage_rounded, size: 32),
                    const SizedBox(height: 24),
                    Text(
                      'Data belum dapat dibuka',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Focus Clock berhenti di sini agar perubahan baru tidak tersimpan sementara. Data yang sudah ada tetap di perangkat.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _retrying ? null : _retry,
                      icon: _retrying
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded),
                      label: Text(_retrying ? 'Mencoba lagi…' : 'Coba lagi'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
