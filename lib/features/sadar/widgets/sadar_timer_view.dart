import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../models/habit.dart';
import '../../../providers/sadar_providers.dart';
import '../../../services/sadar_timer_engine.dart';

class SadarTimerView extends ConsumerStatefulWidget {
  const SadarTimerView({super.key, required this.habit, required this.onClose});

  final Habit habit;
  final VoidCallback onClose;

  @override
  ConsumerState<SadarTimerView> createState() => _SadarTimerViewState();
}

class _SadarTimerViewState extends ConsumerState<SadarTimerView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  bool _isLoadingSession = true;
  bool _hasSessionConflict = false;
  bool _couldNotStart = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Enable immersive fullscreen on mobile for total focus
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _attachToSession();
  }

  Future<void> _attachToSession() async {
    if (mounted && !_isLoadingSession) {
      setState(() {
        _isLoadingSession = true;
        _couldNotStart = false;
        _hasSessionConflict = false;
      });
    }
    try {
      final engine = ref.read(timerEngineProvider.notifier);
      final attached = await engine.start(widget.habit);
      if (!mounted) return;
      setState(() {
        _isLoadingSession = false;
        _hasSessionConflict = !attached && !engine.currentState.isSavePending;
        _couldNotStart = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingSession = false;
        _couldNotStart = true;
      });
    }
  }

  Future<void> _togglePause() async {
    HapticFeedback.selectionClick();
    final messenger = ScaffoldMessenger.of(context);
    final engine = ref.read(timerEngineProvider.notifier);
    try {
      if (engine.currentState.isPaused) {
        await engine.resume();
      } else {
        await engine.pause();
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Perubahan belum tersimpan. Coba lagi.'),
          ),
        );
      }
    }
  }

  Future<void> _finish() async {
    if (_isSaving) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);
    try {
      await ref.read(timerEngineProvider.notifier).finishEarly();
      _refreshSadarSummaries();
    } catch (_) {
      // The engine keeps the session and exposes a retry action.
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _retryCompletion() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(timerEngineProvider.notifier).retryCompletion();
      _refreshSadarSummaries();
    } catch (_) {
      // Keep the pending state visible until the transaction succeeds.
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _refreshSadarSummaries() {
    ref.invalidate(habitsStreamProvider);
    ref.invalidate(dailyFulfillmentProvider);
    ref.invalidate(whatIRepeatProvider);
    ref.invalidate(awarenessStatsProvider);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildMessageCard({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback? onAction,
    bool showBackButton = true,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.stroke),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppPalette.accent, size: 34),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppPalette.textDim,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
          if (showBackButton) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: widget.onClose,
              child: const Text('Kembali ke Hari Ini'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TimerState>(timerEngineProvider, (previous, next) {
      if (next.isCompleted &&
          !next.isSavePending &&
          (previous?.isCompleted != true || previous?.isSavePending == true)) {
        _refreshSadarSummaries();
      }
    });
    final timer = ref.watch(timerEngineProvider);
    final color = Color(widget.habit.colorValue);

    return Scaffold(
      backgroundColor: AppPalette.bg,
      body: SafeArea(
        child: Stack(
          children: [
            // Exit Top Left
            Positioned(
              top: 16,
              left: 20,
              child: IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppPalette.textDim,
                  size: 24,
                ),
                tooltip: 'Keluar',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  widget.onClose();
                },
              ),
            ),

            // Desktop Floating Pip Top Right
            if (!kIsWeb &&
                (Platform.isWindows || Platform.isLinux || Platform.isMacOS) &&
                !timer.isCompleted)
              Positioned(
                top: 16,
                right: 20,
                child: IconButton(
                  icon: const Icon(
                    Icons.picture_in_picture_alt_rounded,
                    color: AppPalette.textDim,
                    size: 22,
                  ),
                  tooltip: 'Floating Timer',
                  onPressed: () async {
                    HapticFeedback.selectionClick();
                    final messenger = ScaffoldMessenger.of(context);
                    final engine = ref.read(timerEngineProvider.notifier);
                    final started = await engine.start(widget.habit);
                    if (!started) {
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Sesi fokus lain masih berjalan.'),
                          ),
                        );
                      }
                      return;
                    }
                    await engine.makeFloatingWindow();
                    widget.onClose();
                  },
                ),
              ),

            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _isLoadingSession
                    ? const CircularProgressIndicator()
                    : _hasSessionConflict
                    ? _buildMessageCard(
                        icon: Icons.timer_off_outlined,
                        title: 'Sesi lain masih berjalan',
                        message:
                            'Selesaikan atau jeda sesi yang aktif sebelum memulai habit ini.',
                        actionLabel: 'Kembali ke Hari Ini',
                        onAction: widget.onClose,
                        showBackButton: false,
                      )
                    : _couldNotStart
                    ? _buildMessageCard(
                        icon: Icons.cloud_off_outlined,
                        title: 'Timer belum dimulai',
                        message:
                            'Penyimpanan belum siap. Coba lagi setelah koneksi penyimpanan pulih.',
                        actionLabel: 'Coba lagi',
                        onAction: _attachToSession,
                      )
                    : timer.isSavePending
                    ? _buildMessageCard(
                        icon: Icons.sync_problem_rounded,
                        title: 'Catatan belum tersimpan',
                        message:
                            'Sesi tetap tersimpan. Coba lagi untuk memasukkan hasilnya ke riwayat.',
                        actionLabel: _isSaving
                            ? 'Menyimpan…'
                            : 'Coba simpan lagi',
                        onAction: _isSaving ? null : _retryCompletion,
                      )
                    : timer.isCompleted
                    ? _buildCompletionView(color, timer)
                    : _buildActiveTimer(color, timer),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTimer(Color color, TimerState timer) {
    final isPaused = timer.isPaused;
    final progress = timer.progress;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (timer.recoveryUncertain) ...[
          Text(
            timerRecoveryNotice,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppPalette.sand, height: 1.4),
          ),
          const SizedBox(height: 16),
        ],
        // Intention Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.habit.iconKey.isNotEmpty ? widget.habit.iconKey : '🎯',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 10),
              Text(
                widget.habit.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        Text(
          'Satu hal pada satu waktu. Lanjut sesuai energimu.',
          style: TextStyle(
            fontSize: 13,
            color: AppPalette.textDim,
            fontWeight: FontWeight.normal,
            letterSpacing: 0.4,
          ),
        ),

        const SizedBox(height: 36),

        // Breathing Circle Dial
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (context, child) {
            final scale = 1.0 + (_pulseCtrl.value * 0.02);
            return Transform.scale(
              scale: scale,
              child: SizedBox(
                width: 260,
                height: 260,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background track
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation(
                          AppPalette.stroke.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    // Progress arc
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 6,
                        strokeCap: StrokeCap.round,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                    // Digits
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(timer.remainingSeconds),
                          style: TextStyle(
                            fontSize: 54,
                            fontWeight: FontWeight.w300,
                            letterSpacing: -1.0,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isPaused ? 'JEDA' : 'SADAR',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3.0,
                            color: isPaused ? AppPalette.textDim : color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 44),

        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                side: const BorderSide(color: AppPalette.stroke),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: Icon(
                isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                size: 20,
                color: AppPalette.text,
              ),
              label: Text(
                isPaused ? 'Lanjutkan' : 'Jeda',
                style: const TextStyle(color: AppPalette.text),
              ),
              onPressed: _togglePause,
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: color.withValues(alpha: 0.2),
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: color.withValues(alpha: 0.5)),
                ),
              ),
              icon: const Icon(Icons.check_rounded, size: 20),
              label: Text(
                _isSaving ? 'Menyimpan…' : 'Selesai',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: _finish,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletionView(Color color, TimerState timer) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.stroke),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, color: color, size: 30),
          ),
          const SizedBox(height: 20),
          Text(
            widget.habit.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kamu fokus selama ${_formatTime(timer.actualDurationSeconds)} dari target ${_formatTime(timer.targetSeconds)}.\nCatatan ini sudah tersimpan.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppPalette.textDim,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF22C55E).withValues(alpha: 0.4),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: Color(0xFF22C55E),
                ),
                SizedBox(width: 8),
                Text(
                  'Tersimpan di riwayat',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF22C55E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppPalette.accent,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: widget.onClose,
            child: const Text(
              'Kembali ke Hari Ini',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
