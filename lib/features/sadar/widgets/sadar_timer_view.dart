import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../models/habit.dart';
import '../../../models/habit_entry.dart';
import '../../../providers/providers.dart';
import '../../../providers/sadar_providers.dart';
import '../../../services/chime_service.dart';
import '../../../services/sadar_timer_engine.dart';

class SadarTimerView extends ConsumerStatefulWidget {
  const SadarTimerView({
    super.key,
    required this.habit,
    required this.onClose,
  });

  final Habit habit;
  final VoidCallback onClose;

  @override
  ConsumerState<SadarTimerView> createState() => _SadarTimerViewState();
}

class _SadarTimerViewState extends ConsumerState<SadarTimerView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  bool _isPaused = false;
  bool _isCompleted = false;
  bool _isOverdue = false;
  bool _hasChimed = false;

  Timer? _ticker;
  late int _totalSeconds;
  late int _remainingSeconds;
  int _overdueSeconds = 0;
  DateTime? _pausedAt;
  late DateTime _targetEndTime;

  @override
  void initState() {
    super.initState();
    // Enable immersive fullscreen on mobile for total focus
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    final minutes = widget.habit.target > 0 ? widget.habit.target : 20;
    _totalSeconds = minutes * 60;
    _remainingSeconds = _totalSeconds;
    _targetEndTime = DateTime.now().add(Duration(seconds: _totalSeconds));

    _startTimer();
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
              try {
                ref.read(notificationServiceProvider).showNotification(
                  id: widget.habit.id,
                  title: 'Waktu Selesai! 🎉',
                  body: 'Target "${widget.habit.name}" tercapai. Anda dalam mode fokus ekstra!',
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

  void _togglePause() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_isPaused) {
        // Resuming
        if (_pausedAt != null) {
          final pauseDuration = DateTime.now().difference(_pausedAt!);
          _targetEndTime = _targetEndTime.add(pauseDuration);
        }
        _isPaused = false;
      } else {
        // Pausing
        _pausedAt = DateTime.now();
        _isPaused = true;
      }
    });
  }

  void _finish() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isCompleted = true;
    });
    _ticker?.cancel();
    _autoRecordCompletion();
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
      source: 'timer',
    );

    ref.invalidate(habitsStreamProvider);
    ref.invalidate(dailyFulfillmentProvider);
    ref.invalidate(whatIRepeatProvider);
    ref.invalidate(awarenessStatsProvider);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulseCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
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
                icon: const Icon(Icons.close_rounded, color: AppPalette.textDim, size: 24),
                tooltip: 'Keluar',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  widget.onClose();
                },
              ),
            ),

            // Desktop Floating Pip Top Right
            if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS) && !_isCompleted)
              Positioned(
                top: 16,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.picture_in_picture_alt_rounded, color: AppPalette.textDim, size: 22),
                  tooltip: 'Floating Timer',
                  onPressed: () async {
                    HapticFeedback.selectionClick();
                    final engine = ref.read(timerEngineProvider.notifier);
                    engine.start(widget.habit);
                    await engine.makeFloatingWindow();
                    widget.onClose();
                  },
                ),
              ),

            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _isCompleted ? _buildCompletionView(color) : _buildActiveTimer(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTimer(Color color) {
    final progress = _isOverdue
        ? 1.0
        : (_totalSeconds > 0 ? (1.0 - (_remainingSeconds / _totalSeconds)).clamp(0.0, 1.0) : 0.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
          _isOverdue
              ? 'Target selesai! Terus melangkah selama fokus.'
              : 'Stay with it. Fulfill your day.',
          style: TextStyle(
            fontSize: 13,
            color: _isOverdue ? AppPalette.accent : AppPalette.textDim,
            fontWeight: _isOverdue ? FontWeight.w600 : FontWeight.normal,
            letterSpacing: 0.4,
          ),
        ),

        const SizedBox(height: 36),

        // Breathing Circle Dial
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (context, child) {
            final scale = 1.0 + (_pulseCtrl.value * (_isOverdue ? 0.035 : 0.02));
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
                          _isOverdue
                              ? AppPalette.accent.withValues(alpha: 0.2)
                              : AppPalette.stroke.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    // Progress arc
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 6,
                        strokeCap: StrokeCap.round,
                        valueColor: AlwaysStoppedAnimation(_isOverdue ? AppPalette.accent : color),
                      ),
                    ),
                    // Digits
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isOverdue ? '+${_formatTime(_overdueSeconds)}' : _formatTime(_remainingSeconds),
                          style: TextStyle(
                            fontSize: _isOverdue ? 48 : 54,
                            fontWeight: FontWeight.w300,
                            letterSpacing: -1.0,
                            color: _isOverdue ? AppPalette.accent : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isPaused
                              ? 'JEDA'
                              : (_isOverdue ? 'LEBIH (OVERDUE)' : 'SADAR'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3.0,
                            color: _isPaused
                                ? AppPalette.textDim
                                : (_isOverdue ? AppPalette.accent : color),
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
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                side: const BorderSide(color: AppPalette.stroke),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: Icon(_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 20, color: AppPalette.text),
              label: Text(_isPaused ? 'Lanjutkan' : 'Jeda', style: const TextStyle(color: AppPalette.text)),
              onPressed: _togglePause,
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: color.withValues(alpha: 0.2),
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: color.withValues(alpha: 0.5)),
                ),
              ),
              icon: const Icon(Icons.check_rounded, size: 20),
              label: Text(_isOverdue ? 'Selesai (+${_overdueSeconds ~/ 60}m)' : 'Selesai', style: const TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _finish,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletionView(Color color) {
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
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.habit.target} menit terpenuhi.\nKamu telah menepati janji pada dirimu sendiri.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppPalette.textDim, height: 1.5),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF22C55E)),
                SizedBox(width: 8),
                Text(
                  'Otomatis Ditandai Selesai (Centang Hijau)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF22C55E)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: widget.onClose,
            child: const Text('Kembali ke Hari Ini', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
