import 'habit_action_save_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/intent_repository.dart';
import '../../../domain/focus_intent.dart';
import '../../../domain/today_intent_projection.dart';
import '../../../models/habit.dart';
import '../../../models/habit_entry.dart';
import '../../../models/task.dart';
import '../../../providers/intent_providers.dart';
import '../../../providers/sadar_providers.dart';
import '../../../services/sadar_timer_engine.dart';

class HomeIntentCue extends ConsumerStatefulWidget {
  const HomeIntentCue({
    super.key,
    required this.foreground,
    required this.secondary,
    required this.accent,
    required this.surface,
    required this.onHabitTimer,
    this.onHabitSchedule,
    required this.onTaskSchedule,
    required this.onSession,
  });
  final Color foreground, secondary, accent, surface;
  final void Function(Habit) onHabitTimer;
  final void Function(Habit)? onHabitSchedule;
  final Future<void> Function(Task) onTaskSchedule;
  final VoidCallback onSession;
  @override
  ConsumerState<HomeIntentCue> createState() => _HomeIntentCueState();
}

class _HomeIntentCueState extends ConsumerState<HomeIntentCue> {
  bool _busy = false;
  String? _error;
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(intentStateProvider);
    final data = ref.watch(intentSourceDataProvider);
    final date = state.hasValue
        ? ref.watch(actualIntentDateProvider)
        : intentLocalDate(DateTime.now());
    // The cue doesn't subscribe to the session's second-by-second countdown.
    final session = ref.watch(
      timerEngineProvider.select(
        (s) => (s.isActive, s.isPaused, s.habitName, s.restoreError),
      ),
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.secondary.withValues(alpha: .25)),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: widget.foreground),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            state.when(
              loading: () => const LinearProgressIndicator(
                semanticsLabel: 'Memuat tujuan',
              ),
              error: (e, _) => _failure(e, () {
                ref.invalidate(intentInitializationProvider);
                ref.invalidate(intentStateProvider);
              }),
              data: (intent) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tujuan jangka panjang',
                    style: TextStyle(color: widget.secondary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          intent.pinnedGoal?.title ??
                              'Apa arah yang ingin kamu jaga?',
                          style: TextStyle(
                            fontSize: 20,
                            height: 1.3,
                            color: widget.foreground,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Ubah tujuan',
                        onPressed: () => _goals(intent),
                        icon: Icon(Icons.edit_outlined, color: widget.accent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (session.$1) ...[
                    Text(
                      '${session.$2 ? 'Sesi dijeda' : 'Sesi berjalan'}: ${session.$3}',
                    ),
                    FilledButton(
                      style: _primaryStyle,
                      onPressed: widget.onSession,
                      child: Text(session.$2 ? 'Lanjutkan sesi' : 'Buka sesi'),
                    ),
                  ] else
                    data.when(
                      loading: () => const LinearProgressIndicator(
                        semanticsLabel: 'Memuat pilihan hari ini',
                      ),
                      error: (e, _) => _failure(
                        e,
                        () => ref.invalidate(intentSourceDataProvider),
                      ),
                      data: (sources) => _choice(intent, sources, date),
                    ),
                  Builder(
                    builder: (context) {
                      final choice = data.hasValue
                          ? TodayIntentProjection.calculate(
                              state: intent,
                              actualDate: date,
                              habits: data.requireValue.habits,
                              tasks: data.requireValue.tasks,
                              entries: data.requireValue.entries,
                            )
                          : null;
                      final primary =
                          !session.$1 &&
                          data.hasValue &&
                          (choice == null ||
                              choice.completed ||
                              choice.kind == IntentActionKind.unavailable);
                      final action = data.hasValue
                          ? () => _choose(intent, data.requireValue, date)
                          : null;
                      return primary
                          ? FilledButton.icon(
                              style: _primaryStyle,
                              onPressed: action,
                              icon: const Icon(Icons.today_outlined),
                              label: const Text(
                                'Pilih tindakan hari ini',
                                textAlign: TextAlign.center,
                              ),
                            )
                          : TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: widget.accent,
                                minimumSize: const Size(48, 48),
                              ),
                              onPressed: action,
                              icon: const Icon(Icons.today_outlined),
                              label: const Text(
                                'Pilih tindakan hari ini',
                                textAlign: TextAlign.center,
                              ),
                            );
                    },
                  ),
                ],
              ),
            ),
            if (_busy) const LinearProgressIndicator(),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    );
  }

  ButtonStyle get _primaryStyle => FilledButton.styleFrom(
    backgroundColor: widget.accent,
    foregroundColor: widget.surface,
    minimumSize: const Size(48, 48),
  );

  Widget _failure(Object error, VoidCallback retry) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Belum dapat memuat: $error'),
      TextButton(onPressed: retry, child: const Text('Coba lagi tujuan')),
    ],
  );
  Widget _choice(IntentState state, IntentSourceData data, String date) {
    final choice = TodayIntentProjection.calculate(
      state: state,
      actualDate: date,
      habits: data.habits,
      tasks: data.tasks,
      entries: data.entries,
    );
    if (choice == null || choice.completed) {
      final agenda = ref.watch(intentAgendaProvider);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            choice?.completed == true
                ? 'Pilihan hari ini selesai: ${choice!.title}'
                : 'Belum ada tindakan yang dipilih hari ini',
            style: TextStyle(color: widget.secondary),
          ),
          agenda.when(
            loading: () => const Text('Memuat agenda…'),
            error: (e, _) =>
                _failure(e, () => ref.invalidate(intentAgendaProvider)),
            data: (rows) {
              final now = ref.watch(intentNowProvider);
              final minute = now.hour * 60 + now.minute;
              final upcoming =
                  rows
                      .where(
                        (a) =>
                            !a.isCompleted &&
                            a.endMinute + a.ampmHalf.index * 720 > minute,
                      )
                      .toList()
                    ..sort(
                      (a, b) => (a.startMinute + a.ampmHalf.index * 720)
                          .compareTo(b.startMinute + b.ampmHalf.index * 720),
                    );
              return upcoming.isEmpty
                  ? const SizedBox.shrink()
                  : Text(
                      'Direncanakan: ${upcoming.first.title}',
                      style: TextStyle(color: widget.secondary),
                    );
            },
          ),
        ],
      );
    }
    final label = switch (choice.kind) {
      IntentActionKind.timed => 'Mulai fokus',
      IntentActionKind.binary => 'Tandai dilakukan',
      IntentActionKind.count => 'Catat jumlah',
      IntentActionKind.task =>
        choice.task?.activityId != null || choice.task?.startMinute != null
            ? 'Buka jadwal tugas'
            : 'Jadwalkan tugas',
      IntentActionKind.unsupported => 'Lihat rincian',
      IntentActionKind.unavailable => 'Sumber tidak tersedia',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pilihan hari ini', style: TextStyle(color: widget.secondary)),
        if (choice.habit case final habit?)
          if (!habit.isArchived &&
              habit.habitType == 'timed' &&
              habit.unit == HabitUnit.min &&
              habit.target > 0 &&
              widget.onHabitSchedule != null)
            TextButton(
              onPressed: _busy ? null : () => widget.onHabitSchedule!(habit),
              child: const Text('Atur waktu'),
            ),
        Text(choice.title, style: const TextStyle(fontSize: 16)),
        if (state.links
                .where((l) => l.sourceId == state.selectionFor(date)?.sourceId)
                .firstOrNull
            case final link?)
          Text(
            'Tujuan: ${state.goals.where((g) => g.id == link.goalId).firstOrNull?.title ?? 'Tidak tersedia'}${state.goals.where((g) => g.id == link.goalId).firstOrNull?.archived == true ? ' (diarsipkan)' : ''}',
            style: TextStyle(color: widget.secondary),
          ),
        if (choice.kind != IntentActionKind.unavailable)
          FilledButton(
            style: _primaryStyle,
            onPressed: _busy || choice.kind == IntentActionKind.unavailable
                ? null
                : () => _act(choice, date),
            child: Text(label),
          ),
      ],
    );
  }

  Future<void> _act(TodayIntentProjection choice, String date) async {
    setState(() {
      _busy =
          choice.kind != IntentActionKind.count &&
          choice.kind != IntentActionKind.unsupported;
      _error = null;
    });
    try {
      if (ref.read(timerEngineProvider).isActive) {
        widget.onSession();
        return;
      }
      switch (choice.kind) {
        case IntentActionKind.timed:
          widget.onHabitTimer(choice.habit!);
        case IntentActionKind.task:
          await widget.onTaskSchedule(choice.task!);
        case IntentActionKind.binary:
          await ref
              .read(sadarRepoProvider)
              .recordEntryStatus(
                habitId: choice.habit!.id,
                dateString: date,
                status: HabitStatus.yes,
                valueCompleted: 1,
                actualDurationMinutes: 0,
                preserveDuration: true,
              );
        case IntentActionKind.count:
          await _count(choice.habit!, date);
        case IntentActionKind.unsupported:
          await _showIntentDialog(
            context: context,
            builder: (c) => AlertDialog(
              title: Text(choice.title),
              content: Text(habitExecutionLimit(choice.habit!)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text('Tutup'),
                ),
              ],
            ),
          );
        case IntentActionKind.unavailable:
          break;
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Belum tersimpan: $e. Coba tindakan lagi.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _count(Habit habit, String date) async {
    final controller = TextEditingController();
    final sources = ref.read(intentSourceDataProvider).requireValue;
    final old = sources.entries
        .where((e) => e.habitId == habit.id && e.dateString == date)
        .firstOrNull;
    controller.text = '${old?.valueCompleted ?? 0}';
    await _showIntentDialog(
      context: context,
      builder: (c) => HabitActionSaveDialog(
        title: 'Jumlah ${habit.name}',
        body: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Jumlah total hari ini'),
        ),
        onSave: () async {
          final value = int.tryParse(controller.text);
          if (value == null || value < 0 || value > 9999) {
            throw StateError('Masukkan jumlah 0–9999.');
          }
          await ref
              .read(sadarRepoProvider)
              .setHabitCount(habitId: habit.id, dateString: date, value: value);
        },
      ),
    );
    controller.dispose();
  }

  Future<void> _goals(IntentState initial) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (c) => _GoalEditor(foreground: widget.foreground),
    );
  }

  Future<void> _choose(
    IntentState initial,
    IntentSourceData sources,
    String date,
  ) async {
    final selected = initial.sourceFor(initial.selectionFor(date)?.sourceId);
    String? key =
        selected == null || selected.sourceStoreId != initial.sourceStoreId
        ? null
        : '${selected.type.name}/${selected.legacyId}';
    String? goalId = initial.links
        .where((l) => l.sourceId == selected?.id)
        .firstOrNull
        ?.goalId;
    final available = <String, String>{
      for (final h in sources.habits.where((h) => !h.isArchived))
        'habit/${h.id}': h.name,
      for (final t in sources.tasks.where((t) => !t.isCompleted))
        'task/${t.id}': t.title,
    };
    final unavailableKey = selected != null && !available.containsKey(key)
        ? 'unavailable/${selected.id}'
        : null;
    if (unavailableKey != null) key = unavailableKey;
    if (!initial.goals.any((g) => g.id == goalId && !g.archived)) goalId = null;
    await _showIntentDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, update) => HabitActionSaveDialog(
          title: 'Tindakan hari ini',
          body: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: key,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Habit atau tugas',
                ),
                items: [
                  if (unavailableKey != null)
                    DropdownMenuItem<String>(
                      value: unavailableKey,
                      child: const Text(
                        'Pilihan tersimpan tidak tersedia',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Kosongkan pilihan'),
                  ),
                  ...available.entries.map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (v) => update(() => key = v),
              ),
              DropdownButtonFormField<String>(
                initialValue: goalId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Hubungkan tujuan (opsional)',
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Tanpa tujuan'),
                  ),
                  ...initial.goals
                      .where((g) => !g.archived)
                      .map(
                        (g) => DropdownMenuItem(
                          value: g.id,
                          child: Text(g.title, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                ],
                onChanged: key == unavailableKey && unavailableKey != null
                    ? null
                    : (v) => update(() => goalId = v),
              ),
            ],
          ),
          onSave: () async {
            if (unavailableKey != null && key == unavailableKey) return;
            final parts = key?.split('/');
            await ref
                .read(intentRepositoryProvider)
                .choose(
                  localDate: date,
                  type: parts == null
                      ? null
                      : IntentSourceType.values.byName(parts.first),
                  legacyId: parts == null ? null : int.parse(parts.last),
                  goalId: key == null ? null : goalId,
                  expectedRevision: initial.selectionFor(date)?.revision,
                );
          },
        ),
      ),
    );
  }
}

