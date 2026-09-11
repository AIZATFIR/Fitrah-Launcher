import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../services/app_launcher_service.dart';

class MinimalistAppDrawer extends ConsumerStatefulWidget {
  const MinimalistAppDrawer({super.key});

  @override
  ConsumerState<MinimalistAppDrawer> createState() => _MinimalistAppDrawerState();
}

class _MinimalistAppDrawerState extends ConsumerState<MinimalistAppDrawer> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final Map<String, GlobalKey> _letterKeys = {};
  String _selectedScrubLetter = '';
  String _searchQuery = '';

  static const List<String> _alphabet = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '#'
  ];

  @override
  void initState() {
    super.initState();
    for (final l in _alphabet) {
      _letterKeys[l] = GlobalKey();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToLetter(String letter) {
    if (_selectedScrubLetter != letter) {
      HapticFeedback.selectionClick();
      setState(() => _selectedScrubLetter = letter);
    }
    final key = _letterKeys[letter];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  void _launchApp(InstalledApp app) {
    HapticFeedback.lightImpact();
    ref.read(appLauncherServiceProvider).launchApp(app.packageName);
  }

  void _showAppOptions(InstalledApp app) {
    HapticFeedback.mediumImpact();
    final favorites = ref.read(favoritePackagesProvider);
    final isFav = favorites.contains(app.packageName);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppPalette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppPalette.stroke),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppPalette.bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppPalette.stroke),
                    ),
                    child: Center(
                      child: Text(
                        app.appName.isNotEmpty ? app.appName[0].toUpperCase() : '?',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppPalette.accent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.appName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppPalette.text),
                        ),
                        Text(
                          app.packageName,
                          style: const TextStyle(fontSize: 11, color: AppPalette.textDim),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(color: AppPalette.stroke, height: 1),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isFav ? AppPalette.accent : AppPalette.textDim,
                ),
                title: Text(isFav ? 'Hapus dari Favorit' : 'Sematkan ke Favorit'),
                onTap: () {
                  final newSet = Set<String>.from(favorites);
                  if (isFav) {
                    newSet.remove(app.packageName);
                  } else {
                    newSet.add(app.packageName);
                  }
                  ref.read(favoritePackagesProvider.notifier).state = newSet;
                  Navigator.of(ctx).pop();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info_outline_rounded, color: AppPalette.textDim),
                title: const Text('Detail Aplikasi'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ref.read(appLauncherServiceProvider).openAppDetails(app.packageName);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _resolveAppIcon(String appName) {
    final lower = appName.toLowerCase();
    if (lower.contains('browser') || lower.contains('chrome') || lower.contains('firefox')) {
      return Icons.language_rounded;
    }
    if (lower.contains('phone') || lower.contains('call') || lower.contains('dialer')) {
      return Icons.phone_outlined;
    }
    if (lower.contains('message') || lower.contains('sms') || lower.contains('chat')) {
      return Icons.chat_bubble_outline_rounded;
    }
    if (lower.contains('camera')) {
      return Icons.camera_alt_outlined;
    }
    if (lower.contains('calendar')) {
      return Icons.calendar_today_outlined;
    }
    if (lower.contains('clock') || lower.contains('timer') || lower.contains('alarm')) {
      return Icons.schedule_rounded;
    }
    if (lower.contains('setting')) {
      return Icons.tune_rounded;
    }
    if (lower.contains('calculator')) {
      return Icons.calculate_outlined;
    }
    if (lower.contains('mail')) {
      return Icons.mail_outline_rounded;
    }
    if (lower.contains('file') || lower.contains('manager') || lower.contains('folder')) {
      return Icons.folder_open_rounded;
    }
    if (lower.contains('note') || lower.contains('memo') || lower.contains('keep')) {
      return Icons.edit_note_rounded;
    }
    if (lower.contains('term') || lower.contains('shell')) {
      return Icons.terminal_rounded;
    }
    return Icons.widgets_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final appsAsync = ref.watch(installedAppsFutureProvider);
    final favoritePackages = ref.watch(favoritePackagesProvider);

    return Scaffold(
      backgroundColor: AppPalette.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 36, 12),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppPalette.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppPalette.stroke),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                          style: const TextStyle(fontSize: 14, color: AppPalette.text),
                          decoration: InputDecoration(
                            hintText: 'Cari aplikasi...',
                            hintStyle: const TextStyle(fontSize: 13, color: AppPalette.textDim),
                            prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppPalette.textDim),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 16, color: AppPalette.textDim),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),

                    // Main App List
                    Expanded(
                      child: appsAsync.when(
                        data: (allApps) {
                          final filtered = _searchQuery.isEmpty
                              ? allApps
                              : allApps.where((a) => a.appName.toLowerCase().contains(_searchQuery)).toList();

                          final favApps = allApps.where((a) => favoritePackages.contains(a.packageName)).toList();

                          if (filtered.isEmpty) {
                            return const Center(
                              child: Text(
                                'Tidak ada aplikasi yang cocok.',
                                style: TextStyle(color: AppPalette.textDim, fontSize: 13),
                              ),
                            );
                          }

                          // Group by first letter
                          final Map<String, List<InstalledApp>> grouped = {};
                          for (final app in filtered) {
                            final letter = app.firstLetter;
                            grouped.putIfAbsent(letter, () => []).add(app);
                          }

                          return ListView(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.fromLTRB(20, 4, 38, 40),
                            children: [
                              // Favorites Section (Only when not searching)
                              if (_searchQuery.isEmpty && favApps.isNotEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.only(left: 4, bottom: 8, top: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.star_rounded, size: 13, color: AppPalette.accent),
                                      SizedBox(width: 6),
                                      Text(
                                        'FAVORIT',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.5,
                                          color: AppPalette.accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ...favApps.map((app) => _buildAppRow(app)),
                                const SizedBox(height: 16),
                                const Divider(color: AppPalette.stroke, height: 1),
                                const SizedBox(height: 12),
                              ],

                              // Alphabetical Groups
                              for (final entry in grouped.entries) ...[
                                Container(
                                  key: _letterKeys[entry.key],
                                  padding: const EdgeInsets.only(left: 6, top: 12, bottom: 6),
                                  child: Text(
                                    entry.key,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: AppPalette.textDim,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                                ...entry.value.map((app) => _buildAppRow(app)),
                              ],
                            ],
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Color(0xFFEF4444)))),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Niagara-Style Alphabet Scrubber Bar on the Right Margin
            Positioned(
              right: 2,
              top: 70,
              bottom: 24,
              width: 26,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  final renderBox = context.findRenderObject() as RenderBox?;
                  if (renderBox == null) return;
                  final localY = details.localPosition.dy;
                  final totalHeight = renderBox.size.height - 94;
                  final itemHeight = totalHeight / _alphabet.length;
                  final index = (localY / itemHeight).clamp(0, _alphabet.length - 1).floor();
                  final letter = _alphabet[index];
                  _scrollToLetter(letter);
                },
                child: Container(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _alphabet.map((letter) {
                      final isSelected = _selectedScrubLetter == letter;
                      return GestureDetector(
                        onTap: () => _scrollToLetter(letter),
                        child: Text(
                          letter,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                            color: isSelected ? AppPalette.accent : AppPalette.textDim.withValues(alpha: 0.6),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppRow(InstalledApp app) {
    final iconData = _resolveAppIcon(app.appName);

    return InkWell(
      onTap: () => _launchApp(app),
      onLongPress: () => _showAppOptions(app),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppPalette.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppPalette.stroke),
              ),
              child: Icon(iconData, size: 18, color: AppPalette.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                app.appName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.text,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
