import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../launcher/services/app_launcher_service.dart';

class AllowedAppsSelectorDialog extends ConsumerStatefulWidget {
  const AllowedAppsSelectorDialog({
    super.key,
    required this.initialAllowed,
    required this.onSaved,
  });

  final List<String> initialAllowed;
  final ValueChanged<List<String>> onSaved;

  @override
  ConsumerState<AllowedAppsSelectorDialog> createState() => _AllowedAppsSelectorDialogState();
}

class _AllowedAppsSelectorDialogState extends ConsumerState<AllowedAppsSelectorDialog> {
  late Set<String> _selectedPackages;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedPackages = Set.from(widget.initialAllowed);
  }

  @override
  Widget build(BuildContext context) {
    final installedAppsAsync = ref.watch(installedAppsFutureProvider);

    return Dialog(
      backgroundColor: const Color(0xFF141416),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFF27272A)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Row(
                children: [
                  const Icon(Icons.shield_outlined, color: AppPalette.accent, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Pilih Aplikasi Diizinkan (Whitelist)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Hanya aplikasi yang dicentang yang dapat dibuka selama sesi fokus YPT.',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
              const SizedBox(height: 14),

              // Search field
              Container(
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 18, color: Colors.white54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        style: const TextStyle(fontSize: 14, color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Cari aplikasi...',
                          hintStyle: TextStyle(fontSize: 13, color: Colors.white38),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // App List
              Expanded(
                child: installedAppsAsync.when(
                  data: (apps) {
                    final filtered = _searchQuery.isEmpty
                        ? apps
                        : apps.where((a) => a.appName.toLowerCase().contains(_searchQuery)).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text(
                          'Tidak ada aplikasi ditemukan.',
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, idx) {
                        final app = filtered[idx];
                        final isSelected = _selectedPackages.contains(app.packageName);

                        return CheckboxListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          title: Text(
                            app.appName,
                            style: const TextStyle(fontSize: 14, color: Colors.white),
                          ),
                          subtitle: Text(
                            app.packageName,
                            style: const TextStyle(fontSize: 11, color: Colors.white38),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          value: isSelected,
                          activeColor: AppPalette.accent,
                          checkColor: Colors.black,
                          onChanged: (val) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              if (val == true) {
                                _selectedPackages.add(app.packageName);
                              } else {
                                _selectedPackages.remove(app.packageName);
                              }
                            });
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
                ),
              ),

              const SizedBox(height: 16),

              // Save Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  widget.onSaved(_selectedPackages.toList());
                  Navigator.pop(context);
                },
                child: Text(
                  'Simpan (${_selectedPackages.length} Aplikasi Diizinkan)',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