class _GoalEditor extends ConsumerWidget {
  const _GoalEditor({required this.foreground});
  final Color foreground;
  @override
  Widget build(BuildContext context, WidgetRef ref) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .65,
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Tujuan jangka panjang',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                IconButton(
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Expanded(
              child: ref
                  .watch(intentStateProvider)
                  .when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('$e'),
                    data: (state) => ListView(
                      children: [
                        for (final goal in state.goals.where(
                          (g) => !g.archived,
                        ))
                          ListTile(
                            title: Text(goal.title),
                            subtitle: Text(
                              goal.pinned ? 'Disematkan di Home' : 'Tujuan',
                            ),
                            onTap: () => _edit(context, ref, goal),
                            trailing: const Icon(Icons.edit_outlined),
                          ),
                        if (state.goals.where((g) => !g.archived).isEmpty)
                          const Text('Tujuan boleh kosong.'),
                        TextButton.icon(
                          onPressed: () => _edit(context, ref, null),
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah tujuan'),
                        ),
                      ],
                    ),
                  ),
            ),
          ],
        ),
      ),
    ),
  );
  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    IntentGoal? goal,
  ) async {
    final title = TextEditingController(text: goal?.title ?? '');
    final id = goal?.id ?? IntentRepository.newId();
    bool pinned = goal?.pinned ?? false;
    bool archived = false;
    await _showIntentDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, update) => HabitActionSaveDialog(
          title: goal == null ? 'Tambah tujuan' : 'Ubah tujuan',
          body: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                maxLength: 120,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Tujuan'),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sematkan di Home'),
                value: pinned,
                onChanged: (v) => update(() => pinned = v ?? false),
              ),
              if (goal != null)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Arsipkan tujuan'),
                  subtitle: const Text('Habit dan riwayat tetap disimpan'),
                  value: archived,
                  onChanged: (v) => update(() => archived = v ?? false),
                ),
            ],
          ),
          onSave: () async {
            await ref
                .read(intentRepositoryProvider)
                .saveGoal(
                  id: id,
                  title: title.text,
                  expectedRevision: goal?.revision,
                  pinned: pinned,
                  archived: archived,
                );
          },
        ),
      ),
    );
    title.dispose();
  }
}

Future<void> _showIntentDialog({
  required BuildContext context,
  required WidgetBuilder builder,
}) async {
  final route = DialogRoute<void>(
    context: context,
    builder: builder,
    barrierDismissible: false,
  );
  await Navigator.of(context, rootNavigator: true).push(route);
  // Keep controllers alive until the exit transition has removed their fields.
  await route.completed;
}
