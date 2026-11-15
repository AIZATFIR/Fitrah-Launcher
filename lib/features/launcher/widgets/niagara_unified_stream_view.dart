import 'drawer_preferences_controls.dart';
import 'app_preferences_sheet.dart';
import 'launcher_action_feedback.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../widgets/activity_icon.dart';

import '../models/launcher_settings.dart';
import '../providers/launcher_settings_provider.dart';
import '../services/app_launcher_service.dart';
import '../utils/hijri_date.dart';
import 'app_icon_widget.dart';
import 'fitrah_settings_screen.dart';
import 'launcher_customization_sheet.dart';
import 'niagara_wave_scrubber.dart';
import 'loop_habit_grid_widget.dart';
import 'task_dump_inbox_widget.dart';
import '../../../models/habit_entry.dart';
import '../../../providers/sadar_providers.dart';

/// Unified Niagara-style home stream combining header widget,
/// favorite apps, and the full alphabetical app list with the signature wave scrubber.
class NiagaraUnifiedStreamView extends ConsumerStatefulWidget {
  const NiagaraUnifiedStreamView({
    super.key,
    required this.onOpenFocusClock,
    this.isActive = true,
  });

  final VoidCallback onOpenFocusClock;
  final bool isActive;

  @override
  ConsumerState<NiagaraUnifiedStreamView> createState() =>
      _NiagaraUnifiedStreamViewState();
}

