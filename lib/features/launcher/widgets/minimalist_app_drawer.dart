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
      backgroundColor: const Color(0xFF161618),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: Color(0xFF26262B)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        app.appName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.create_new_folder_outlined, color: Colors.white70, size: 22),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFF26262B), height: 1),
                const SizedBox(height: 6),

                // 1. Add to Favorites
                _buildSheetTile(
                  icon: isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                  iconColor: isFav ? const Color(0xFFFBBF24) : Colors.white70,
                  title: isFav ? 'Remove from Favorites' : 'Add to Favorites',
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

                // 2. App Interrupts
                _buildSheetTile(
                  icon: Icons.front_hand_outlined,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'App Interrupts',
                  subtitle: 'Quran verse, timer, Password Interrupts',
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('App Interrupts diatur untuk ${app.appName}')),
                    );
                  },
                ),

                // 3. App Block
                _buildSheetTile(
                  icon: Icons.block_outlined,
                  iconColor: const Color(0xFFEF4444),
                  title: 'App Block',
                  subtitle: 'Block for a set duration',
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('App Block diatur untuk ${app.appName}')),
                    );
                  },
                ),

                // 4. Change app name
                _buildSheetTile(
                  icon: Icons.edit_outlined,
                  title: 'Change app name',
                  onTap: () => Navigator.pop(ctx),
                ),

                // 5. Add to folder
                _buildSheetTile(
                  icon: Icons.folder_open_outlined,
                  title: 'Add to folder',
                  onTap: () => Navigator.pop(ctx),
                ),

                // 6. Set category
                _buildSheetTile(
                  icon: Icons.category_outlined,
                  title: 'Set category',
                  onTap: () => Navigator.pop(ctx),
                ),

                // 7. Hide this app
                _buildSheetTile(
                  icon: Icons.visibility_off_outlined,
                  title: 'Hide this app',
                  onTap: () => Navigator.pop(ctx),
                ),

                // 8. App info
                _buildSheetTile(
                  icon: Icons.info_outline_rounded,
                  title: 'App info',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    ref.read(appLauncherServiceProvider).openAppDetails(app.packageName);
                  },
                ),

                // 9. Uninstall app
                _buildSheetTile(
                  icon: Icons.delete_outline_rounded,
                  iconColor: const Color(0xFFEF4444),
                  textColor: const Color(0xFFEF4444),
                  title: 'Uninstall app',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    ref.read(appLauncherServiceProvider).uninstallApp(app.packageName);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color iconColor = Colors.white70,
    Color textColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
              width: 32,
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
                onVerticalDragEnd: (_) {
                  setState(() => _selectedScrubLetter = '');
                },
                child: Container(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _alphabet.map((letter) {
                      final isSelected = _selectedScrubLetter == letter;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 0.5),
                        child: Text(
                          letter,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.white38,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            // Letter Indicator Bubble while scrubbing
            if (_selectedScrubLetter.isNotEmpty)
              Positioned(
                right: 48,
                top: 200,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2E),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _selectedScrubLetter,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
    return InkWell(
      onTap: () => _launchApp(app),
      onLongPress: () => _showAppOptions(app),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                app.appName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
