import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/launcher_settings_provider.dart';
import '../services/app_launcher_service.dart';
import 'app_icon_widget.dart';
import 'fitrah_settings_screen.dart';
import 'niagara_wave_scrubber.dart';

/// Minimalist Niagara-style launcher app drawer that floats directly
/// over the phone's system wallpaper.
class MinimalistAppDrawer extends ConsumerStatefulWidget {
  const MinimalistAppDrawer({
    super.key,
    this.isActive = false,
    this.onBackToHome,
  });

  final bool isActive;
  final VoidCallback? onBackToHome;

  @override
  ConsumerState<MinimalistAppDrawer> createState() => _MinimalistAppDrawerState();
}

class _MinimalistAppDrawerState extends ConsumerState<MinimalistAppDrawer> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();
  final Map<String, GlobalKey> _letterKeys = {};

  String _searchQuery = '';
  bool _isSearchOpen = false;
  Timer? _clockTicker;

  static const List<String> _alphabet = [
    '☆', '#', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '○'
  ];

  @override
  void initState() {
    super.initState();
    for (final l in _alphabet) {
      _letterKeys[l] = GlobalKey();
    }
    // Update time every 15 seconds to keep clock fresh
    _clockTicker = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });

    if (widget.isActive) {
      _checkAutoFocus();
    }
  }

  @override
  void didUpdateWidget(covariant MinimalistAppDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _checkAutoFocus();
    } else if (oldWidget.isActive && !widget.isActive) {
      _searchFocusNode.unfocus();
    }
  }

  void _checkAutoFocus() {
    final settings = ref.read(launcherSettingsProvider);
    if (settings.autoFocusSearch) {
      Future.delayed(const Duration(milliseconds: 180), () {
        if (mounted && widget.isActive) {
          setState(() => _isSearchOpen = true);
          _searchFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _clockTicker?.cancel();
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToLetter(String letter) {
    if (letter == '☆') {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
      return;
    }

    if (letter == '○') {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
      return;
    }

    final appsAsync = ref.read(installedAppsFutureProvider);
    final allApps = appsAsync.valueOrNull ?? [];
    final filtered = _searchQuery.isEmpty
        ? allApps
        : allApps.where((a) => a.appName.toLowerCase().contains(_searchQuery)).toList();

    final targetIdx = filtered.indexWhere((a) => a.firstLetter == letter);
    if (targetIdx != -1 && _scrollCtrl.hasClients) {
      // Estimated header height ~130px, each app item ~56px
      final targetOffset = (130.0 + targetIdx * 56.0).clamp(0.0, _scrollCtrl.position.maxScrollExtent);
      _scrollCtrl.jumpTo(targetOffset);
    } else {
      final key = _letterKeys[letter];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
        );
      }
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
                Row(
                  children: [
                    AppIconWidget(
                      packageName: app.packageName,
                      appName: app.appName,
                      size: 46,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.appName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            app.packageName,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFF26262B)),

                _buildSheetTile(
                  icon: isFav ? Icons.star_rounded : Icons.star_border_rounded,
                  iconColor: isFav ? const Color(0xFFE5A93C) : Colors.white70,
                  title: isFav ? 'Hapus dari Favorit' : 'Tambah ke Favorit',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    final newSet = Set<String>.from(favorites);
                    if (isFav) {
                      newSet.remove(app.packageName);
                    } else {
                      newSet.add(app.packageName);
                    }
                    ref.read(favoritePackagesProvider.notifier).state = newSet;
                  },
                ),
                _buildSheetTile(
                  icon: Icons.info_outline_rounded,
                  title: 'App info',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    ref.read(appLauncherServiceProvider).openAppDetails(app.packageName);
                  },
                ),
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

  String _formatHeaderDate(DateTime dt) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    return '$dayName, $monthName ${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final appsAsync = ref.watch(installedAppsFutureProvider);
    final favorites = ref.watch(favoritePackagesProvider);

    return PopScope(
      canPop: !_isSearchOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isSearchOpen) {
          setState(() {
            _isSearchOpen = false;
            _searchQuery = '';
          });
          _searchFocusNode.unfocus();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: Column(
                    children: [
                      // Search Bar when Search Mode is Open
                      if (_isSearchOpen)
                        Container(
                          height: 48,
                          margin: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                          decoration: BoxDecoration(
                            color: const Color(0xCC0D1B2A),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded, size: 20, color: Colors.white70),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _searchCtrl,
                                  focusNode: _searchFocusNode,
                                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                                  style: const TextStyle(fontSize: 15, color: Colors.white),
                                  decoration: const InputDecoration(
                                    hintText: 'Search apps',
                                    hintStyle: TextStyle(fontSize: 15, color: Colors.white38),
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
                                )
                              else
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isSearchOpen = false;
                                      _searchQuery = '';
                                    });
                                    _searchFocusNode.unfocus();
                                  },
                                  child: const Icon(Icons.close_rounded, size: 18, color: Colors.white60),
                                ),
                            ],
                          ),
                        ),

                      // Main List
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
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 14,
                                    shadows: [Shadow(color: Colors.black87, blurRadius: 6)],
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              controller: _scrollCtrl,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 4, 44, 90),
                              itemCount: filtered.length + (_isSearchOpen ? 0 : 2), // Header + Apps + Footer
                              itemBuilder: (context, index) {
                                // In normal mode, index 0 is Clock/Date Header
                                if (!_isSearchOpen && index == 0) {
                                  return _buildClockHeader();
                                }

                                // Bottom Footer section (Niagara Launcher settings etc.)
                                final appIndex = _isSearchOpen ? index : index - 1;
                                if (!_isSearchOpen && appIndex == filtered.length) {
                                  return _buildFooterSection();
                                }

                                final app = filtered[appIndex];
                                final isFirstOfLetter = appIndex == 0 ||
                                    filtered[appIndex - 1].firstLetter != app.firstLetter;

                                final rowWidget = _buildAppRow(app, isFav: favorites.contains(app.packageName));

                                if (isFirstOfLetter && _searchQuery.isEmpty) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        key: _letterKeys[app.firstLetter],
                                        padding: const EdgeInsets.only(left: 18, top: 20, bottom: 6),
                                        child: Text(
                                          app.firstLetter,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(color: Colors.black87, blurRadius: 8, offset: Offset(0, 1)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      rowWidget,
                                    ],
                                  );
                                }
                                return rowWidget;
                              },
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator(color: Colors.white54)),
                          error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Color(0xFFEF4444)))),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Alphabet Wave Scrubber Bar (Stable fixed width)
              if (!_isSearchOpen)
                Positioned(
                  right: 0,
                  top: 60,
                  bottom: 30,
                  width: 44,
                  child: NiagaraWaveScrubber(
                    alphabet: _alphabet,
                    selectedLetter: '',
                    onLetterSelected: _scrollToLetter,
                  ),
                ),

              // Niagara Blue Circular Search FAB at Bottom Right
              if (!_isSearchOpen)
                Positioned(
                  right: 22,
                  bottom: 24,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _isSearchOpen = true);
                      _searchFocusNode.requestFocus();
                    },
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D64A8),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.search_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClockHeader() {
    final now = DateTime.now();
    final hourStr = now.hour.toString().padLeft(2, '0');
    final minStr = now.minute.toString().padLeft(2, '0');
    final timeStr = '$hourStr:$minStr';
    final dateStr = _formatHeaderDate(now);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => ref.read(appLauncherServiceProvider).launchClock(),
            onLongPress: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FitrahSettingsScreen()),
              );
            },
            child: Text(
              timeStr,
              style: const TextStyle(
                fontSize: 54,
                fontWeight: FontWeight.w300,
                color: Colors.white,
                letterSpacing: -1.0,
                height: 1.05,
                shadows: [
                  Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 2)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => ref.read(appLauncherServiceProvider).launchCalendar(),
            child: Text(
              dateStr,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.85),
                shadows: const [
                  Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 1)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppRow(InstalledApp app, {bool isFav = false}) {
    return RepaintBoundary(
      child: InkWell(
        onTap: () => _launchApp(app),
        onLongPress: () => _showAppOptions(app),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Row(
            children: [
              AppIconWidget(
                packageName: app.packageName,
                appName: app.appName,
                size: 44,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      app.appName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        letterSpacing: 0.2,
                        shadows: [
                          Shadow(color: Colors.black87, blurRadius: 8, offset: Offset(0, 1)),
                        ],
                      ),
                    ),
                    if (_isSearchOpen) ...[
                      const SizedBox(height: 1),
                      Text(
                        isFav ? 'Favorit' : app.packageName,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.55),
                          shadows: const [
                            Shadow(color: Colors.black87, blurRadius: 6),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 18, bottom: 8),
            child: Text(
              'Fitrah Launcher',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                shadows: [
                  Shadow(color: Colors.black87, blurRadius: 8, offset: Offset(0, 1)),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FitrahSettingsScreen()),
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.settings_outlined, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Pengaturan Launcher',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Colors.black87, blurRadius: 8, offset: Offset(0, 1)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
