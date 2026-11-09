import '../../launcher/widgets/launcher_action_feedback.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/habit.dart';
import '../../../models/timer_session.dart';
import '../../../providers/providers.dart';
import '../../../providers/sadar_providers.dart';
import '../../launcher/services/app_launcher_service.dart';
import '../../../services/chime_service.dart';
import '../../../services/sadar_timer_engine.dart';

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
  bool _isStarting = true;
  bool _hasSessionConflict = false;
  bool _isSaving = false;
  bool _hasChimed = false;
  String? _actionError;

  Timer? _appGuardTimer;

  // Emergency Exit Hold State
  double _holdProgress = 0.0;
  Timer? _holdTimer;

  static const MethodChannel _channel = MethodChannel('fitrah_launcher/apps');

  @override
  void initState() {
    super.initState();
    // Enable sticky immersive fullscreen and lockscreen display
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _channel
        .invokeMethod('setLockscreenFocus', {'enabled': true})
        .catchError((_) => null);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _attachSharedTimer();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _channel
        .invokeMethod('setLockscreenFocus', {'enabled': false})
        .catchError((_) => null);
    _appGuardTimer?.cancel();
    _holdTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _attachSharedTimer() async {
    try {
      final attached = await ref
          .read(timerEngineProvider.notifier)
          .startYpt(widget.habit);
      if (!mounted) return;
      final timer = ref.read(timerEngineProvider);
      setState(() {
        _hasSessionConflict =
            !attached &&
            !(timer.isSavePending &&
                timer.habitId == widget.habit.id &&
                timer.sourceKind == TimerSessionSourceKind.yptHabit);
        _isStarting = false;
      });
      if (attached) _startAppGuard();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _actionError = 'Timer belum tersimpan: $error';
        _isStarting = false;
      });
    }
  }

  void _startAppGuard() {
    if (kIsWeb || widget.habit.allowedPackages.isEmpty) return;
    _appGuardTimer?.cancel();
    _appGuardTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final timer = ref.read(timerEngineProvider);
      if (!mounted ||
          timer.isPaused ||
          timer.isCompleted ||
          _hasSessionConflict) {
        return;
      }
      try {
        final currentFgApp = await _channel.invokeMethod<String>(
          'getForegroundApp',
        );
        if (currentFgApp != null && currentFgApp.isNotEmpty) {
          // Check if foreground app is allowed
          final allowed = widget.habit.allowedPackages;
          final isAllowed =
              allowed.contains(currentFgApp) ||
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

  Future<void> _togglePause() async {
    HapticFeedback.selectionClick();
    final engine = ref.read(timerEngineProvider.notifier);
    try {
      if (engine.currentState.isPaused) {
        await engine.resume();
      } else {
        await engine.pause();
      }
      if (mounted) setState(() => _actionError = null);
    } catch (error) {
      if (mounted) {
        setState(() => _actionError = 'Perubahan belum tersimpan: $error');
      }
    }
  }

  Future<void> _finish() async {
    if (_isSaving) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);
    final engine = ref.read(timerEngineProvider.notifier);
    try {
      if (engine.currentState.isSavePending) {
        await engine.retryCompletion();
      } else if (engine.currentState.isCompleted) {
        widget.onClose();
        return;
      } else {
        await engine.finishEarly();
      }
      ref.invalidate(habitsStreamProvider);
      ref.invalidate(dailyFulfillmentProvider);
      ref.invalidate(whatIRepeatProvider);
      ref.invalidate(awarenessStatsProvider);
      if (mounted && !engine.currentState.isSavePending) widget.onClose();
    } catch (error) {
      if (mounted) {
        setState(() => _actionError = 'Sesi belum tersimpan: $error');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _cancelAndClose() async {
    try {
      final engine = ref.read(timerEngineProvider.notifier);
      if (engine.currentState.isSavePending) {
        throw StateError('Sesi selesai menunggu penyimpanan.');
      }
      await engine.cancel();
      if (mounted) widget.onClose();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi belum bisa dibatalkan. Coba lagi.'),
          ),
        );
      }
    }
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
          _cancelAndClose();
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
    final timer = ref.watch(timerEngineProvider);
    ref.listen<TimerState>(timerEngineProvider, (previous, next) {
      if (previous?.remainingSeconds != 0 && next.isOverdue && !_hasChimed) {
        _hasChimed = true;
        ChimeService().playTwingChime();
        HapticFeedback.heavyImpact();
        ref
            .read(notificationServiceProvider)
            .showNotification(
              id: widget.habit.id,
              title: 'Waktu Selesai! 🎯',
              body:
                  'Target "${widget.habit.name}" tercapai. Waktu ekstra tetap dihitung.',
            );
      }
    });
    final installedAppsAsync = ref.watch(installedAppsFutureProvider);

    if (_isStarting) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_hasSessionConflict ||
        (_actionError != null &&
            !timer.isActive &&
            !timer.isSavePending &&
            !timer.isCompleted)) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _actionError ??
                        timer.restoreError ??
                        'Sesi lain sedang berjalan. Selesaikan atau jeda dulu.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  TextButton(
                    onPressed: widget.onClose,
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Top Bar: Habit Pill & Emergency Exit Indicator
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                // Habit badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF141416),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: habitColor.withOpacity(0.4),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget.habit.iconKey,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          widget.habit.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // YPT Tag
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF27272A),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.lock_clock_rounded,
                                        color: Color(0xFFF59E0B),
                                        size: 14,
                                      ),
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
                                  timer.isOverdue
                                      ? '+${_formatTime((timer.actualDurationSeconds - timer.targetSeconds).clamp(0, 999999))}'
                                      : _formatTime(timer.remainingSeconds),
                                  style: TextStyle(
                                    fontSize: 76,
                                    fontWeight: FontWeight.w800,
                                    color: timer.isOverdue
                                        ? const Color(0xFFF59E0B)
                                        : Colors.white,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                    letterSpacing: -2.0,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  timer.isCompleted && !timer.isSavePending
                                      ? '🎉 Target Tercapai! Alhamdulillah'
                                      : (timer.isPaused
                                            ? '⏸️ Sesi Dijeda'
                                            : (timer.isOverdue
                                                  ? '🔥 Waktu Tambahan Ekstra Fokus'
                                                  : 'Tetap fokus & sadar')),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: timer.isOverdue
                                        ? const Color(0xFFFBBF24)
                                        : Colors.white54,
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
                                    padding: EdgeInsets.only(
                                      left: 4,
                                      bottom: 8,
                                    ),
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
                                    skipLoadingOnRefresh: false,
                                    data: (apps) {
                                      final allowed = apps
                                          .where(
                                            (a) => widget.habit.allowedPackages
                                                .contains(a.packageName),
                                          )
                                          .toList();
                                      if (allowed.isEmpty) {
                                        return const Text(
                                          'Aplikasi yang diizinkan tidak tersedia di perangkat ini. Pilihan tersimpan tetap aman.',
                                          style: TextStyle(
                                            color: Colors.white70,
                                          ),
                                        );
                                      }
                                      return SizedBox(
                                        height: 48,
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: allowed.length,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(width: 10),
                                          itemBuilder: (ctx, idx) {
                                            final app = allowed[idx];
                                            return InkWell(
                                              onTap: () {
                                                HapticFeedback.lightImpact();
                                                runLauncherAction(
                                                  context,
                                                  ref.read(
                                                    appLauncherServiceProvider,
                                                  ),
                                                  (service) =>
                                                      service.launchApp(
                                                        app.packageName,
                                                      ),
                                                );
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF1C1C20,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  border: Border.all(
                                                    color: Colors.white24,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.open_in_new_rounded,
                                                      size: 14,
                                                      color: Colors.white70,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      app.appName,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                    loading: () => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    error: (e, _) =>
                                        LauncherAppListFailure(error: e),
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
                                        onTap: _isSaving || timer.isCompleted
                                            ? null
                                            : _togglePause,
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          constraints: const BoxConstraints(
                                            minHeight: 52,
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1E1E22),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: Colors.white24,
                                            ),
                                          ),
                                          child: Center(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  timer.isPaused
                                                      ? Icons.play_arrow_rounded
                                                      : Icons.pause_rounded,
                                                  color: Colors.white,
                                                  size: 22,
                                                ),
                                                const SizedBox(width: 8),
                                                Flexible(
                                                  child: Text(
                                                    timer.isPaused
                                                        ? 'Lanjutkan'
                                                        : 'Jeda',
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                  ),
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
                                        onTap: _isSaving ? null : _finish,
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          constraints: const BoxConstraints(
                                            minHeight: 52,
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                habitColor,
                                                habitColor.withOpacity(0.8),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Center(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.check_rounded,
                                                  color: Colors.black,
                                                  size: 22,
                                                ),
                                                SizedBox(width: 8),
                                                Flexible(
                                                  child: Text(
                                                    timer.isSavePending
                                                        ? 'Coba lagi'
                                                        : 'Selesai',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_actionError != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _actionError!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.orangeAccent,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),

                                // Emergency Exit (Hold 3 seconds - 100% Anti-Brick/Nyangkut Guarantee)
                                GestureDetector(
                                  onTapDown: (_) => _startHoldExit(),
                                  onTapUp: (_) => _cancelHoldExit(),
                                  onTapCancel: () => _cancelHoldExit(),
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minHeight: 48,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.red.withOpacity(0.35),
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        // Fill progress
                                        if (_holdProgress > 0)
                                          Positioned.fill(
                                            child: FractionallySizedBox(
                                              widthFactor: _holdProgress,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withOpacity(
                                                    0.3,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                            ),
                                          ),
                                        Center(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.shield_outlined,
                                                size: 16,
                                                color: Color(0xFFEF4444),
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  _holdProgress > 0
                                                      ? 'Menahan... (${((1.0 - _holdProgress) * 3).toStringAsFixed(1)}s)'
                                                      : 'Tahan 3 Detik untuk Keluar Darurat',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFFEF4444),
                                                  ),
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
