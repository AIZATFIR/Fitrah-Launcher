import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../services/sadar_timer_engine.dart';

class DesktopFloatingTimer extends ConsumerWidget {
  const DesktopFloatingTimer({super.key});

  String _format(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(timerEngineProvider);
    final engine = ref.read(timerEngineProvider.notifier);

    return Scaffold(
      backgroundColor: AppPalette.bg,
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppPalette.card,
          border: Border.all(color: AppPalette.accent.withValues(alpha: 0.6), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title & Expand button
            Row(
              children: [
                Expanded(
                  child: Text(
                    timer.habitName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppPalette.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: () => engine.restoreNormalWindow(),
                  child: const Icon(Icons.open_in_full_rounded, size: 14, color: AppPalette.textDim),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Big readable timer
            Text(
              _format(timer.remainingSeconds),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w300,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (timer.isRunning) {
                      engine.pause();
                    } else {
                      engine.resume();
                    }
                  },
                  child: Icon(
                    timer.isRunning ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                    size: 26,
                    color: AppPalette.accent,
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    engine.finishEarly();
                    engine.restoreNormalWindow();
                  },
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 24,
                    color: Color(0xFF22C55E),
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    engine.cancel();
                    engine.restoreNormalWindow();
                  },
                  child: const Icon(
                    Icons.stop_circle_outlined,
                    size: 24,
                    color: AppPalette.textDim,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
