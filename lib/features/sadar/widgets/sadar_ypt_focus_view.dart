import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/habit.dart';
import '../../../models/habit_entry.dart';
import '../../../providers/providers.dart';
import '../../../providers/sadar_providers.dart';
import '../../launcher/services/app_launcher_service.dart';
import '../../../services/chime_service.dart';

class SadarYptFocusView extends ConsumerStatefulWidget {
  const SadarYptFocusView({
    super.key,
    required this.habit,
    required this.onClose,
  });

  final Habit habit;
  final VoidCallback onClose;

  @override
  ConsumerState<SadarYptFocusView> createState() => _SadarYptFocusViewState();
}

class _SadarYptFocusViewState extends ConsumerState<SadarYptFocusView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  bool _isPaused = false;
  bool _isCompleted = false;
  bool _isOverdue = false;
  bool _hasChimed = false;

  Timer? _ticker;
  Timer? _appGuardTimer;
  late int _totalSeconds;
  late int _remainingSeconds;
  int _overdueSeconds = 0;
  DateTime? _pausedAt;
  late DateTime _targetEndTime;

  // Emergency Exit Hold State
  double _holdProgress = 0.0;
  Timer? _holdTimer;

  static const MethodChannel _channel = MethodChannel('fitrah_launcher/apps');

  @override
  void initState() {
    super.initState();
    // Enable sticky immersive fullscreen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    final minutes = widget.habit.target > 0 ? widget.habit.target : 25;
    _totalSeconds = minutes * 60;
    _remainingSeconds = _totalSeconds;
    _targetEndTime = DateTime.now().add(Duration(seconds: _totalSeconds));

    _startTimer();
    _startAppGuard();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _ticker?.cancel();
    _appGuardTimer?.cancel();
    _holdTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused && mounted) {
        final now = DateTime.now();
        final diff = _targetEndTime.difference(now).inSeconds;
        setState(() {
          if (diff <= 0) {
            _remainingSeconds = 0;
            _isOverdue = true;
            _overdueSeconds = diff.abs();

            if (!_hasChimed) {
              _hasChimed = true;
              ChimeService().playTwingChime();
              HapticFeedback.heavyImpact();
              try {
                ref.read(notificationServiceProvider).showNotification(
                  id: widget.habit.id,
                  title: 'Waktu Selesai! 🎯',
                  body: 'Target "${widget.habit.name}" telah tercapai!',
                );
              } catch (_) {}
            }
          } else {
            _remainingSeconds = diff.clamp(0, _totalSeconds);
          }
        });
      }
    });
  }

  void _startAppGuard() {
    if (kIsWeb || widget.habit.allowedPackages.isEmpty) return;
    _appGuardTimer?.cancel();
    _appGuardTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted || _isPaused || _isCompleted) return;
      try {
        final currentFgApp = await _channel.invokeMethod<String>('getForegroundApp');
        if (currentFgApp != null && currentFgApp.isNotEmpty) {
          // Check if foreground app is allowed
          final allowed = widget.habit.allowedPackages;
          final isAllowed = allowed.contains(currentFgApp) ||
              currentFgApp == 'com.aizatfir.sadar' ||
              currentFgApp == 'com.aizatfir.focus_clock' ||
              currentFgApp.contains('launcher');

          if (!isAllowed) {
            // Bring back to Sadar with gentle haptic
            await _channel.invokeMethod('bringAppToFront');
            if (mounted) {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF1F1F24),
                  duration: const Duration(seconds: 2),
                  content: Text(
                    'Mode YPT Aktif: Tetap fokus pada ${widget.habit.name}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              );
            }
          }
        }
      } catch (_) {}
    });
  }

  void _togglePause() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_isPaused) {
        if (_pausedAt != null) {
          final pauseDuration = DateTime.now().difference(_pausedAt!);
          _targetEndTime = _targetEndTime.add(pauseDuration);
        }
        _isPaused = false;
      } else {
        _pausedAt = DateTime.now();
        _isPaused = true;
      }
    });
  }

  Future<void> _finish() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isCompleted = true;
    });
    _ticker?.cancel();
    _appGuardTimer?.cancel();
    await _autoRecordCompletion();
  }

  Future<void> _autoRecordCompletion() async {
    final now = DateTime.now();
    final dateStr = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final totalElapsedSecs = _totalSeconds - _remainingSeconds + _overdueSeconds;
    final elapsedMinutes = (totalElapsedSecs / 60).ceil().clamp(1, 999);

    await ref.read(sadarRepoProvider).recordEntryStatus(
      habitId: widget.habit.id,
      dateString: dateStr,
      status: HabitStatus.yes,
      valueCompleted: elapsedMinutes,
      completedAt: now,
      source: 'ypt_timer',
    );

    ref.invalidate(habitsStreamProvider);
    ref.invalidate(dailyFulfillmentProvider);
    ref.invalidate(whatIRepeatProvider);
    ref.invalidate(awarenessStatsProvider);
  }

  void _startHoldExit() {
    HapticFeedback.lightImpact();
    _holdTimer?.cancel();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _holdProgress += 0.05 / 3.0; // 3 seconds to complete
        if (_holdProgress >= 1.0) {
          _holdProgress = 1.0;
          timer.cancel();
          HapticFeedback.heavyImpact();
          widget.onClose();
        }
      });
    });
  }

  void _cancelHoldExit() {
    _holdTimer?.cancel();
    setState(() {
      _holdProgress = 0.0;
    });
  }

  String _formatTime(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final habitColor = Color(widget.habit.colorValue);
    final installedAppsAsync = ref.watch(installedAppsFutureProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient Radial Glow
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (context, child) {
                  final scale = 0.8 + (_pulseCtrl.value * 0.4);
                  return Center(
                    child: Container(
                      width: 320 * scale,
                      height: 320 * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            habitColor.withOpacity(0.18),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Main Content
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Bar: Habit Pill & Emergency Exit Indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Habit badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141416),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: habitColor.withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(widget.habit.iconKey, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Text(
                                  widget.habit.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // YPT Tag
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF27272A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.lock_clock_rounded, color: Color(0xFFF59E0B), size: 14),
                                SizedBox(width: 5),
                                Text(
                                  'YPT LOCK',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFF59E0B),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Center: Huge Digital Clock with Pulse
                      Column(
                        children: [
                          Text(
                            _isOverdue ? '+${_formatTime(_overdueSeconds)}' : _formatTime(_remainingSeconds),
                            style: TextStyle(
                              fontSize: 76,
                              fontWeight: FontWeight.w800,
                              color: _isOverdue ? const Color(0xFFF59E0B) : Colors.white,
                              fontFeatures: const [FontFeature.tabularFigures()],
                              letterSpacing: -2.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isCompleted
                                ? '🎉 Target Tercapai! Alhamdulillah'
                                : (_isPaused ? '⏸️ Sesi Dijeda' : (_isOverdue ? '🔥 Waktu Tambahan Ekstra Fokus' : 'Tetap fokus & sadar')),
                            style: TextStyle(
                              fontSize: 14,
                              color: _isOverdue ? const Color(0xFFFBBF24) : Colors.white54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      // Whitelisted / Allowed Apps Bar
                      if (widget.habit.allowedPackages.isNotEmpty) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 8),
                              child: Text(
                                'APLIKASI DIIZINKAN (ALLOWED)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white38,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            installedAppsAsync.when(
                              data: (apps) {
                                final allowed = apps
                                    .where((a) => widget.habit.allowedPackages.contains(a.packageName))
                                    .toList();
                                if (allowed.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return SizedBox(
                                  height: 48,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: allowed.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                                    itemBuilder: (ctx, idx) {
                                      final app = allowed[idx];
                                      return InkWell(
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          ref.read(appLauncherServiceProvider).launchApp(app.packageName);
                                        },
                                        borderRadius: BorderRadius.circular(14),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1C1C20),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(color: Colors.white24),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.open_in_new_rounded, size: 14, color: Colors.white70),
                                              const SizedBox(width: 8),
                                              Text(
                                                app.appName,
                                                style: const TextStyle(fontSize: 13, color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ],

                      // Bottom Controls: Pause, Finish, & 3s Safety Exit
                      Column(
                        children: [
                          Row(
                            children: [
                              // Pause / Resume
                              Expanded(
                                child: InkWell(
                                  onTap: _togglePause,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E1E22),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _isPaused ? 'Lanjutkan' : 'Jeda',
                                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Selesai (Finish)
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    _finish();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Sesi fokus selesai & tercatat!')),
                                    );
                                    widget.onClose();
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    height: 52,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [habitColor, habitColor.withOpacity(0.8)],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.check_rounded, color: Colors.black, size: 22),
                                          SizedBox(width: 8),
                                          Text(
                                            'Selesai',
                                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Emergency Exit (Hold 3 seconds - 100% Anti-Brick/Nyangkut Guarantee)
                          GestureDetector(
                            onTapDown: (_) => _startHoldExit(),
                            onTapUp: (_) => _cancelHoldExit(),
                            onTapCancel: () => _cancelHoldExit(),
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.withOpacity(0.35)),
                              ),
                              child: Stack(
                                children: [
                                  // Fill progress
                                  if (_holdProgress > 0)
                                    FractionallySizedBox(
                                      widthFactor: _holdProgress,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.shield_outlined, size: 16, color: Color(0xFFEF4444)),
                                        const SizedBox(width: 8),
                                        Text(
                                          _holdProgress > 0
                                              ? 'Menahan... (${((1.0 - _holdProgress) * 3).toStringAsFixed(1)}s)'
                                              : 'Tahan 3 Detik untuk Keluar Darurat',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFFEF4444),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
