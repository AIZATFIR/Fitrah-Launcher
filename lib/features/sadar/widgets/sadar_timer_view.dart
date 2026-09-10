import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../models/habit.dart';
import '../../../models/habit_entry.dart';
import '../../../providers/sadar_providers.dart';
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

  Timer? _ticker;
  late int _totalSeconds;
  late int _remainingSeconds;
  DateTime? _pausedAt;
  late DateTime _targetEndTime;

  @override
  void initState() {
    super.initState();
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
            _isCompleted = true;
            _ticker?.cancel();
            HapticFeedback.heavyImpact();
            _autoRecordCompletion();
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

  void _finishEarly() {
    HapticFeedback.mediumImpact();
    setState(() {
      _remainingSeconds = 0;
      _isCompleted = true;
    });
    _ticker?.cancel();
    _autoRecordCompletion();
  }

  Future<void> _autoRecordCompletion() async {
    final now = DateTime.now();
    final dateStr = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final elapsedMinutes = ((_totalSeconds - _remainingSeconds) / 60).ceil().clamp(1, widget.habit.target);

    await ref.read(sadarRepoProvider).recordEntryStatus(
      habitId: widget.habit.id,
      dateString: dateStr,
      status: HabitStatus.yes,
      valueCompleted: elapsedMinutes,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulseCtrl.dispose();
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
    final progress = _totalSeconds > 0 ? (1.0 - (_remainingSeconds / _totalSeconds)).clamp(0.0, 1.0) : 0.0;

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
        const Text(
          'Stay with it. Fulfill your day.',
          style: TextStyle(fontSize: 13, color: AppPalette.textDim, letterSpacing: 0.4),
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
                        valueColor: AlwaysStoppedAnimation(AppPalette.stroke.withValues(alpha: 0.3)),
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
                          _formatTime(_remainingSeconds),
                          style: const TextStyle(
                            fontSize: 54,
                            fontWeight: FontWeight.w300,
                            letterSpacing: -1.0,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isPaused ? 'JEDA' : 'SADAR',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3.5,
                            color: _isPaused ? AppPalette.textDim : color,
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
              label: const Text('Selesai', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _finishEarly,
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
              color: AppPalette.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppPalette.stroke),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.spa_outlined, size: 16, color: AppPalette.accent),
                SizedBox(width: 8),
                Text(
                  '+1 Tindakan Bermakna Terpenuhi',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppPalette.accent),
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
