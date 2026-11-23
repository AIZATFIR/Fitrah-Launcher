import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';

import '../../core/theme.dart';
import '../../widgets/activity_icon.dart';
import '../../core/time_math.dart';
import '../../models/activity.dart';
import '../../models/preset.dart';
import '../../providers/providers.dart';
import '../activity_detail/activity_detail_sheet.dart';
import '../presets/presets_tab.dart';
import '../../widgets/command_palette.dart';
import '../../widgets/hotkeys_modal.dart';
import 'analog_clock_face.dart';
import 'widgets/now_next_card.dart';

/// Returns a Preset if user picked one, null if user chose "Custom".
/// Returns false (via pop with no result) if user dismissed.
Future<Object?> _showPresetPicker(BuildContext context) async {
  return showModalBottomSheet<Object>(
    context: context,
    backgroundColor: AppPalette.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const _PresetPickerSheet(),
  );
}

class _PresetPickerSheet extends ConsumerStatefulWidget {
  const _PresetPickerSheet();

  @override
  ConsumerState<_PresetPickerSheet> createState() => _PresetPickerSheetState();
}

class _PresetPickerSheetState extends ConsumerState<_PresetPickerSheet> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKey(KeyEvent event, List<Preset> presets) {
    if (event is! KeyDownEvent) return;
    final label = event.logicalKey.keyLabel;
    final n = int.tryParse(label);
    if (n != null && n >= 1 && n <= presets.length) {
      Navigator.pop(context, presets[n - 1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final presets = ref.watch(presetsProvider).valueOrNull ?? [];
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (e) => _handleKey(e, presets),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tambah kegiatan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pilih preset atau buat sendiri',
              style: TextStyle(fontSize: 13, color: AppPalette.textDim),
            ),
            const SizedBox(height: 14),
            if (presets.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Belum ada preset.',
                  style: TextStyle(color: AppPalette.textDim),
                ),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: presets.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final p = entry.value;
                  final color = Color(p.colorValue);
                  final hasIcon = p.iconKey != null && p.iconKey!.isNotEmpty;
                  return GestureDetector(
                    onTap: () => Navigator.pop(context, p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: color.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Number badge
                          if (idx < 9)
                            Container(
                              width: 16,
                              height: 16,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${idx + 1}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          if (hasIcon) ...[
                            ActivityIcon(iconKey: p.iconKey, color: color),
                            const SizedBox(width: 8),
                          ] else ...[
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            p.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppPalette.accent.withValues(alpha: 0.15),
                    foregroundColor: AppPalette.accent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 24),
                  label: const Text(
                    'Buat kegiatan sendiri',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () => Navigator.pop(context, 'custom'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FocusClockTab extends ConsumerStatefulWidget {
  const FocusClockTab({super.key});
  @override
  ConsumerState<FocusClockTab> createState() => _FocusClockTabState();
}

class _FocusClockTabState extends ConsumerState<FocusClockTab>
    with TickerProviderStateMixin {
  Activity? _draggingActivity;
  int? _lastPanMinute;
  bool _isPrecisionMode = false;
  bool _hasDragged = false;
  final bool _isExiting = false;
  int? _dragClickMinute;
  int _dragValue = 0;

  late final AnimationController _revealCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _startupCtrl;
  late final AnimationController _aimLockCtrl;
  late final AnimationController _exitCtrl;

  late final ValueNotifier<int?> _hoverMinuteNotifier;
  late final ValueNotifier<int?> _dragStartNotifier;
  late final ValueNotifier<int?> _dragEndNotifier;
  late final ValueNotifier<bool> _dragConflictNotifier;

  int _snap(int m) => _isPrecisionMode ? m : snap5(m);

  @override
  void initState() {
    super.initState();
    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _startupCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _aimLockCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _hoverMinuteNotifier = ValueNotifier<int?>(null);
    _dragStartNotifier = ValueNotifier<int?>(null);
    _dragEndNotifier = ValueNotifier<int?>(null);
    _dragConflictNotifier = ValueNotifier<bool>(false);

    _startupCtrl.forward();
  }

  @override
  void dispose() {
    _revealCtrl.dispose();
    _pulseCtrl.dispose();
    _startupCtrl.dispose();
    _aimLockCtrl.dispose();
    _exitCtrl.dispose();
    _hoverMinuteNotifier.dispose();
    _dragStartNotifier.dispose();
    _dragEndNotifier.dispose();
    _dragConflictNotifier.dispose();
    super.dispose();
  }

  double get _grow => clockGrowFactor(1.0, ref.read(planningModeProvider));

  bool _hasConflict(
    int start,
    int end,
    List<Activity> activities, {
    int? excludeId,
    required bool is24h,
  }) {
    for (final a in activities) {
      if (excludeId != null && a.id == excludeId) continue;
      final aStart = toUiMinute(a.startMinute, a.ampmHalf, is24h: is24h);
      final aEnd = toUiMinute(a.endMinute, a.ampmHalf, is24h: is24h);

      if (is24h) {
        if (rangesOverlap(start, end, aStart, aEnd)) return true;
      } else {
        int cycleStart = (start ~/ 720) * 720;
        if (start < 0 && start % 720 != 0) {
          cycleStart = ((start ~/ 720) - 1) * 720;
        }
        for (int c = cycleStart; c <= end; c += 720) {
          if ((c ~/ 720).abs() % 2 == 0) {
            final s = math.max(start - c, 0);
            final e = math.min(end - c, 720);
            if (s < e) {
              if (rangesOverlap(s, e, aStart, aEnd)) return true;
            }
          }
        }
      }
    }
    return false;
  }

  ({int start, int end})? _getFreeInterval(
    int hoverMin,
    int slotStart,
    int slotEnd,
    List<Activity> activities, {
    required bool is24h,
  }) {
    List<({int start, int end})> freeIntervals = [
      (start: slotStart, end: slotEnd),
    ];
    for (final a in activities) {
      final aStart = toUiMinute(a.startMinute, a.ampmHalf, is24h: is24h);
      final aEnd = toUiMinute(a.endMinute, a.ampmHalf, is24h: is24h);

      final nextFree = <({int start, int end})>[];
      for (final f in freeIntervals) {
        if (aStart >= f.end || aEnd <= f.start) {
          nextFree.add(f);
        } else {
          if (aStart > f.start) {
            nextFree.add((start: f.start, end: aStart));
          }
          if (aEnd < f.end) {
            nextFree.add((start: aEnd, end: f.end));
          }
        }
      }
      freeIntervals = nextFree;
    }

    for (final f in freeIntervals) {
      if (hoverMin >= f.start && hoverMin < f.end) {
        return f;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final is24hDial = ref.watch(
      settingsProvider.select((s) => s.valueOrNull?.is24hDial ?? false),
    );
    final is24hTime = ref.watch(
      settingsProvider.select((s) => s.valueOrNull?.is24hTime ?? false),
    );
    final showCurrentTime = ref.watch(
      settingsProvider.select((s) => s.valueOrNull?.showCurrentTime ?? true),
    );
    final currentTimeFormat = ref.watch(
      settingsProvider.select(
        (s) => s.valueOrNull?.currentTimeFormat ?? 'short',
      ),
    );
    final floatTimeText = ref.watch(
      settingsProvider.select((s) => s.valueOrNull?.floatTimeText ?? false),
    );
    final glowStyle = ref.watch(
      settingsProvider.select((s) => s.valueOrNull?.glowStyle ?? 'default'),
    );
    final is24h = is24hDial;
    final clockHandsMode = ref.watch(
      settingsProvider.select((s) => s.valueOrNull?.clockHandsMode ?? 1),
    );
    final clockFaceTheme = ref.watch(
      settingsProvider.select((s) => s.valueOrNull?.clockFaceTheme ?? 1),
    );
    final activitiesAsync = ref.watch(
      is24hDial ? activitiesByDateProvider : activitiesByHalfProvider,
    );
    final tasks = ref.watch(
      is24hDial ? tasksByDateProvider : tasksByHalfProvider,
    );
    final half = ref.watch(ampmHalfProvider);
    final nowAsync = ref.watch(currentTimeProvider);
    final now = nowAsync.valueOrNull ?? DateTime.now();
    final date = ref.watch(currentDateProvider);
    final isToday = date == dateOnly(DateTime.now());
    final activities = activitiesAsync.valueOrNull ?? const <Activity>[];
    final schedulingTask = ref.watch(schedulingTaskProvider);
    final isInstant = ref.watch(isInstantModeProvider);

    ref.listen<bool>(precisionModeProvider, (prev, next) {
      if (next != _isPrecisionMode) {
        setState(() {
          _isPrecisionMode = next;
        });
        if (!_isPrecisionMode) {
          _hoverMinuteNotifier.value = null;
        }
      }
    });

    ref.listen<bool>(isInstantModeProvider, (prev, next) {
      if (next == false) {
        _dragStartNotifier.value = null;
        _dragEndNotifier.value = null;
      }
    });

    final m = is24h
        ? (now.hour * 60 + now.minute)
        : ((now.hour % 12) * 60 + now.minute);

    final hasCurrent = activities.any((a) {
      final start = toUiMinute(a.startMinute, a.ampmHalf, is24h: is24h);
      final end = toUiMinute(a.endMinute, a.ampmHalf, is24h: is24h);
      return m >= start && m < end;
    });
    if (hasCurrent && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat();
    } else if (!hasCurrent && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.value = 0;
    }

    return AnimatedBuilder(
      animation: _exitCtrl,
      builder: (context, child) {
        if (!_isExiting) return child!;
        final val = _exitCtrl.value;
        final double heightScale = val < 0.5 ? (1.0 - (val * 2.0)) : 0.005;
        final double widthScale = val < 0.5 ? 1.0 : (1.0 - ((val - 0.5) * 2.0));
        return Center(
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(widthScale, heightScale, 1.0),
            child: Container(color: Colors.white, child: child!),
          ),
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          // This page is capped at 500dp inside the launcher. Use its actual
          // available width, not the device's wider MediaQuery, for the header.
          final isCompactHeader = constraints.maxWidth < 600;
          return Stack(
            children: [
              Positioned.fill(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: LayoutBuilder(
                      builder: (context, c) => Stack(
                        children: [
                          Positioned.fill(
                            child: DragTarget<Preset>(
                              onAcceptWithDetails: (details) =>
                                  _onPresetDropped(details.data),
                              builder: (ctx, candidate, rejected) {
                                return MouseRegion(
                                  onHover: (e) {
                                    final centered = _toCenter(
                                      e.localPosition,
                                      c.biggest,
                                    );
                                    final rDist = centered.distance;
                                    final r =
                                        c.biggest.shortestSide / 2 * _grow;
                                    final outer = r * 0.95 * 1.15;

                                    if (rDist <= outer) {
                                      _revealCtrl.forward();
                                      final newMinute = offsetToMinute(
                                        centered,
                                        is24h: is24h,
                                      );
                                      if (_hoverMinuteNotifier.value !=
                                          newMinute) {
                                        _hoverMinuteNotifier.value = newMinute;
                                      }

                                      if (isInstant) {
                                        final interval = ref.read(
                                          instantIntervalProvider,
                                        );
                                        final slotStart =
                                            (newMinute ~/ interval) * interval;
                                        final slotEnd = slotStart + interval;

                                        final freeSeg = _getFreeInterval(
                                          newMinute,
                                          slotStart,
                                          slotEnd,
                                          activities,
                                          is24h: is24h,
                                        );
                                        if (freeSeg != null) {
                                          _dragStartNotifier.value =
                                              freeSeg.start;
                                          _dragEndNotifier.value = freeSeg.end;
                                        } else {
                                          _dragStartNotifier.value = null;
                                          _dragEndNotifier.value = null;
                                        }
                                      }
                                    } else {
                                      _revealCtrl.reverse();
                                      if (_hoverMinuteNotifier.value != null) {
                                        _hoverMinuteNotifier.value = null;
                                      }
                                      if (isInstant) {
                                        _dragStartNotifier.value = null;
                                        _dragEndNotifier.value = null;
                                      }
                                    }
                                  },
                                  onExit: (_) {
                                    _revealCtrl.reverse();
                                    if (_hoverMinuteNotifier.value != null) {
                                      _hoverMinuteNotifier.value = null;
                                    }
                                    if (isInstant) {
                                      _dragStartNotifier.value = null;
                                      _dragEndNotifier.value = null;
                                    }
                                  },
                                  child: Listener(
                                    onPointerDown: (_) {
                                      ref
                                              .read(
                                                isClockDraggingProvider
                                                    .notifier,
                                              )
                                              .state =
                                          true;
                                    },
                                    onPointerUp: (_) {
                                      ref
                                              .read(
                                                isClockDraggingProvider
                                                    .notifier,
                                              )
                                              .state =
                                          false;
                                    },
                                    onPointerCancel: (_) {
                                      ref
                                              .read(
                                                isClockDraggingProvider
                                                    .notifier,
                                              )
                                              .state =
                                          false;
                                    },
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onSecondaryTap: () {
                                        ref
                                                .read(
                                                  precisionModeProvider
                                                      .notifier,
                                                )
                                                .state =
                                            !_isPrecisionMode;
                                      },
                                      onTapUp: (e) {
                                        if (isInstant) {
                                          final centered = _toCenter(
                                            e.localPosition,
                                            c.biggest,
                                          );
                                          final rawMin = _snap(
                                            offsetToMinute(
                                              centered,
                                              is24h: is24h,
                                            ),
                                          );
                                          final interval = ref.read(
                                            instantIntervalProvider,
                                          );
                                          _dragStartNotifier.value = rawMin;
                                          _dragEndNotifier.value =
                                              rawMin + interval;

                                          final Color themeAccentColor;
                                          if (clockFaceTheme == 2) {
                                            themeAccentColor = Colors.white;
                                          } else if (clockFaceTheme == 3) {
                                            themeAccentColor = const Color(
                                              0xFF3399FF,
                                            );
                                          } else if (clockFaceTheme == 4) {
                                            themeAccentColor = const Color(
                                              0xFFBB86FC,
                                            );
                                          } else if (clockFaceTheme == 5 ||
                                              clockFaceTheme == 6) {
                                            themeAccentColor = const Color(
                                              0xFFFFD54F,
                                            );
                                          } else {
                                            themeAccentColor =
                                                AppPalette.accent;
                                          }
                                          _onInstantModeTap(
                                            date,
                                            themeAccentColor,
                                          );
                                        } else {
                                          final lead =
                                              ref
                                                  .read(settingsProvider)
                                                  .valueOrNull
                                                  ?.notifLeadMinutes ??
                                              1;
                                          _onTapUp(
                                            e.localPosition,
                                            c.biggest,
                                            activities,
                                            lead,
                                          );
                                        }
                                      },
                                      onDoubleTapDown: (e) {
                                        final instantMode = ref.read(
                                          isInstantModeProvider,
                                        );
                                        ref
                                                .read(
                                                  isInstantModeProvider
                                                      .notifier,
                                                )
                                                .state =
                                            !instantMode;
                                        HapticFeedback.mediumImpact();
                                      },
                                      onLongPressStart: (e) {
                                        if (!isInstant) {
                                          _onLongPressStart(
                                            e.localPosition,
                                            c.biggest,
                                            activities,
                                          );
                                        }
                                      },
                                      onLongPressMoveUpdate: (e) {
                                        if (!isInstant) {
                                          _onLongPressMove(
                                            e.localPosition,
                                            c.biggest,
                                            activities,
                                          );
                                        }
                                      },
                                      onLongPressEnd: (_) {
                                        if (!isInstant) {
                                          final lead =
                                              ref
                                                  .read(settingsProvider)
                                                  .valueOrNull
                                                  ?.notifLeadMinutes ??
                                              1;
                                          _onLongPressEnd(lead);
                                        }
                                      },
                                      onPanStart: (e) {
                                        _onPanStart(e.localPosition, c.biggest);
                                      },
                                      onPanUpdate: (e) {
                                        _onPanUpdate(
                                          e.localPosition,
                                          c.biggest,
                                          activities,
                                        );
                                      },
                                      onPanEnd: (_) {
                                        if (ref.read(isInstantModeProvider)) {
                                          if (_hasDragged &&
                                              _dragStartNotifier.value !=
                                                  null &&
                                              _dragEndNotifier.value != null) {
                                            final themeAccentColor =
                                                AppPalette.accent;
                                            _onInstantModeTap(
                                              date,
                                              themeAccentColor,
                                            );
                                          }
                                        } else {
                                          _onPanEnd();
                                        }
                                      },
                                      child: RepaintBoundary(
                                        child: AnimatedBuilder(
                                          animation: Listenable.merge([
                                            _pulseCtrl,
                                            _revealCtrl,
                                            _hoverMinuteNotifier,
                                            _dragStartNotifier,
                                            _dragEndNotifier,
                                            _dragConflictNotifier,
                                          ]),
                                          builder: (context, child) =>
                                              AnalogClockFace(
                                                now: now,
                                                activities: activities,
                                                tasks: tasks,
                                                viewHalf: half,
                                                previewStartMinute:
                                                    _dragStartNotifier.value,
                                                previewEndMinute:
                                                    _dragEndNotifier.value,
                                                previewColor:
                                                    candidate.isNotEmpty
                                                    ? Color(
                                                        candidate
                                                            .first!
                                                            .colorValue,
                                                      )
                                                    : (isInstant
                                                          ? const Color(
                                                              0xFFFFEE99,
                                                            ).withValues(
                                                              alpha: 0.27,
                                                            )
                                                          : null),
                                                previewConflict:
                                                    _dragConflictNotifier.value,
                                                pulse: _pulseCtrl.value,
                                                clockHandsMode: clockHandsMode,
                                                is24hDial: is24hDial,
                                                is24hTime: is24hTime,
                                                floatTimeText: floatTimeText,
                                                showCurrentTime:
                                                    showCurrentTime,
                                                currentTimeFormat:
                                                    currentTimeFormat,
                                                glowStyle: glowStyle,
                                                isToday: isToday,
                                                hoverMinute:
                                                    _hoverMinuteNotifier.value,
                                                isPrecisionMode:
                                                    _isPrecisionMode,
                                                outerReveal:
                                                    1.0 +
                                                    (_revealCtrl.value * 0.04),
                                                clockFaceTheme: clockFaceTheme,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (schedulingTask != null)
                            Positioned(
                              top: 10,
                              left: 16,
                              right: 16,
                              child: Container(
                                constraints: const BoxConstraints(
                                  minHeight: 44,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppPalette.card,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppPalette.accent.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppPalette.accent.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      size: 20,
                                      color: AppPalette.accent,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Tap an activity to schedule "${schedulingTask.title}"',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppPalette.accent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        size: 18,
                                        color: AppPalette.textDim,
                                      ),
                                      onPressed: () =>
                                          ref
                                                  .read(
                                                    schedulingTaskProvider
                                                        .notifier,
                                                  )
                                                  .state =
                                              null,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Top Header Action Bar & Quick Timer Hub
              // Calm Minimal Header Overlay
              Positioned(
                top: 14,
                left: 18,
                right: 18,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 8,
                  children: [
                    // App Title & Contextual Menu (Routines & Reflection)
                    PopupMenuButton<String>(
                      tooltip: 'Menu Fokus',
                      color: AppPalette.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppPalette.stroke),
                      ),
                      onSelected: (val) {
                        HapticFeedback.mediumImpact();
                        if (val == 'routines') {
                          ref.read(tabIndexProvider.notifier).state = 0;
                        } else if (val == 'copy_day') {
                          _showCopyScheduleDialog(
                            context,
                            ref.read(currentDateProvider),
                          );
                        } else if (val == 'schedule_list') {
                          _showScheduleList(
                            context,
                            date,
                            activities,
                            isLoading: activitiesAsync.isLoading,
                            hasError: activitiesAsync.hasError,
                            is24h: is24hDial,
                          );
                        } else if (val == 'command') {
                          showDialog(
                            context: context,
                            builder: (_) => const CommandPaletteModal(),
                          );
                        } else if (val == 'hotkeys') {
                          showDialog(
                            context: context,
                            builder: (_) => const HotkeysModal(),
                          );
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'schedule_list',
                          child: Row(
                            children: [
                              Icon(
                                Icons.view_agenda_outlined,
                                size: 16,
                                color: AppPalette.accent,
                              ),
                              SizedBox(width: 10),
                              Text('Jadwal', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'routines',
                          child: Row(
                            children: [
                              Icon(
                                Icons.auto_stories_rounded,
                                size: 16,
                                color: AppPalette.accent,
                              ),
                              SizedBox(width: 10),
                              Text('Rutinitas', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'copy_day',
                          child: Row(
                            children: [
                              Icon(
                                Icons.copy_rounded,
                                size: 16,
                                color: AppPalette.accent,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Salin hari',
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),

                        const PopupMenuItem(
                          value: 'command',
                          child: Row(
                            children: [
                              Icon(
                                Icons.terminal_rounded,
                                size: 16,
                                color: AppPalette.textDim,
                              ),
                              SizedBox(width: 10),
                              Text('Perintah', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'hotkeys',
                          child: Row(
                            children: [
                              Icon(
                                Icons.help_outline_rounded,
                                size: 16,
                                color: AppPalette.textDim,
                              ),
                              SizedBox(width: 10),
                              Text('Pintasan', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        width: isCompactHeader ? 44 : null,
                        height: isCompactHeader ? 44 : null,
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompactHeader ? 0 : 10,
                          vertical: isCompactHeader ? 0 : 6,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppPalette.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppPalette.stroke),
                        ),
                        child: isCompactHeader
                            ? const Icon(
                                Icons.menu_book_outlined,
                                size: 20,
                                color: AppPalette.accent,
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'FOCUS',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2,
                                      color: AppPalette.text,
                                    ),
                                  ),
                                  Text(
                                    'CLOCK',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2,
                                      color: AppPalette.accent,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 14,
                                    color: AppPalette.textDim,
                                  ),
                                ],
                              ),
                      ),
                    ),

                    // Current Date & Time Display
                    Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Semantics(
                          button: true,
                          label:
                              'Pilih tanggal ${date.day} ${_monthName(date.month)} ${date.year}',
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              _showLargeCalendarBatchPicker(context, date);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppPalette.card,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppPalette.accent.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.calendar_month_rounded,
                                    size: 13,
                                    color: AppPalette.accent,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isCompactHeader
                                        ? '${date.day} ${_monthName(date.month)}'
                                        : '${date.day} ${_monthName(date.month)} ${date.year}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppPalette.text,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        _AmPmMini(
                          half: half,
                          onChanged: (h) {
                            HapticFeedback.selectionClick();
                            ref.read(ampmHalfProvider.notifier).state = h;
                          },
                        ),
                        Text(
                          formatTimeOfDay(now, is24h: is24h),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppPalette.accent,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bottom Contextual Card (Now, Next & Natural Intent Engine)
              Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: Center(
                  child: NowNextCard(
                    activities: activities,
                    now: now,
                    date: date,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Offset _toCenter(Offset local, Size size) => local - size.center(Offset.zero);

  bool get _is24h => ref.read(settingsProvider).valueOrNull?.is24hDial ?? false;

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Future<void> _showScheduleList(
    BuildContext context,
    DateTime date,
    List<Activity> activities, {
    required bool isLoading,
    required bool hasError,
    required bool is24h,
  }) async {
    final sorted = [...activities]
      ..sort((a, b) {
        final halfOrder = a.ampmHalf.index.compareTo(b.ampmHalf.index);
        return halfOrder != 0
            ? halfOrder
            : a.startMinute.compareTo(b.startMinute);
      });

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.72,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Container(
              decoration: BoxDecoration(
                color: AppPalette.card,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                border: Border.all(color: AppPalette.stroke),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Jadwal',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${date.day} ${_monthName(date.month)} ${date.year}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppPalette.textDim,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Tutup daftar jadwal',
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppPalette.stroke),
                  Expanded(
                    child: hasError
                        ? const Center(child: Text('Jadwal belum bisa dimuat.'))
                        : isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : sorted.isEmpty
                        ? const Center(
                            child: Text(
                              'Belum ada jadwal untuk tanggal ini.',
                              style: TextStyle(color: AppPalette.textDim),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: sorted.length,
                            separatorBuilder: (_, __) => const Divider(
                              height: 1,
                              indent: 20,
                              endIndent: 20,
                              color: AppPalette.stroke,
                            ),
                            itemBuilder: (context, index) {
                              final activity = sorted[index];
                              final start = formatMinuteOfHalf(
                                activity.startMinute,
                                activity.ampmHalf,
                                is24h: is24h,
                              );
                              final end = formatMinuteOfHalf(
                                activity.endMinute,
                                activity.ampmHalf,
                                is24h: is24h,
                              );
                              return Semantics(
                                key: ValueKey(
                                  'focus-clock-schedule-${activity.id}',
                                ),
                                button: true,
                                label: '$start sampai $end, ${activity.title}',
                                child: ListTile(
                                  minVerticalPadding: 12,
                                  leading: Container(
                                    width: 4,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Color(activity.colorValue),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  title: Text(activity.title),
                                  subtitle: Text('$start–$end'),
                                  onTap: () {
                                    Navigator.pop(sheetContext);
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          if (mounted) {
                                            unawaited(
                                              showActivityDetailSheet(
                                                context,
                                                activity: activity,
                                                mode: DetailMode.view,
                                              ),
                                            );
                                          }
                                        });
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int? _hitActivity(Offset local, Size size, List<Activity> activities) {
    final centered = _toCenter(local, size);
    final r = centered.distance;
    final outer = size.shortestSide / 2 * 0.85 * _grow;
    final inner = size.shortestSide / 2 * 0.55 * _grow;
    if (r < inner || r > outer) return null;
    final is24h = _is24h;
    final minute = offsetToMinute(centered, is24h: is24h);
    for (final a in activities) {
      final start = toUiMinute(a.startMinute, a.ampmHalf, is24h: is24h);
      final end = toUiMinute(a.endMinute, a.ampmHalf, is24h: is24h);
      if (minute >= start && minute < end) return a.id;
    }
    return null;
  }

  void _onInstantModeTap(DateTime date, Color accentColor) async {
    final start = _dragStartNotifier.value;
    final end = _dragEndNotifier.value;
    if (start == null || end == null) return;

    _dragStartNotifier.value = null;
    _dragEndNotifier.value = null;
    _hoverMinuteNotifier.value = null;

    final is24h = _is24h;
    final half = ref.read(ampmHalfProvider);
    final start24 = is24h ? start : (start + (half == AmPmHalf.pm ? 720 : 0));
    final end24 = is24h ? end : (end + (half == AmPmHalf.pm ? 720 : 0));

    final dbStart = toDbMinute(start24);
    final dbHalf = toDbHalf(start24);
    final dbEnd = toDbEndMinute(end24, dbHalf);
    final duration = end24 - start24;

    final activity = Activity()
      ..title = 'Fokus ${duration}m'
      ..startMinute = dbStart
      ..endMinute = dbEnd
      ..ampmHalf = dbHalf
      ..date = dateOnly(date)
      ..colorValue = accentColor.toARGB32()
      ..description = ''
      ..recurrence = 'none'
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    final lead = ref.read(settingsProvider).valueOrNull?.notifLeadMinutes ?? 1;
    await ref
        .read(activityRepoProvider)
        .upsert(activity, notifLeadMinutes: lead);

    HapticFeedback.mediumImpact();
  }

  void _onPanStart(Offset p, Size size) {
    if (_draggingActivity != null) return;
    final centered = _toCenter(p, size);
    final rDist = centered.distance;
    final outer = size.shortestSide / 2 * 0.95 * _grow;
    if (rDist > outer) return;

    ref.read(isClockDraggingProvider.notifier).state = true;
    _hasDragged = false;
    final is24h = _is24h;
    final clickMin = _snap(offsetToMinute(centered, is24h: is24h));
    _dragClickMinute = clickMin;
    _dragStartNotifier.value = clickMin;
    _dragEndNotifier.value = clickMin;
    _lastPanMinute = offsetToMinute(centered, is24h: is24h);
    _dragValue = 0;
    _dragConflictNotifier.value = false;
  }

  void _onPanUpdate(Offset p, Size size, List<Activity> activities) {
    if (_dragClickMinute == null) return;
    _hasDragged = true;
    final centered = _toCenter(p, size);
    final is24h = _is24h;
    final raw = offsetToMinute(centered, is24h: is24h);
    final isInstant = ref.read(isInstantModeProvider);
    final prevEnd = _dragEndNotifier.value;

    if (isInstant) {
      final interval = ref.read(instantIntervalProvider);
      final rawSnapped = _snap(raw);
      _dragStartNotifier.value = rawSnapped;
      _dragEndNotifier.value = rawSnapped + interval;
      _dragConflictNotifier.value = _hasConflict(
        rawSnapped,
        rawSnapped + interval,
        activities,
        is24h: is24h,
      );
      _hoverMinuteNotifier.value = rawSnapped;
      if (rawSnapped != prevEnd) HapticFeedback.selectionClick();
      return;
    }

    final clickMin = _dragClickMinute!;

    final last = _lastPanMinute ?? raw;
    final scale = is24h ? 1440 : 720;

    int delta = raw - last;
    if (delta > scale / 2) {
      delta -= scale;
    } else if (delta < -scale / 2) {
      delta += scale;
    }
    _dragValue += delta;
    _lastPanMinute = raw;

    final currentAbsolute = clickMin + _dragValue;

    int start;
    int end;
    if (currentAbsolute >= clickMin) {
      start = clickMin;
      end = _snap(currentAbsolute);
    } else {
      start = _snap(currentAbsolute);
      end = clickMin;
    }

    if (end - start < 5) {
      end = start + 5;
    }
    if (end - start > 1440) {
      end = start + 1440;
    }

    _dragStartNotifier.value = start;
    _dragEndNotifier.value = end;
    _dragConflictNotifier.value = _hasConflict(
      start,
      end,
      activities,
      is24h: is24h,
    );
    _hoverMinuteNotifier.value = raw;

    if (_isPrecisionMode && !_aimLockCtrl.isAnimating) {
      _aimLockCtrl.forward(from: 0.0);
    }

    if (end != prevEnd) HapticFeedback.selectionClick();
  }

  Future<void> _showLargeCalendarBatchPicker(
    BuildContext context,
    DateTime currentDate,
  ) async {
    final selectedDates = <DateTime>{dateOnly(currentDate)};
    bool isBatchMode = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isToday =
              dateOnly(selectedDates.first) == dateOnly(DateTime.now());

          return Dialog(
            backgroundColor: AppPalette.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: AppPalette.stroke),
            ),
            child: Container(
              width: 480,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        color: AppPalette.accent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isBatchMode
                            ? 'Batch Duplikasi Jadwal'
                            : 'Pilih Tanggal Jam',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // Mode Switch: Pindah Hari vs Batch Mode
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppPalette.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isBatchMode
                                ? AppPalette.accent.withValues(alpha: 0.5)
                                : AppPalette.stroke,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isBatchMode ? 'Batch Mode' : 'Pindah Hari',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isBatchMode
                                    ? AppPalette.accent
                                    : AppPalette.text,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Transform.scale(
                              scale: 0.75,
                              child: Switch(
                                value: isBatchMode,
                                activeTrackColor: AppPalette.accent,
                                onChanged: (val) {
                                  setDialogState(() {
                                    isBatchMode = val;
                                    if (!isBatchMode &&
                                        selectedDates.length > 1) {
                                      final first = selectedDates.first;
                                      selectedDates.clear();
                                      selectedDates.add(first);
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppPalette.textDim,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CalendarDatePicker(
                    initialDate: selectedDates.first,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    onDateChanged: (picked) {
                      final key = dateOnly(picked);
                      setDialogState(() {
                        if (isBatchMode) {
                          if (selectedDates.contains(key) &&
                              selectedDates.length > 1) {
                            selectedDates.remove(key);
                          } else {
                            selectedDates.add(key);
                          }
                        } else {
                          selectedDates.clear();
                          selectedDates.add(key);
                        }
                      });
                      if (!isBatchMode) {
                        ref.read(currentDateProvider.notifier).state = key;
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppPalette.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppPalette.stroke),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isBatchMode
                              ? Icons.copy_rounded
                              : Icons.today_rounded,
                          size: 16,
                          color: AppPalette.accent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isBatchMode
                                ? (selectedDates.length == 1
                                      ? 'Batch Mode: Pilih beberapa tanggal tujuan'
                                      : 'Batch Duplikasi ke ${selectedDates.length} Hari Terpilih')
                                : 'Tanggal Aktif: ${selectedDates.first.day}/${selectedDates.first.month}/${selectedDates.first.year}${isToday ? ' (Hari Ini)' : ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (!isToday && !isBatchMode)
                        OutlinedButton.icon(
                          onPressed: () {
                            final today = dateOnly(DateTime.now());
                            setDialogState(() {
                              selectedDates.clear();
                              selectedDates.add(today);
                            });
                            ref.read(currentDateProvider.notifier).state =
                                today;
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppPalette.accent,
                            side: BorderSide(
                              color: AppPalette.accent.withValues(alpha: 0.5),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          icon: const Icon(Icons.history_rounded, size: 15),
                          label: const Text(
                            'Hari Ini',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Tutup'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPalette.accent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                        ),
                        icon: Icon(
                          isBatchMode
                              ? Icons.copy_all_rounded
                              : Icons.check_circle_rounded,
                          size: 18,
                        ),
                        label: Text(
                          isBatchMode
                              ? (selectedDates.length > 1
                                    ? 'Terapkan (${selectedDates.length} Hari)'
                                    : 'Pilih Hari Tujuan')
                              : 'Buka Jadwal Tanggal Ini',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () async {
                          final primaryDate = selectedDates.first;
                          ref.read(currentDateProvider.notifier).state =
                              primaryDate;
                          if (isBatchMode && selectedDates.length > 1) {
                            final targets = selectedDates
                                .where((d) => d != currentDate)
                                .toList();
                            await _copyScheduleToDates(
                              context,
                              currentDate,
                              targets,
                            );
                          }
                          if (context.mounted) Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _onPanEnd() async {
    ref.read(isClockDraggingProvider.notifier).state = false;
    if (!_hasDragged) {
      _dragStartNotifier.value = null;
      _dragEndNotifier.value = null;
      _dragConflictNotifier.value = false;
      _hoverMinuteNotifier.value = null;
      _dragClickMinute = null;
      return;
    }
    if (_dragStartNotifier.value == null || _dragEndNotifier.value == null) {
      return;
    }
    final start = _dragStartNotifier.value!;
    final endVal = _dragEndNotifier.value!;
    final end = (endVal - start) < 5 ? start + 5 : endVal;
    final date = ref.read(currentDateProvider);

    _dragStartNotifier.value = null;
    _dragEndNotifier.value = null;
    _dragConflictNotifier.value = false;
    _hoverMinuteNotifier.value = null;
    _dragClickMinute = null;
    _lastPanMinute = null;

    HapticFeedback.lightImpact();
    if (!mounted) return;

    final result = await _showPresetPicker(context);
    final is24h = _is24h;
    final half = ref.read(ampmHalfProvider);
    final start24 = is24h ? start : (start + (half == AmPmHalf.pm ? 720 : 0));
    final end24 = is24h ? end : (end + (half == AmPmHalf.pm ? 720 : 0));

    final dbStart = toDbMinute(start24);
    final dbHalf = toDbHalf(start24);
    final dbEnd = toDbEndMinute(end24, dbHalf);

    if (result is Preset) {
      final activity = await activityFromPreset(
        preset: result,
        date: dateOnly(date),
        half: dbHalf,
        startMinute: dbStart,
        endMinute: dbEnd,
      );
      final lead =
          ref.read(settingsProvider).valueOrNull?.notifLeadMinutes ?? 1;
      await ref
          .read(activityRepoProvider)
          .upsert(activity, notifLeadMinutes: lead);
    } else if (result == 'custom') {
      final duration = end24 - start24;
      final activity = Activity()
        ..title = 'Fokus ${duration}m'
        ..date = dateOnly(date)
        ..ampmHalf = dbHalf
        ..startMinute = dbStart
        ..endMinute = dbEnd
        ..colorValue = presetColors.first;
      if (!mounted) return;
      await showActivityDetailSheet(
        context,
        activity: activity,
        mode: DetailMode.create,
      );
    } else {
      final duration = end24 - start24;
      if (duration >= 5) {
        final activity = Activity()
          ..title = 'Fokus ${duration}m'
          ..date = dateOnly(date)
          ..ampmHalf = dbHalf
          ..startMinute = dbStart
          ..endMinute = dbEnd
          ..colorValue = presetColors.first;
        final lead =
            ref.read(settingsProvider).valueOrNull?.notifLeadMinutes ?? 1;
        await ref
            .read(activityRepoProvider)
            .upsert(activity, notifLeadMinutes: lead);
      }
    }
  }

  Future<void> _onTapUp(
    Offset p,
    Size size,
    List<Activity> activities,
    int leadMinutes,
  ) async {
    if (_draggingActivity != null) return;
    final hit = _hitActivity(p, size, activities);
    if (hit == null) {
      final centered = _toCenter(p, size);
      final radius = centered.distance;
      final outer = size.shortestSide / 2 * 0.85 * _grow;
      final inner = size.shortestSide / 2 * 0.55 * _grow;
      if (radius < inner || radius > outer) return;

      final is24h = _is24h;
      final start = _snap(offsetToMinute(centered, is24h: is24h));
      final half = ref.read(ampmHalfProvider);
      final start24 = is24h
          ? start
          : start + (half == AmPmHalf.pm ? 720 : 0);
      final startDate = dateOnly(ref.read(currentDateProvider)).add(
        Duration(days: start24 ~/ 1440),
      );
      final startMinute = start24 % 1440;
      final endMinute = startMinute + 30;
      final dbHalf = toDbHalf(startMinute);
      final activity = Activity()
        ..title = ''
        ..startMinute = toDbMinute(startMinute)
        ..endMinute = toDbEndMinute(endMinute, dbHalf)
        ..ampmHalf = dbHalf
        ..date = startDate
        ..colorValue = presetColors.first;

      await showActivityDetailSheet(
        context,
        activity: activity,
        mode: DetailMode.create,
      );
      return;
    }

    final a = activities.firstWhere((x) => x.id == hit);
    if (ref.read(schedulingTaskProvider) != null) {
      final schedulingTask = ref.read(schedulingTaskProvider)!;
      schedulingTask.activityId = a.id;
      schedulingTask.date = a.date;
      schedulingTask.startMinute = a.startMinute;
      schedulingTask.endMinute = a.endMinute;
      schedulingTask.ampmHalf = a.ampmHalf;
      await ref.read(taskRepoProvider).update(schedulingTask);
      ref.read(schedulingTaskProvider.notifier).state = null;
      HapticFeedback.lightImpact();
      return;
    }

    await showActivityDetailSheet(context, activity: a, mode: DetailMode.view);
  }

  void _onLongPressStart(Offset p, Size size, List<Activity> activities) {
    final hit = _hitActivity(p, size, activities);
    if (hit == null) return;
    final a = activities.firstWhere((x) => x.id == hit);
    HapticFeedback.mediumImpact();

    ref.read(isClockDraggingProvider.notifier).state = true;
    _draggingActivity = a;

    final is24h = _is24h;
    final start = toUiMinute(a.startMinute, a.ampmHalf, is24h: is24h);
    final end = toUiMinute(a.endMinute, a.ampmHalf, is24h: is24h);
    _dragStartNotifier.value = start;
    _dragEndNotifier.value = end;
    _dragConflictNotifier.value = _hasConflict(
      start,
      end,
      activities,
      excludeId: a.id,
      is24h: is24h,
    );
  }

  void _onLongPressMove(Offset p, Size size, List<Activity> activities) {
    if (_draggingActivity == null) return;
    final centered = _toCenter(p, size);
    final is24h = _is24h;
    final newStart = _snap(offsetToMinute(centered, is24h: is24h));
    final duration =
        toUiMinute(
          _draggingActivity!.endMinute,
          _draggingActivity!.ampmHalf,
          is24h: is24h,
        ) -
        toUiMinute(
          _draggingActivity!.startMinute,
          _draggingActivity!.ampmHalf,
          is24h: is24h,
        );
    if (newStart == _dragStartNotifier.value) return;
    HapticFeedback.selectionClick();

    final limitMax = is24h ? 1440 : 720;
    final newEnd = (newStart + duration).clamp(0, limitMax);
    _dragStartNotifier.value = newStart;
    _dragEndNotifier.value = newEnd;
    _hoverMinuteNotifier.value = offsetToMinute(centered, is24h: is24h);
    _dragConflictNotifier.value = _hasConflict(
      newStart,
      newEnd,
      activities,
      excludeId: _draggingActivity!.id,
      is24h: is24h,
    );

    if (_isPrecisionMode && !_aimLockCtrl.isAnimating) {
      _aimLockCtrl.forward(from: 0.0);
    }
  }

  Future<void> _onLongPressEnd(int leadMinutes) async {
    ref.read(isClockDraggingProvider.notifier).state = false;
    if (_draggingActivity == null) return;

    final start = _dragStartNotifier.value!;
    final end = _dragEndNotifier.value!;
    final is24h = _is24h;
    final half = ref.read(ampmHalfProvider);
    final start24 = is24h ? start : (start + (half == AmPmHalf.pm ? 720 : 0));
    final end24 = is24h ? end : (end + (half == AmPmHalf.pm ? 720 : 0));

    final dbStart = toDbMinute(start24);
    final dbHalf = toDbHalf(start24);
    final dbEnd = toDbEndMinute(end24, dbHalf);

    final a = _draggingActivity!;
    a.startMinute = dbStart;
    a.endMinute = dbEnd;
    a.ampmHalf = dbHalf;
    await ref
        .read(activityRepoProvider)
        .upsert(a, notifLeadMinutes: leadMinutes);

    _draggingActivity = null;
    _dragStartNotifier.value = null;
    _dragEndNotifier.value = null;
    _dragConflictNotifier.value = false;
    _hoverMinuteNotifier.value = null;
  }

  Future<void> _onPresetDropped(Preset p) async {
    final now = DateTime.now();
    final date = ref.read(currentDateProvider);
    final is24h = _is24h;
    final half = ref.read(ampmHalfProvider);
    final dropMin =
        _hoverMinuteNotifier.value ??
        snap5(is24h ? (now.hour * 60 + now.minute) : minuteOfHalf(now));
    final start = dropMin;
    final end = is24h
        ? (start + 60).clamp(0, 1440)
        : (start + 60).clamp(0, 720);

    final start24 = is24h ? start : (start + (half == AmPmHalf.pm ? 720 : 0));
    final end24 = is24h ? end : (end + (half == AmPmHalf.pm ? 720 : 0));

    final dbStart = toDbMinute(start24);
    final dbHalf = toDbHalf(start24);
    final dbEnd = toDbEndMinute(end24, dbHalf);

    final a = await activityFromPreset(
      preset: p,
      date: dateOnly(date),
      half: dbHalf,
      startMinute: dbStart,
      endMinute: dbEnd,
    );
    if (!mounted) return;
    await showActivityDetailSheet(
      context,
      activity: a,
      mode: DetailMode.create,
    );
  }

  Future<void> _copyScheduleToDates(
    BuildContext context,
    DateTime sourceDate,
    List<DateTime> targetDates,
  ) async {
    final activityRepo = ref.read(activityRepoProvider);
    final sourceActivities = await activityRepo.getByDate(sourceDate);
    if (sourceActivities.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No activities on this day to copy.')),
        );
      }
      return;
    }

    final lead = ref.read(settingsProvider).valueOrNull?.notifLeadMinutes ?? 1;
    for (final targetDate in targetDates) {
      final targetActivities = await activityRepo.getByDate(targetDate);
      for (final a in targetActivities) {
        await activityRepo.delete(a.id);
      }
      for (final sa in sourceActivities) {
        final cloned = Activity()
          ..habitId = sa.habitId
          ..presetId = sa.presetId
          ..iconKey = sa.iconKey
          ..title = sa.title
          ..startMinute = sa.startMinute
          ..endMinute = sa.endMinute
          ..ampmHalf = sa.ampmHalf
          ..date = targetDate
          ..description = sa.description
          ..colorValue = sa.colorValue
          ..recurrence = 'none'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await activityRepo.upsert(cloned, notifLeadMinutes: lead);
      }
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied schedule to ${targetDates.length} day(s).'),
        ),
      );
    }
  }

  Future<void> _showCopyScheduleDialog(
    BuildContext context,
    DateTime sourceDate,
  ) async {
    final result = await showDialog<List<DateTime>>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppPalette.card,
        title: const Text(
          'Copy Day Schedule',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Copy this day\'s activities to other dates. Existing activities on those target dates will be overwritten.',
              style: TextStyle(fontSize: 12, color: AppPalette.textDim),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.accent.withValues(alpha: 0.15),
                foregroundColor: AppPalette.accent,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.next_plan_outlined, size: 18),
              label: const Text('Tomorrow'),
              onPressed: () {
                Navigator.pop(ctx, [sourceDate.add(const Duration(days: 1))]);
              },
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.accent.withValues(alpha: 0.15),
                foregroundColor: AppPalette.accent,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.date_range_outlined, size: 18),
              label: const Text('Next 3 Days'),
              onPressed: () {
                Navigator.pop(ctx, [
                  sourceDate.add(const Duration(days: 1)),
                  sourceDate.add(const Duration(days: 2)),
                  sourceDate.add(const Duration(days: 3)),
                ]);
              },
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.accent.withValues(alpha: 0.15),
                foregroundColor: AppPalette.accent,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.date_range, size: 18),
              label: const Text('Next 7 Days'),
              onPressed: () {
                Navigator.pop(
                  ctx,
                  List.generate(
                    7,
                    (i) => sourceDate.add(Duration(days: i + 1)),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.accent.withValues(alpha: 0.15),
                foregroundColor: AppPalette.accent,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.calendar_month_outlined, size: 18),
              label: const Text('Pick Specific Date...'),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: sourceDate.add(const Duration(days: 1)),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null && ctx.mounted) {
                  Navigator.pop(ctx, [dateOnly(picked)]);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppPalette.textDim),
            ),
          ),
        ],
      ),
    );

    if (result != null && context.mounted) {
      await _copyScheduleToDates(context, sourceDate, result);
    }
  }
}

class _AmPmMini extends StatelessWidget {
  const _AmPmMini({required this.half, required this.onChanged});
  final AmPmHalf half;
  final ValueChanged<AmPmHalf> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _seg(AmPmHalf.am),
          const SizedBox(width: 2),
          _seg(AmPmHalf.pm),
        ],
      ),
    );
  }

  Widget _seg(AmPmHalf value) {
    final active = half == value;
    return GestureDetector(
      onTap: active ? null : () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppPalette.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          value.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: active ? Colors.black : AppPalette.textDim,
          ),
        ),
      ),
    );
  }
}

class _FocusToolsControlBar extends ConsumerStatefulWidget {
  const _FocusToolsControlBar();

  @override
  ConsumerState<_FocusToolsControlBar> createState() =>
      _FocusToolsControlBarState();
}

class _FocusToolsControlBarState extends ConsumerState<_FocusToolsControlBar> {
  bool _isHourUnit = false;
  double _sliderValue = 30;

  @override
  Widget build(BuildContext context) {
    final isInstantActive = ref.watch(isInstantModeProvider);
    final currentMinutes = _isHourUnit
        ? (_sliderValue * 60).round()
        : _sliderValue.round();

    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          final delta = event.scrollDelta.dy;
          setState(() {
            if (_isHourUnit) {
              _sliderValue = (_sliderValue - (delta > 0 ? 0.5 : -0.5)).clamp(
                0.5,
                12.0,
              );
            } else {
              _sliderValue = (_sliderValue - (delta > 0 ? 5.0 : -5.0)).clamp(
                1.0,
                180.0,
              );
            }
          });
          ref.read(instantIntervalProvider.notifier).state = (_isHourUnit
              ? (_sliderValue * 60).round()
              : _sliderValue.round());
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        constraints: const BoxConstraints(maxWidth: 350),
        decoration: BoxDecoration(
          color: AppPalette.card.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppPalette.accent.withValues(alpha: 0.4),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppPalette.accent.withValues(alpha: 0.18),
              blurRadius: 16,
              spreadRadius: 1,
            ),
            const BoxShadow(
              color: Colors.black45,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Instant Slider Mode ON/OFF Switch
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'ON',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppPalette.accent,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Transform.scale(
                      scale: 0.75,
                      child: Switch(
                        value: isInstantActive,
                        activeTrackColor: AppPalette.accent,
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          ref.read(isInstantModeProvider.notifier).state = val;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 2),

                // Unit Switcher Button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _isHourUnit = !_isHourUnit;
                      if (_isHourUnit) {
                        _sliderValue = (_sliderValue / 60).clamp(0.5, 12.0);
                      } else {
                        _sliderValue = (_sliderValue * 60).clamp(1.0, 180.0);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppPalette.accent.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Text(
                      _isHourUnit ? 'JAM' : 'MENIT',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppPalette.accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Duration Display
                Text(
                  _isHourUnit
                      ? '${_sliderValue.toStringAsFixed(1)}h'
                      : '${currentMinutes}m',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.text,
                  ),
                ),
                const SizedBox(width: 4),

                // Interactive Slider
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                      activeTrackColor: AppPalette.accent,
                      inactiveTrackColor: AppPalette.stroke,
                      thumbColor: AppPalette.accent,
                    ),
                    child: Slider(
                      value: _sliderValue.clamp(
                        _isHourUnit ? 0.5 : 5.0,
                        _isHourUnit ? 12.0 : 180.0,
                      ),
                      min: _isHourUnit ? 0.5 : 5.0,
                      max: _isHourUnit ? 12.0 : 180.0,
                      divisions: _isHourUnit ? 23 : 35,
                      onChanged: (val) {
                        final snapped = _isHourUnit
                            ? val
                            : (val / 5).round() * 5.0;
                        setState(() => _sliderValue = snapped);
                        ref
                            .read(instantIntervalProvider.notifier)
                            .state = _isHourUnit
                            ? (snapped * 60).round()
                            : snapped.round();
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Quick Presets Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _QuickPresetChip(
                    label: '15m',
                    onTap: () {
                      setState(() {
                        _isHourUnit = false;
                        _sliderValue = 15;
                      });
                      ref.read(instantIntervalProvider.notifier).state = 15;
                      HapticFeedback.selectionClick();
                    },
                  ),
                  const SizedBox(width: 4),
                  _QuickPresetChip(
                    label: '30m',
                    onTap: () {
                      setState(() {
                        _isHourUnit = false;
                        _sliderValue = 30;
                      });
                      ref.read(instantIntervalProvider.notifier).state = 30;
                      HapticFeedback.selectionClick();
                    },
                  ),
                  const SizedBox(width: 4),
                  _QuickPresetChip(
                    label: '45m',
                    onTap: () {
                      setState(() {
                        _isHourUnit = false;
                        _sliderValue = 45;
                      });
                      ref.read(instantIntervalProvider.notifier).state = 45;
                      HapticFeedback.selectionClick();
                    },
                  ),
                  const SizedBox(width: 4),
                  _QuickPresetChip(
                    label: '1 Jam',
                    onTap: () {
                      setState(() {
                        _isHourUnit = true;
                        _sliderValue = 1.0;
                      });
                      ref.read(instantIntervalProvider.notifier).state = 60;
                      HapticFeedback.selectionClick();
                    },
                  ),
                  const SizedBox(width: 4),
                  _QuickPresetChip(
                    label: '2 Jam',
                    onTap: () {
                      setState(() {
                        _isHourUnit = true;
                        _sliderValue = 2.0;
                      });
                      ref.read(instantIntervalProvider.notifier).state = 120;
                      HapticFeedback.selectionClick();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickPresetChip extends StatelessWidget {
  const _QuickPresetChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: AppPalette.bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppPalette.stroke),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: AppPalette.textDim,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
