import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/habit.dart';
import '../../providers/sadar_providers.dart';
import 'widgets/awareness_view.dart';
import 'widgets/daily_fulfillment_banner.dart';
import 'widgets/habit_editor_sheet.dart';
import 'widgets/horizontal_timeline_grid.dart';

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
  bool _showAwareness = false;

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
            SizedBox(height: 12),
            Text(
              'Aplikasi ini tidak dirancang untuk memaksakan streak atau angka persentase dingin.\n\n'
              'Tujuannya adalah membantumu menyadari hal-hal yang benar-benar bermakna bagimu, '
              'mengulangnya setiap hari, dan menutup hari dengan perasaan bangga atas apa yang kau jalani.',
              style: TextStyle(fontSize: 13, color: AppPalette.textDim, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Saya Mengerti', style: TextStyle(color: AppPalette.accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsStreamProvider);
    final selectedDate = ref.watch(sadarSelectedDateProvider);

    return Scaffold(
      backgroundColor: AppPalette.bg,
      appBar: AppBar(
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
                letterSpacing: 3.0,
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Fulfillment Header
                DailyFulfillmentBanner(
                  selectedDate: selectedDate,
                  isShowingAwareness: _showAwareness,
                  onToggleAwareness: () {
                    HapticFeedback.selectionClick();
                    setState(() => _showAwareness = !_showAwareness);
                  },
                ),

                const SizedBox(height: 16),

                // 2. Timeline Grid or Awareness Analytics
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _showAwareness
                      ? const AwarenessView()
                      : habitsAsync.when(
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
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppPalette.accent,
        foregroundColor: Colors.black,
        elevation: 3,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Kebiasaan Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        onPressed: () => _openHabitEditor(),
      ),
    );
  }
}
