import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../widgets/activity_icon.dart';
import '../../../core/time_math.dart';
import '../../../models/activity.dart';
import '../../../models/timer_session.dart';
import '../../../services/sadar_timer_engine.dart';

class FocusSessionView extends ConsumerStatefulWidget {
  const FocusSessionView({
    super.key,
    required this.activity,
    required this.onClose,
  });

  final Activity activity;
  final VoidCallback onClose;

  @override
  ConsumerState<FocusSessionView> createState() => _FocusSessionViewState();
}

class _FocusSessionViewState extends ConsumerState<FocusSessionView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  bool _isStarting = true;
  bool _isBusy = false;
  bool _hasSessionConflict = false;
  String? _actionError;
  String? _selectedReflection;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _ensureSharedSession();
  }

  Future<void> _ensureSharedSession() async {
    final engine = ref.read(timerEngineProvider.notifier);
    await engine.waitUntilRestored();
    if (!mounted) return;

    final current = engine.currentState;
    if (current.isActive ||
        current.isCompleted ||
        (current.isSavePending && current.activityId != null)) {
      setState(() {
        _hasSessionConflict = current.activityId != widget.activity.id;
        _isStarting = false;
      });
      return;
    }

    final durationSeconds =
        (widget.activity.endMinute - widget.activity.startMinute).clamp(
          1,
          720,
        ) *
        60;
    final now = DateTime.now();
    final minuteNow = minuteOfHalf(now);
    final elapsedSeconds =
        dateOnly(widget.activity.date) == dateOnly(now) &&
            widget.activity.ampmHalf == halfOfNow(now) &&
            minuteNow >= widget.activity.startMinute &&
            minuteNow < widget.activity.endMinute
        ? (minuteNow - widget.activity.startMinute) * 60 + now.second
        : 0;
    try {
      final started = await engine.startNonHabit(
        title: widget.activity.title,
        targetSeconds: (durationSeconds - elapsedSeconds).clamp(
          1,
          durationSeconds,
        ),
        sourceKind: TimerSessionSourceKind.activity,
        activityId: widget.activity.id,
        sourceIdentity: 'scheduled_activity',
        sourceColorValue: widget.activity.colorValue,
      );
      if (!mounted) return;
      final state = engine.currentState;
      setState(() {
        _hasSessionConflict =
            !started && state.activityId != widget.activity.id;
        _isStarting = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _actionError = 'Timer belum tersimpan: $error';
        _isStarting = false;
      });
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _togglePause(TimerState timer) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final engine = ref.read(timerEngineProvider.notifier);
      if (timer.isPaused) {
        await engine.resume();
      } else {
        await engine.pause();
      }
      if (mounted) setState(() => _actionError = null);
    } catch (error) {
      if (mounted) {
        setState(() => _actionError = 'Perubahan belum tersimpan: $error');
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _finishEarly() async {
    if (_isBusy) return;
    HapticFeedback.mediumImpact();
    setState(() => _isBusy = true);
    try {
      await ref.read(timerEngineProvider.notifier).finishEarly();
      if (mounted) setState(() => _actionError = null);
    } catch (error) {
      if (mounted) {
        setState(() => _actionError = 'Sesi belum tersimpan: $error');
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _retryCompletion() async {
    setState(() => _isBusy = true);
    try {
      await ref.read(timerEngineProvider.notifier).retryCompletion();
      if (mounted) setState(() => _actionError = null);
    } catch (error) {
      if (mounted) setState(() => _actionError = 'Simpan ulang gagal: $error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  String _formatTimer(int totalSecs) {
    final m = totalSecs ~/ 60;
    final s = totalSecs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.activity.colorValue);
    final timer = ref.watch(timerEngineProvider);

    return Scaffold(
      backgroundColor: AppPalette.bg,
      body: SafeArea(
        child: Stack(
          children: [
            // Top minimal exit button
            Positioned(
              top: 16,
              left: 20,
              child: IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppPalette.textDim,
                  size: 24,
                ),
                tooltip: 'Tutup Fokus',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  widget.onClose();
                },
              ),
            ),

            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _isStarting
                    ? const CircularProgressIndicator()
                    : _hasSessionConflict
                    ? _buildSessionConflict()
                    : timer.restoreError != null
                    ? _buildMessageCard(
                        timer.restoreError!,
                        'Tutup',
                        widget.onClose,
                      )
                    : _actionError != null &&
                          !timer.isActive &&
                          !timer.isSavePending &&
                          !timer.isCompleted
                    ? _buildMessageCard(_actionError!, 'Tutup', widget.onClose)
                    : timer.isSavePending
                    ? _buildPendingCard()
                    : timer.isCompleted
                    ? _buildReflectionCard(color)
                    : !timer.isActive
                    ? _buildMessageCard(
                        'Sesi ini sudah tidak aktif.',
                        'Tutup',
                        widget.onClose,
                      )
                    : _buildActiveTimer(color, timer),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTimer(Color color, TimerState timer) {
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ActivityIcon(
                iconKey: widget.activity.iconKey,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                widget.activity.title,
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
        const SizedBox(height: 36),

        // Hero Breathing Timer Circle
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (context, child) {
            final scale = 1.0 + (_pulseCtrl.value * 0.025);
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
                        strokeWidth: 5,
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
                    // Big Time Digits
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTimer(timer.remainingSeconds),
                          style: const TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w300,
                            letterSpacing: -1.0,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timer.isPaused ? 'JEDA' : 'FOKUS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3.0,
                            color: timer.isPaused ? AppPalette.textDim : color,
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

        const SizedBox(height: 48),

        // Minimal Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pause / Resume
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
                timer.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                size: 20,
                color: AppPalette.text,
              ),
              label: Text(
                timer.isPaused ? 'Lanjutkan' : 'Jeda',
                style: const TextStyle(color: AppPalette.text),
              ),
              onPressed: _isBusy
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      _togglePause(timer);
                    },
            ),
            const SizedBox(width: 16),
            // Finish Early
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
              label: const Text(
                'Selesai',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: _isBusy ? null : _finishEarly,
            ),
          ],
        ),
        if (_actionError != null) ...[
          const SizedBox(height: 12),
          Text(
            _actionError!,
            style: const TextStyle(color: AppPalette.textDim),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildSessionConflict() => _buildMessageCard(
    'Sesi lain sedang berjalan. Selesaikan atau jeda sesi itu sebelum memulai kegiatan ini.',
    'Tutup',
    widget.onClose,
  );

  Widget _buildMessageCard(
    String message,
    String action,
    VoidCallback onPressed,
  ) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: AppPalette.card,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppPalette.stroke),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppPalette.textDim),
        ),
        const SizedBox(height: 16),
        TextButton(onPressed: onPressed, child: Text(action)),
      ],
    ),
  );

  Widget _buildPendingCard() => _buildMessageCard(
    _actionError ?? 'Sesi selesai, tetapi penyimpanannya masih menunggu.',
    _isBusy ? 'Menyimpan…' : 'Coba simpan lagi',
    _isBusy ? () {} : _retryCompletion,
  );

  Widget _buildReflectionCard(Color color) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.stroke),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.spa_rounded, color: color, size: 26),
          ),
          const SizedBox(height: 18),
          const Text(
            'Sesi Selesai',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.activity.title} telah selesai. Bagaimana sesinya terasa?',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppPalette.textDim,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // 3 Quiet Reflection Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _reflectionOption(Icons.spa_outlined, 'Tenang', 'smooth'),
              _reflectionOption(Icons.center_focus_strong, 'Fokus', 'deep'),
              _reflectionOption(
                Icons.more_horiz_rounded,
                'Teralih',
                'distracted',
              ),
            ],
          ),

          const SizedBox(height: 28),
          TextButton(
            onPressed: () {
              widget.onClose();
            },
            child: const Text(
              'Tutup',
              style: TextStyle(color: AppPalette.textDim),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reflectionOption(IconData icon, String label, String value) {
    final selected = _selectedReflection == value;
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedReflection = value);
        Future.delayed(const Duration(milliseconds: 300), widget.onClose);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppPalette.accent.withValues(alpha: 0.2)
              : AppPalette.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppPalette.accent : AppPalette.stroke,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppPalette.accent : AppPalette.text,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? AppPalette.accent : AppPalette.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