class _NiagaraUnifiedStreamViewState
    extends ConsumerState<NiagaraUnifiedStreamView> {
  late Timer _clockTimer;
  late DateTime _currentTime;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {};

  String _selectedLetter = '★';
  String _searchQuery = '';
  bool _isScrubbing = false;
  int _focusRevision = 0;

  static const List<String> _alphabet = [
    '★',
    '#',
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
  ];

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });

    for (final l in _alphabet) {
      _sectionKeys[l] = GlobalKey();
    }

    _checkAutoFocus();
  }

  @override
  void didUpdateWidget(covariant NiagaraUnifiedStreamView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _focusRevision++;
      if (widget.isActive) {
        _checkAutoFocus();
      } else {
        _searchFocusNode.unfocus();
      }
    }
  }

  Future<void> _checkAutoFocus() async {
    final revision = ++_focusRevision;
    final notifier = ref.read(launcherSettingsProvider.notifier);
    await notifier.hydration;
    if (!mounted ||
        revision != _focusRevision ||
        !widget.isActive ||
        !notifier.isLoaded) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          revision == _focusRevision &&
          widget.isActive &&
          ref.read(launcherSettingsProvider).autoFocusSearch &&
          (ModalRoute.of(context)?.isCurrent ?? true)) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusRevision++;
    _clockTimer.cancel();
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToSection(String letter) {
    setState(() => _selectedLetter = letter);
    if (letter == '★') {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      }
      return;
    }

    final key = _sectionKeys[letter];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
    }
  }

  void _launchApp(InstalledApp app) {
    HapticFeedback.lightImpact();
    runLauncherAction(
      context,
      ref.read(appLauncherServiceProvider),
      (service) => service.launchApp(app.packageName),
    );
  }

  void _showAppOptions(InstalledApp app) {
    showAppPreferences(context, app);
  }

  Map<String, dynamic> _calculateNextPrayer(LauncherSettings settings) {
    final now = _currentTime;
    final curSec = (now.hour * 60 + now.minute) * 60 + now.second;

    final prayers = [
      {'name': 'Subuh', 'time': settings.prayerSubuh},
      {'name': 'Syuruq', 'time': settings.prayerSyuruq},
      {'name': 'Dzuhur', 'time': settings.prayerDzuhur},
      {'name': 'Ashar', 'time': settings.prayerAshar},
      {'name': 'Maghrib', 'time': settings.prayerMaghrib},
      {'name': 'Isya', 'time': settings.prayerIsya},
    ];

    String nextName = 'Subuh';
    int nextSec = 0;

    for (int i = 0; i < prayers.length; i++) {
      final p = prayers[i];
      final parts = (p['time'] as String).split(':');
      final pSec = (int.parse(parts[0]) * 60 + int.parse(parts[1])) * 60;

      if (pSec > curSec) {
        nextName = p['name'] as String;
        nextSec = pSec;
        break;
      }
    }

    if (nextSec == 0) {
      final parts = settings.prayerSubuh.split(':');
      final fajrSec = (int.parse(parts[0]) * 60 + int.parse(parts[1])) * 60;
      nextSec = 24 * 3600 + fajrSec;
      nextName = 'Subuh';
    }

    final diffSec = (nextSec - curSec).clamp(0, 24 * 3600);
    final hours = (diffSec ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((diffSec % 3600) ~/ 60).toString().padLeft(2, '0');

    return {'nextName': nextName, 'countdown': '$hours:$minutes'};
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(launcherSettingsProvider);
    ref.listen(launcherSettingsProvider, (previous, next) {
      if (previous?.autoFocusSearch != next.autoFocusSearch) {
        _focusRevision++;
        if (next.autoFocusSearch && widget.isActive) _checkAutoFocus();
      }
    });
    final appsAsync = ref.watch(installedAppsFutureProvider);
    final favoritePackages = ref.watch(favoritePackagesProvider);
    final hiddenPackages = ref.watch(hiddenPackagesProvider);

    final timeStr = settings.is24h
        ? DateFormat('HH:mm').format(_currentTime)
        : DateFormat('hh:mm').format(_currentTime);
    final periodStr = settings.is24h
        ? ''
        : DateFormat('a').format(_currentTime);
    final dateStr = DateFormat('EEEE, d MMM').format(_currentTime);
    final hijriStr = HijriCalendarHelper.formatHijri(_currentTime);
    final nextPrayer = _calculateNextPrayer(settings);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      body: SafeArea(
        child: Stack(
          children: [
            // Main scrollable Niagara stream
            appsAsync.when(
              data: (allApps) {
                // Filter out hidden bloatware/apps
                final visibleApps =
                    (ref.read(launcherSettingsProvider.notifier).isLoaded
                            ? allApps
                            : <InstalledApp>[])
                        .where((a) => !hiddenPackages.contains(a.packageName))
                        .toList();

                // Filtered apps if searching
                final filtered = _searchQuery.isEmpty
                    ? visibleApps
                    : visibleApps
                          .where(
                            (a) => a.appName.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ),
                          )
                          .toList();

                // Favorite apps
                final favoriteApps = visibleApps
                    .where((a) => favoritePackages.contains(a.packageName))
                    .toList();

                // Group full alphabet
                final Map<String, List<InstalledApp>> grouped = {};
                for (final app in filtered) {
                  final letter = app.firstLetter;
                  grouped.putIfAbsent(letter, () => []).add(app);
                }

                return ListView(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 16, 44, 100),
                  children: [
                    // Top header: Minimalist Clock & Date
                    _buildHeader(
                      timeStr,
                      periodStr,
                      dateStr,
                      hijriStr,
                      nextPrayer,
                    ),
                    const SizedBox(height: 8),

                    // Strategic Visual Cue Card (Goal Cue)
                    _buildSadarStrategicCueCard(),
                    const SizedBox(height: 6),

                    // ── 1. Daily Habits Grid (Loop Style) ──
                    const LoopHabitGridWidget(),
                    const SizedBox(height: 6),

                    // ── 2. Task Dump Inbox (Google Tasks Style) ──
                    TaskDumpInboxWidget(
                      onTaskScheduled: widget.onOpenFocusClock,
                    ),
                    const SizedBox(height: 14),

                    // Search input
                    _buildSearchBar(settings, filtered),
                    const SizedBox(height: 20),

                    if (!ref.read(launcherSettingsProvider.notifier).isLoaded)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ref
                                    .read(launcherSettingsProvider.notifier)
                                    .loadFailed
                                ? 'Gagal memuat preferensi.'
                                : 'Memuat preferensi…',
                          ),
                          if (ref
                              .read(launcherSettingsProvider.notifier)
                              .loadFailed)
                            TextButton(
                              style: TextButton.styleFrom(
                                minimumSize: const Size(48, 48),
                              ),
                              onPressed: ref
                                  .read(launcherSettingsProvider.notifier)
                                  .reload,
                              child: const Text('Coba lagi'),
                            ),
                        ],
                      ),

                    // FAVORITES SECTION (Only if not searching)
                    if (_searchQuery.isEmpty && favoriteApps.isNotEmpty) ...[
                      Container(
                        key: _sectionKeys['★'],
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Color(0xFFE5A93C),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'FAVORIT (${favoriteApps.length})',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: Color(0xFFE5A93C),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...favoriteApps.map(
                        (app) => _buildAppRow(app, isFavorite: true),
                      ),
                      const SizedBox(height: 28),
                      const Divider(color: Color(0xFF222226), height: 1),
                      const SizedBox(height: 20),
                    ],

                    // ALL APPS (ALPHABETICAL)
                    if (filtered.isEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'Tidak ada aplikasi ditemukan.',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      for (final entry in grouped.entries) ...[
                        Container(
                          key: _sectionKeys[entry.key],
                          padding: const EdgeInsets.only(top: 14, bottom: 6),
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: Colors.white.withOpacity(0.4),
                            ),
                          ),
                        ),
                        ...entry.value.map((app) => _buildAppRow(app)),
                      ],
                    ],
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFFE5A93C)),
              ),
              error: (e, _) => LauncherAppListFailure(error: e),
            ),

            // Niagara Signature Curved Wave Alphabet Scrubber (persists when pulled to screen center)
            Positioned(
              right: 0,
              top: 70,
              bottom: 40,
              width: _isScrubbing
                  ? MediaQuery.of(context).size.width * 0.75
                  : 48.0,
              child: NiagaraWaveScrubber(
                alphabet: _alphabet,
                selectedLetter: _selectedLetter,
                onLetterSelected: _scrollToSection,
                onScrubStart: () => setState(() => _isScrubbing = true),
                onScrubEnd: () => setState(() => _isScrubbing = false),
              ),
            ),

            // Top right quick settings & focus clock pills
            Positioned(
              top: 12,
              right: 14,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Focus Clock pill
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onOpenFocusClock();
                    },
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 13,
                            color: Color(0xFFE5A93C),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'CLOCK',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Sadar standalone connector pill
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      runLauncherAction(
                        context,
                        ref.read(appLauncherServiceProvider),
                        (service) => service.launchSadar(),
                      );
                    },
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.wb_sunny_outlined,
                            size: 13,
                            color: Color(0xFF10B981),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'SADAR',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Settings gear
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FitrahSettingsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                        ),
                      ),
                      child: const Icon(
                        Icons.settings_outlined,
                        size: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    String timeStr,
    String periodStr,
    String dateStr,
    String hijriStr,
    Map<String, dynamic> nextPrayer,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_scrollCtrl.hasClients && _scrollCtrl.offset > 40) {
          HapticFeedback.selectionClick();
          _scrollCtrl.animateTo(
            0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
          );
        }
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const LauncherCustomizationSheet(),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time (Tap launches Clock / Alarm)
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              runLauncherAction(
                context,
                ref.read(appLauncherServiceProvider),
                (service) => service.launchClock(),
              );
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 54,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                if (periodStr.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    periodStr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Date & Hijri (Tap launches Calendar)
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              runLauncherAction(
                context,
                ref.read(appLauncherServiceProvider),
                (service) => service.launchCalendar(),
              );
            },
            child: Row(
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 3,
                  height: 3,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white30,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  hijriStr,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),

          // Next Prayer Pill
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const LauncherCustomizationSheet(),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.wb_twilight_rounded,
                    size: 12,
                    color: Color(0xFFE5A93C),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${nextPrayer['nextName']}: ${nextPrayer['countdown']}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
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

  Widget _buildSearchBar(
    LauncherSettings settings,
    List<InstalledApp> filtered,
  ) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 18, color: Colors.white38),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocusNode,
              onChanged: (val) => setState(() => _searchQuery = val),
              onSubmitted: (_) {
                if (filtered.isNotEmpty) {
                  _launchApp(filtered.first);
                  _searchCtrl.clear();
                  setState(() => _searchQuery = '');
                }
              },
              style: const TextStyle(fontSize: 14, color: Colors.white),
              decoration: InputDecoration(
                hintText: _searchQuery.isEmpty
                    ? 'Cari aplikasi...'
                    : (filtered.isNotEmpty
                          ? 'Buka ${filtered.first.appName}'
                          : 'Cari aplikasi...'),
                hintStyle: const TextStyle(fontSize: 14, color: Colors.white38),
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
              child: const Icon(
                Icons.clear_rounded,
                size: 16,
                color: Colors.white60,
              ),
            ),
          const SizedBox(width: 8),
          // Auto keyboard toggle
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: const Color(0xFF161618),
                builder: (_) => const SafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: DrawerPreferencesControls(keyboardOnly: true),
                  ),
                ),
              );
            },
            child: Icon(
              Icons.keyboard_rounded,
              size: 18,
              color: settings.autoFocusSearch
                  ? const Color(0xFFE5A93C)
                  : Colors.white24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppRow(InstalledApp app, {bool isFavorite = false}) {
    return InkWell(
      onTap: () => _launchApp(app),
      onLongPress: () => _showAppOptions(app),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 34),
          child: Row(
            children: [
              if (ref.read(launcherSettingsProvider).showAppIcons) ...[
                AppIconWidget(
                  packageName: app.packageName,
                  appName: app.appName,
                  size: 42,
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Text(
                  app.appName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isFavorite ? FontWeight.w700 : FontWeight.w500,
                    color: Colors.white.withOpacity(0.92),
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isFavorite)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: Color(0xFFE5A93C),
                  ),
                ),
              GestureDetector(
                onTap: () => _showAppOptions(app),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.more_vert_rounded,
                    size: 16,
                    color: Colors.white.withOpacity(0.25),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSadarStrategicCueCard() {
    final todayStr = DateFormat('yyyy-MM-dd').format(_currentTime);
    final habitsAsync = ref.watch(habitsStreamProvider);
    final entriesRange = DateRangeQuery(start: todayStr, end: todayStr);
    final entriesAsync = ref.watch(habitEntriesStreamProvider(entriesRange));

    return habitsAsync.when(
      data: (habits) {
        if (habits.isEmpty) return const SizedBox.shrink();

        final entriesList = entriesAsync.value ?? [];
        final entriesMap = {for (final e in entriesList) e.habitId: e};

        final completedHabits = habits
            .where((h) => entriesMap[h.id]?.status == HabitStatus.yes)
            .toList();
        final pendingHabits = habits
            .where((h) => entriesMap[h.id]?.status != HabitStatus.yes)
            .toList();
        final nextHabit = pendingHabits.isNotEmpty ? pendingHabits.first : null;

        final total = habits.length;
        final done = completedHabits.length;
        final ratio = total > 0 ? (done / total).clamp(0.0, 1.0) : 0.0;
        final isAllDone = total > 0 && done == total;

        return Container(
          margin: const EdgeInsets.only(top: 8, bottom: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF18171E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isAllDone
                  ? const Color(0xFF10B981).withOpacity(0.35)
                  : const Color(0xFFF0C987).withOpacity(0.28),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: status pill + count
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isAllDone
                          ? const Color(0xFF10B981).withOpacity(0.15)
                          : const Color(0xFFF0C987).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isAllDone
                            ? const Color(0xFF10B981).withOpacity(0.3)
                            : const Color(0xFFF0C987).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAllDone
                              ? Icons.check_circle_rounded
                              : Icons.bolt_rounded,
                          size: 12,
                          color: isAllDone
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF0C987),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isAllDone
                              ? 'HARI INI TERPENUHI'
                              : 'FOKUS & ARAH HARI INI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: isAllDone
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF0C987),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      runLauncherAction(
                        context,
                        ref.read(appLauncherServiceProvider),
                        (service) => service.launchSadar(),
                      );
                    },
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$done/$total selesai (${(ratio * 100).toInt()}%)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9E9DA6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 5,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isAllDone
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF0C987),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              if (!isAllDone && nextHabit != null) ...[
                const Text(
                  'LANGKAH STRATEGIS SEKARANG:',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Color(0xFF8A8993),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ActivityIcon(
                      iconKey: nextHabit.iconKey,
                      size: 24,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nextHabit.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: 6,
                            children: [
                              Text(
                                nextHabit.habitType == 'timed'
                                    ? 'Target ${nextHabit.target} Menit'
                                    : 'Target ${nextHabit.target} kali',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFF0C987),
                                ),
                              ),
                              const Text(
                                '• Buka Laptop & Mulai',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF8A8993),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Action buttons: 1-Tap Play Timer + Open Sadar
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFF0C987),
                          foregroundColor: const Color(0xFF12100E),
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          widget.onOpenFocusClock();
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow_rounded, size: 18),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Buka Laptop & Play Timer',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.08),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 17),
                      tooltip: 'Buka Sadar',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        runLauncherAction(
                          context,
                          ref.read(appLauncherServiceProvider),
                          (service) => service.launchSadar(),
                        );
                      },
                    ),
                  ],
                ),

                if (pendingHabits.length > 1) ...[
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFF26252E), height: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.hourglass_empty_rounded,
                        size: 11,
                        color: Color(0xFF8A8993),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Kurang:',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8A8993),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: pendingHabits.skip(1).map((h) {
                              return GestureDetector(
                                onTap: () => runLauncherAction(
                                  context,
                                  ref.read(appLauncherServiceProvider),
                                  (service) => service.launchSadar(),
                                ),
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
                                  ),
                                  alignment: Alignment.center,
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.08),
                                    ),
                                  ),
                                  child: Text(
                                    h.name,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF9E9DA6),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ] else ...[
                const Text(
                  'Semua janji hari ini terpenuhi.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Energi telah dialokasikan dengan sadar dan tenang.',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF8A8993)),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
