import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_launcher_service.dart';
import 'fitrah_settings_screen.dart';

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
    '#', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
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
                // Header: App name + folder icon
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        app.appName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Icon(Icons.folder_open_outlined, color: Colors.white70, size: 22),
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
                  iconColor: const Color(0xFFE5A93C),
                  title: 'App Interrupts',
                  subtitle: 'Quran verse, timer, Password Interrupts',
                  onTap: () {
                    Navigator.pop(ctx);
                  },
                ),

                // 3. App Block
                _buildSheetTile(
                  icon: Icons.block_flipped,
                  iconColor: const Color(0xFFE05252),
                  title: 'App Block',
                  subtitle: 'Block for a set duration',
                  onTap: () {
                    Navigator.pop(ctx);
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
                  icon: Icons.folder_outlined,
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
                  iconColor: const Color(0xFFE05252),
                  textColor: const Color(0xFFE05252),
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
            Icon(icon, color: iconColor, size: 21),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
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

  double _scrubberY = 200;

  @override
  Widget build(BuildContext context) {
    final appsAsync = ref.watch(installedAppsFutureProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: Column(
                  children: [
                    // Top App Bar: Crown + Apps + Settings Cog
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.workspace_premium_outlined, color: Color(0xFFE5A93C), size: 26),
                            onPressed: () {},
                          ),
                          const Expanded(
                            child: Center(
                              child: Text(
                                'Apps',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 24),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const FitrahSettingsScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Rounded Pill Search Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white30, width: 1.0),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, size: 20, color: Colors.white70),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                                style: const TextStyle(fontSize: 15, color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: 'Search Apps',
                                  hintStyle: TextStyle(fontSize: 14, color: Colors.white38),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                                child: const Icon(Icons.clear_rounded, size: 18, color: Colors.white60),
                              ),
                          ],
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

                          if (filtered.isEmpty) {
                            return const Center(
                              child: Text(
                                'No apps found.',
                                style: TextStyle(color: Colors.white38, fontSize: 13),
                              ),
                            );
                          }

                          // Group by first letter for scroll indexing
                          final Map<String, List<InstalledApp>> grouped = {};
                          for (final app in filtered) {
                            final letter = app.firstLetter;
                            grouped.putIfAbsent(letter, () => []).add(app);
                          }

                          return ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.fromLTRB(20, 4, 38, 80),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final app = filtered[index];
                              final isFirstOfLetter = index == 0 ||
                                  filtered[index - 1].firstLetter != app.firstLetter;

                              final rowWidget = _buildAppRow(app);

                              if (isFirstOfLetter) {
                                return Container(
                                  key: _letterKeys[app.firstLetter],
                                  child: rowWidget,
                                );
                              }
                              return rowWidget;
                            },
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
              top: 80,
              bottom: 40,
              width: 28,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragDown: (details) {
                  _updateScrub(details.localPosition.dy);
                },
                onVerticalDragUpdate: (details) {
                  _updateScrub(details.localPosition.dy);
                },
                onVerticalDragEnd: (_) {
                  setState(() => _selectedScrubLetter = '');
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _alphabet.map((letter) {
                    final isSelected = _selectedScrubLetter == letter;
                    return Text(
                      letter,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w400,
                        color: isSelected ? Colors.white : Colors.white38,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Niagara-Style Letter Indicator Bubble while scrubbing
            if (_selectedScrubLetter.isNotEmpty)
              Positioned(
                right: 36,
                top: _scrubberY - 18,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3F3F46),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _selectedScrubLetter,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

            // Circled Arrow Up button at Bottom Right (scroll to top)
            Positioned(
              right: 18,
              bottom: 24,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (_scrollCtrl.hasClients) {
                    _scrollCtrl.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(color: Colors.white, width: 2.0),
                  ),
                  child: const Icon(
                    Icons.arrow_upward_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateScrub(double localY) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final totalHeight = renderBox.size.height - 120;
    final itemHeight = totalHeight / _alphabet.length;
    final index = (localY / itemHeight).clamp(0, _alphabet.length - 1).floor();
    final letter = _alphabet[index];
    _scrubberY = (localY + 80).clamp(80.0, renderBox.size.height - 50);
    _scrollToLetter(letter);
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
