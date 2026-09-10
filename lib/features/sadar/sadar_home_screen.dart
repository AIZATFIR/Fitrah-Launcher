import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/habit.dart';
import '../../providers/sadar_providers.dart';
import '../../services/sadar_timer_engine.dart';
import '../../services/secure_storage_service.dart';
import 'widgets/awareness_view.dart';
import 'widgets/daily_fulfillment_banner.dart';
import 'widgets/desktop_floating_timer.dart';
import 'widgets/habit_editor_sheet.dart';
import 'widgets/horizontal_timeline_grid.dart';
import 'widgets/onboarding_view.dart';
import 'widgets/today_view.dart';
import 'widgets/what_i_repeat_view.dart';

class SadarHomeScreen extends ConsumerStatefulWidget {
  const SadarHomeScreen({
    super.key,
    this.onBack,
  });

  final VoidCallback? onBack;

  @override
  ConsumerState<SadarHomeScreen> createState() => _SadarHomeScreenState();
}

class _SadarHomeScreenState extends ConsumerState<SadarHomeScreen> {
  int _currentTabIndex = 0;
  bool? _isOnboardingDone;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final done = await ref.read(secureStorageServiceProvider).isSadarOnboardingDone();
      if (mounted) {
        setState(() => _isOnboardingDone = done);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isOnboardingDone = true);
      }
    }
  }

  void _openHabitEditor([Habit? habit]) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => HabitEditorSheet(
        habit: habit,
        onSaved: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _showPhilosophyDialog() {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppPalette.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppPalette.stroke),
        ),
        title: const Row(
          children: [
            Icon(Icons.spa_rounded, color: AppPalette.accent, size: 22),
            SizedBox(width: 8),
            Text(
              'Filosofi Sadar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppPalette.text),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"Until you make the unconscious conscious, it will direct your life and you will call it fate."',
              style: TextStyle(fontStyle: FontStyle.italic, color: AppPalette.text, height: 1.4),
            ),
            SizedBox(height: 14),
            Text(
              'Sadar bukan sekadar pelacak kebiasaan, melainkan kompas kesadaran harian.\n\n'
              'Pertanyaannya bukan: "Seberapa produktif saya?"\n'
              'Melainkan: "Apakah saya menjalani hari ini dengan cara yang bisa saya hargai?"\n\n'
              '• Kesadaran: Apa yang tidak kau sadari akan mengarahkan hidupmu.\n'
              '• Pengulangan: Apa yang berulang kali kau lakukan membentuk dirimu.\n'
              '• Pemenuhan Diri: Menepati janji pada diri sendiri.',
              style: TextStyle(fontSize: 13, color: AppPalette.textDim, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _isOnboardingDone = false);
            },
            child: const Text('Buka Panduan', style: TextStyle(color: AppPalette.textDim)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Saya Mengerti', style: TextStyle(color: AppPalette.accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTab() {
    final habitsAsync = ref.watch(habitsStreamProvider);
    final selectedDate = ref.watch(sadarSelectedDateProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DailyFulfillmentBanner(
              selectedDate: selectedDate,
              isShowingAwareness: false,
              onToggleAwareness: () {
                setState(() => _currentTabIndex = 3);
              },
            ),
            const SizedBox(height: 16),
            habitsAsync.when(
              data: (habits) => HorizontalTimelineGrid(
                habits: habits,
                onEditHabit: (h) => _openHabitEditor(h),
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Center(
                child: Text('Error: $err', style: const TextStyle(color: Color(0xFFEF4444))),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    // 1. Desktop Floating Timer Mode check
    final isFloating = ref.watch(timerEngineProvider.select((s) => s.isFloating));
    if (isFloating) {
      return const DesktopFloatingTimer();
    }

    // 2. First Launch Onboarding Check
    if (_isOnboardingDone == false) {
      return OnboardingView(
        onComplete: () async {
          await ref.read(secureStorageServiceProvider).setSadarOnboardingDone(true);
          if (mounted) {
            setState(() => _isOnboardingDone = true);
          }
        },
      );
    }

    if (_isOnboardingDone == null) {
      return const Scaffold(
        backgroundColor: AppPalette.bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 3. Main Multi-Screen Tab Interface
    return Scaffold(
      backgroundColor: AppPalette.bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: AppBar(
              backgroundColor: AppPalette.bg,
              elevation: 0,
              leading: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: AppPalette.accent, size: 20),
                      tooltip: 'Kembali',
                      onPressed: widget.onBack,
                    )
                  : null,
              title: const Column(
                children: [
                  Text(
                    'SADAR',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3.5,
                      color: AppPalette.text,
                    ),
                  ),
                  Text(
                    'Way of Life',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.8,
                      color: AppPalette.textDim,
                    ),
                  ),
                ],
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.info_outline_rounded, color: AppPalette.textDim, size: 20),
                  tooltip: 'Filosofi Sadar',
                  onPressed: _showPhilosophyDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.add_rounded, color: AppPalette.accent, size: 22),
                  tooltip: 'Tambah Kebiasaan',
                  onPressed: () => _openHabitEditor(),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _currentTabIndex,
          children: [
            const TodayView(),
            _buildTimelineTab(),
            const WhatIRepeatView(),
            const AwarenessView(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppPalette.card,
          border: Border(top: BorderSide(color: AppPalette.stroke, width: 1.0)),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                backgroundColor: AppPalette.card,
                indicatorColor: AppPalette.accent.withValues(alpha: 0.2),
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  final isSelected = states.contains(WidgetState.selected);
                  return TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppPalette.accent : AppPalette.textDim,
                  );
                }),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  final isSelected = states.contains(WidgetState.selected);
                  return IconThemeData(
                    size: 20,
                    color: isSelected ? AppPalette.accent : AppPalette.textDim,
                  );
                }),
              ),
              child: NavigationBar(
                selectedIndex: _currentTabIndex,
                height: 62,
                elevation: 0,
                onDestinationSelected: (index) {
                  HapticFeedback.selectionClick();
                  setState(() => _currentTabIndex = index);
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.wb_sunny_outlined),
                    selectedIcon: Icon(Icons.wb_sunny_rounded),
                    label: 'Hari Ini',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.calendar_view_week_outlined),
                    selectedIcon: Icon(Icons.calendar_view_week_rounded),
                    label: 'Linimasa',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.repeat_rounded),
                    selectedIcon: Icon(Icons.repeat_on_rounded),
                    label: 'Repetisi',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.insights_outlined),
                    selectedIcon: Icon(Icons.insights_rounded),
                    label: 'Kesadaran',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
