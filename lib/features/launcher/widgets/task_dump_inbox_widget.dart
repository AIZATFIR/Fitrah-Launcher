import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time_math.dart';
import '../../../models/activity.dart';
import '../../../models/task.dart';
import '../../../providers/providers.dart';

/// Task Dump Inbox Widget (Google Tasks Style)
/// Fast capture input, 2px square bento aesthetic, 1-tap Focus Now,
/// and smooth time slot allocation to the 24-hour Focus Clock ring.
class TaskDumpInboxWidget extends ConsumerStatefulWidget {
  const TaskDumpInboxWidget({
    super.key,
    this.onTaskScheduled,
  });

  final VoidCallback? onTaskScheduled;

  @override
  ConsumerState<TaskDumpInboxWidget> createState() => _TaskDumpInboxWidgetState();
}

class _TaskDumpInboxWidgetState extends ConsumerState<TaskDumpInboxWidget> {
  final TextEditingController _taskInputCtrl = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();

  @override
  void dispose() {
    _taskInputCtrl.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _addTask() {
    final title = _taskInputCtrl.text.trim();
    if (title.isEmpty) return;

    HapticFeedback.lightImpact();
    ref.read(taskRepoProvider).add(Task()..title = title);
    _taskInputCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(eisenhowerTasksProvider);
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(color: theme.dividerColor, width: 1),
        borderRadius: BorderRadius.circular(2), // 2px Square Bento rule
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Title & Count ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 3.5,
                      height: 14,
                      color: accentColor,
                      margin: const EdgeInsets.only(right: 8),
                    ),
                    Text(
                      'DAILY TASKS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
                tasksAsync.maybeWhen(
                  data: (tasks) {
                    final pending = tasks.where((t) => !t.isCompleted).length;
                    return Text(
                      '$pending pending',
                      style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4)),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // ── Quick Capture Input (Google Tasks Style) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskInputCtrl,
                    focusNode: _inputFocusNode,
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Dump tugas hari ini... (tekan Enter)',
                      hintStyle: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.35)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFF0F1511),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(2),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                    ),
                    onSubmitted: (_) => _addTask(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: _addTask,
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFF222622)),

          // ── Tasks List ──
          tasksAsync.when(
            data: (tasks) {
              if (tasks.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'Belum ada task. Ketik di atas lalu tekan enter.',
                      style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4)),
                    ),
                  ),
                );
              }

              // Pending first, then completed
              final sortedTasks = List<Task>.from(tasks)
                ..sort((a, b) {
                  if (a.isCompleted != b.isCompleted) {
                    return a.isCompleted ? 1 : -1;
                  }
                  return b.createdAt.compareTo(a.createdAt);
                });

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedTasks.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF1E221E)),
                itemBuilder: (context, index) {
                  final task = sortedTasks[index];
                  final isScheduled = task.startMinute != null && task.endMinute != null;

                  return InkWell(
                    onTap: () => _showTaskAllocationSheet(context, task),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(
                        children: [
                          // 2px Square Checkbox
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              ref.read(taskRepoProvider).toggleCompletion(task.id);
                            },
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: task.isCompleted ? accentColor : Colors.transparent,
                                border: Border.all(
                                  color: task.isCompleted ? accentColor : Colors.white38,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: task.isCompleted
                                  ? const Icon(Icons.check, size: 13, color: Colors.black)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Title
                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 13,
                                color: task.isCompleted ? Colors.white30 : Colors.white,
                                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),

                          // Time Badge or "+ Jam"
                          if (isScheduled)
                            GestureDetector(
                              onTap: () => _showTaskAllocationSheet(context, task),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(color: accentColor.withOpacity(0.4), width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.schedule, size: 10, color: accentColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_formatMinute(task.startMinute!)} - ${_formatMinute(task.endMinute!)}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: accentColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            GestureDetector(
                              onTap: () => _showTaskAllocationSheet(context, task),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: const Text(
                                  '+ Jam',
                                  style: TextStyle(fontSize: 10, color: Colors.white38),
                                ),
                              ),
                            ),

                          // Delete task
                          IconButton(
                            icon: const Icon(Icons.close, size: 14, color: Colors.white24),
                            padding: const EdgeInsets.only(left: 6),
                            constraints: const BoxConstraints(),
                            splashRadius: 14,
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              ref.read(taskRepoProvider).delete(task.id);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const SizedBox(height: 60),
            error: (e, _) => Text('Error tasks: $e'),
          ),
        ],
      ),
    );
  }

  String _formatMinute(int minuteOfDay) {
    final h = (minuteOfDay ~/ 60).toString().padLeft(2, '0');
    final m = (minuteOfDay % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ── Focus Clock Allocation Sheet ──
  void _showTaskAllocationSheet(BuildContext context, Task task) {
    final now = DateTime.now();
    int currentMinuteOfDay = now.hour * 60 + now.minute;
    int startMinute = task.startMinute ?? currentMinuteOfDay;
    int duration = task.endMinute != null ? (task.endMinute! - startMinute).clamp(15, 240) : 45;

    final titleCtrl = TextEditingController(text: task.title);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151E17),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2),
        side: const BorderSide(color: Color(0xFF28362B)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final endMinute = (startMinute + duration).clamp(0, 1439);
          final theme = Theme.of(context);
          final accent = theme.colorScheme.primary;

          return Padding(
            padding: EdgeInsets.only(
              left: 18,
              right: 18,
              top: 18,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ALOKASI FOCUS CLOCK',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.white54),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Editable Title
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: 'Nama Task',
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF0F1511),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(2),
                      borderSide: const BorderSide(color: Color(0xFF28362B)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── 1-Tap "Fokus Sekarang (45 Menit)" Button ──
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: const Text(
                      '▶ FOKUS SEKARANG (45 MENIT)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                    ),
                    onPressed: () async {
                      final n = DateTime.now();
                      final curMin = n.hour * 60 + n.minute;
                      final endMin = (curMin + 45).clamp(0, 1439);

                      final activity = Activity()
                        ..title = titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : task.title
                        ..date = dateOnly(n)
                        ..startMinute = toDbMinute(curMin)
                        ..endMinute = toDbMinute(endMin)
                        ..ampmHalf = toDbHalf(curMin)
                        ..colorValue = accent.value
                        ..createdAt = n
                        ..updatedAt = n;

                      final actId = await ref.read(activityRepoProvider).upsert(activity);

                      task.title = activity.title;
                      task.startMinute = curMin;
                      task.endMinute = endMin;
                      task.activityId = actId;
                      task.updatedAt = n;
                      await ref.read(taskRepoProvider).update(task);

                      if (context.mounted) Navigator.pop(ctx);
                      widget.onTaskScheduled?.call();
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // ── Custom Time Slot Scheduler ──
                Text(
                  'Atur Jadwal di Jam Analog (24 Jam):',
                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),

                // Time Range Display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1511),
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: const Color(0xFF28362B)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('MULAI', style: TextStyle(fontSize: 9, color: Colors.white38)),
                          Text(
                            _formatMinute(startMinute),
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: accent),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white24, size: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SELESAI', style: TextStyle(fontSize: 9, color: Colors.white38)),
                          Text(
                            _formatMinute(endMinute),
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: accent),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          '$duration mnt',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accent),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Duration Preset Chips (15m, 30m, 45m, 60m, 90m, 120m)
                Wrap(
                  spacing: 6,
                  children: [15, 30, 45, 60, 90, 120].map((m) {
                    final isSel = duration == m;
                    return GestureDetector(
                      onTap: () => setModalState(() => duration = m),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSel ? accent.withOpacity(0.2) : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: isSel ? accent : Colors.transparent,
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          '$m mnt',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                            color: isSel ? accent : Colors.white70,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),

                // Start Minute Slider
                Row(
                  children: [
                    const Text('Jam Mulai: ', style: TextStyle(fontSize: 11, color: Colors.white54)),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: accent,
                          inactiveTrackColor: Colors.white12,
                          thumbColor: accent,
                          overlayColor: accent.withOpacity(0.2),
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        ),
                        child: Slider(
                          value: startMinute.toDouble(),
                          min: 0,
                          max: 1410,
                          divisions: 94,
                          onChanged: (val) {
                            setModalState(() => startMinute = val.round());
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Action Buttons: Delete & Save to Focus Clock
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                      tooltip: 'Hapus Task',
                      onPressed: () {
                        ref.read(taskRepoProvider).delete(task.id);
                        Navigator.pop(ctx);
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          final name = titleCtrl.text.trim();
                          if (name.isNotEmpty) {
                            task.title = name;
                            ref.read(taskRepoProvider).update(task);
                          }
                          Navigator.pop(ctx);
                        },
                        child: const Text('SIMPAN JUDUL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          final name = titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : task.title;
                          final act = Activity()
                            ..title = name
                            ..date = dateOnly(DateTime.now())
                            ..startMinute = toDbMinute(startMinute)
                            ..endMinute = toDbMinute(endMinute)
                            ..ampmHalf = toDbHalf(startMinute)
                            ..colorValue = accent.value
                            ..createdAt = DateTime.now()
                            ..updatedAt = DateTime.now();

                          final actId = await ref.read(activityRepoProvider).upsert(act);

                          task.title = name;
                          task.startMinute = startMinute;
                          task.endMinute = endMinute;
                          task.activityId = actId;
                          task.updatedAt = DateTime.now();
                          await ref.read(taskRepoProvider).update(task);

                          if (context.mounted) Navigator.pop(ctx);
                          widget.onTaskScheduled?.call();
                        },
                        child: const Text(
                          'PLOT KE CLOCK',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
