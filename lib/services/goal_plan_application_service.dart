import 'package:uuid/uuid.dart';

import '../core/time_math.dart';
import '../data/store/focus_store.dart';
import '../domain/focus_intent.dart';
import '../domain/goal_plan_proposal.dart';
import '../models/activity.dart';
import '../models/focus_intent_document.dart';
import '../models/habit.dart';

class GoalPlanApplyResult {
  const GoalPlanApplyResult({
    required this.goalId,
    required this.habitId,
    required this.activityIds,
  });
  final String goalId;
  final int habitId;
  final List<int> activityIds;
  @override
  bool operator ==(Object other) =>
      other is GoalPlanApplyResult &&
      goalId == other.goalId &&
      habitId == other.habitId &&
      _same(activityIds, other.activityIds);
  @override
  int get hashCode => Object.hash(goalId, habitId, Object.hashAll(activityIds));
}

/// The only mutation path for an approved goal plan.
class GoalPlanApplicationService {
  GoalPlanApplicationService(this.store, {DateTime Function()? now})
    : now = now ?? DateTime.now;
  final FocusStore store;
  final DateTime Function() now;

  Future<List<String>> previewConflicts(
    PlanProposal proposal, {
    String? goalId,
  }) async {
    _checkStore();
    final current = now();
    _checkTargetDate(proposal, current);
    final activities = await store.activitys.all();
    final documents = await store.focusIntentDocuments.all();
    final state = documents.length == 1
        ? IntentState.decode(documents.single.payload)
        : null;
    final previous = goalId == null
        ? null
        : state?.planReceipts.where((r) => r.goalId == goalId).lastOrNull;
    return _conflicts(
      proposal,
      activities,
      current,
      excludingActivityIds: previous?.activityIds.toSet() ?? const {},
    );
  }

  Future<GoalPlanApplyResult> apply({
    required String operationId,
    required PlanProposal proposal,
    String? goalId,
    int? expectedGoalRevision,
  }) async {
    _checkStore();
    if (operationId.trim().isEmpty || operationId.length > 120) {
      throw ArgumentError.value(
        operationId,
        'operationId',
        'Must be 1–120 characters.',
      );
    }
    final currentTime = now();
    _checkTargetDate(proposal, currentTime);
    final fingerprint =
        '${proposal.fingerprintInput}|goalId=$goalId|revision=$expectedGoalRevision';
    return store.writeTxn(() async {
      final documents = await store.focusIntentDocuments.all();
      if (documents.length > 1 || documents.any((d) => d.id != 1)) {
        throw const FormatException('Invalid intent singleton');
      }
      final state = documents.isEmpty
          ? IntentState(sourceStoreId: const Uuid().v4())
          : IntentState.decode(documents.single.payload);
      final receipt = state.planReceipts
          .where((r) => r.operationId == operationId)
          .firstOrNull;
      if (receipt != null) {
        if (receipt.fingerprint != fingerprint) {
          throw StateError('Operation ID already used with different input.');
        }
        return GoalPlanApplyResult(
          goalId: receipt.goalId,
          habitId: receipt.habitId,
          activityIds: receipt.activityIds,
        );
      }

      final existingGoal = goalId == null
          ? null
          : state.goals.where((g) => g.id == goalId).firstOrNull;
      if ((goalId == null) != (expectedGoalRevision == null) ||
          (goalId != null &&
              (existingGoal == null ||
                  existingGoal.archived ||
                  existingGoal.revision != expectedGoalRevision))) {
        throw StateError(
          'Tujuan berubah. Muat ulang rencana sebelum menerapkan.',
        );
      }
      final previousReceipt = existingGoal == null
          ? null
          : state.planReceipts
                .where((r) => r.goalId == existingGoal.id)
                .lastOrNull;
      final previousActivityIds = previousReceipt?.activityIds.toSet() ?? {};
      final conflicts = _conflicts(
        proposal,
        await store.activitys.all(),
        currentTime,
        excludingActivityIds: previousActivityIds,
      );
      if (conflicts.isNotEmpty) throw StateError(conflicts.join('\n'));

      final newGoalId = goalId ?? const Uuid().v4();
      final goal = IntentGoal(
        id: newGoalId,
        title: proposal.goal.title.trim(),
        why: proposal.goal.why?.trim().isEmpty ?? true
            ? null
            : proposal.goal.why!.trim(),
        targetDate: proposal.goal.targetDate,
        pinned: existingGoal?.pinned ?? state.pinnedGoal == null,
        archived: false,
        revision: (existingGoal?.revision ?? 0) + 1,
      );
      final unpinnedGoals = state.goals
          .map(
            (g) => g.pinned && goal.pinned
                ? IntentGoal(
                    id: g.id,
                    title: g.title,
                    why: g.why,
                    targetDate: g.targetDate,
                    archived: g.archived,
                    revision: g.revision + 1,
                  )
                : g,
          )
          .where((g) => g.id != newGoalId)
          .toList();

      final storedHabit = previousReceipt == null
          ? null
          : await store.habits.get(previousReceipt.habitId);
      final habit = (storedHabit ?? Habit())
        ..name = proposal.goal.title.trim()
        ..target = proposal.blocks
            .map((b) => b.durationMinutes)
            .reduce((a, b) => a > b ? a : b)
        ..unit = HabitUnit.min
        ..thingType = ThingType.habit
        ..habitType = 'timed'
        ..timerEnabled = true
        ..recurrence = 'custom'
        ..preferredTime = _formatMinute(proposal.blocks.first.startMinute)
        ..colorValue = 0xffd8bd74
        ..createdAt = storedHabit?.createdAt ?? currentTime;
      final habitId = await store.habits.put(habit);
      final source =
          state.sources
              .where(
                (s) =>
                    s.sourceStoreId == state.sourceStoreId &&
                    s.type == IntentSourceType.habit &&
                    s.legacyId == habitId,
              )
              .firstOrNull ??
          IntentSource(
            id: const Uuid().v4(),
            sourceStoreId: state.sourceStoreId,
            type: IntentSourceType.habit,
            legacyId: habitId,
          );

      final oldActivities = {
        for (final activity in await store.activitys.all())
          activity.id: activity,
      };
      final terminalActivityIds = (await store.terminalFocusSessions.all())
          .map((session) => session.activityId)
          .whereType<int>()
          .toSet();
      final retainedEvidence = <Activity>[];
      for (final id in previousActivityIds) {
        final old = oldActivities[id];
        if (old == null) continue;
        if (old.isCompleted ||
            old.actualDurationSeconds > 0 ||
            terminalActivityIds.contains(id)) {
          old.recurrence = 'none';
          old.updatedAt = currentTime;
          await store.activitys.put(old);
          retainedEvidence.add(old);
        } else {
          await store.activitys.delete(id);
        }
      }

      final weekStart = dateOnly(
        currentTime,
      ).subtract(Duration(days: currentTime.weekday - 1));
      final activities = <Activity>[...retainedEvidence];
      for (final block in proposal.blocks) {
        final firstDate = weekStart.add(Duration(days: block.weekday - 1));
        var start = DateTime(
          firstDate.year,
          firstDate.month,
          firstDate.day,
          block.startMinute ~/ 60,
          block.startMinute % 60,
        );
        if (start.isBefore(currentTime)) {
          start = start.add(const Duration(days: 7));
        }
        final segments = splitSpan(
          start,
          start.add(Duration(minutes: block.durationMinutes)),
        );
        String? groupId;
        for (final segment in segments) {
          final activity = Activity()
            ..habitId = habitId
            ..title = proposal.goal.title.trim()
            ..date = segment.date
            ..ampmHalf = segment.half
            ..startMinute = segment.start
            ..endMinute = segment.end
            ..colorValue = 0xffd8bd74
            ..description = proposal.goal.why?.trim() ?? ''
            ..recurrence = 'weekly'
            ..groupId = groupId
            ..createdAt = currentTime
            ..updatedAt = currentTime;
          activity.id = await store.activitys.put(activity);
          if (segments.length > 1 && groupId == null) {
            groupId = 'goal-plan-${activity.id}';
            activity.groupId = groupId;
            await store.activitys.put(activity);
          }
          activities.add(activity);
        }
      }
      final goalList = [...unpinnedGoals, goal];
      final receipts = [
        ...state.planReceipts,
        IntentPlanReceipt(
          operationId: operationId,
          fingerprint: fingerprint,
          goalId: newGoalId,
          habitId: habitId,
          activityIds: List.unmodifiable(activities.map((a) => a.id)),
        ),
      ];
      final updated = state.copyWith(
        revision: state.revision + 1,
        goals: goalList,
        sources: [
          ...state.sources.where((item) => item.id != source.id),
          source,
        ],
        links: [
          ...state.links.where((l) => l.sourceId != source.id),
          IntentLink(sourceId: source.id, goalId: newGoalId),
        ],
        planReceipts: receipts,
      );
      final payload = updated.encode();
      IntentState.decode(payload);
      await store.focusIntentDocuments.put(
        FocusIntentDocument()..payload = payload,
      );
      return GoalPlanApplyResult(
        goalId: newGoalId,
        habitId: habitId,
        activityIds: List.unmodifiable(activities.map((a) => a.id)),
      );
    });
  }

  void _checkStore() {
    if (!store.isDurable) {
      throw StateError('Penyimpanan tidak tersedia. Coba lagi.');
    }
  }

  void _checkTargetDate(PlanProposal proposal, DateTime current) {
    final value = proposal.goal.targetDate;
    if (value == null) return;
    final date = DateTime.parse(validLocalDate(value));
    final today = dateOnly(current);
    final limit = DateTime(today.year + 5, today.month, today.day);
    if (date.isBefore(today) || date.isAfter(limit)) {
      throw StateError(
        'Tanggal tujuan harus dari hari ini sampai lima tahun ke depan.',
      );
    }
  }

  List<String> _conflicts(
    PlanProposal proposal,
    List<Activity> existing,
    DateTime current, {
    Set<int> excludingActivityIds = const {},
  }) {
    final weekStart = dateOnly(
      current,
    ).subtract(Duration(days: current.weekday - 1));
    final planned =
        <({int weekday, AmPmHalf half, int start, int end, DateTime date})>[];
    for (final block in proposal.blocks) {
      final firstDate = weekStart.add(Duration(days: block.weekday - 1));
      var start = DateTime(
        firstDate.year,
        firstDate.month,
        firstDate.day,
        block.startMinute ~/ 60,
        block.startMinute % 60,
      );
      if (start.isBefore(current)) start = start.add(const Duration(days: 7));
      for (final segment in splitSpan(
        start,
        start.add(Duration(minutes: block.durationMinutes)),
      )) {
        planned.add((
          weekday: segment.date.weekday,
          half: segment.half,
          start: segment.start,
          end: segment.end,
          date: segment.date,
        ));
      }
    }
    final conflicts = <String>{};
    for (var i = 0; i < planned.length; i++) {
      final a = planned[i];
      for (var j = i + 1; j < planned.length; j++) {
        final b = planned[j];
        if (a.weekday == b.weekday &&
            a.half == b.half &&
            rangesOverlap(a.start, a.end, b.start, b.end)) {
          conflicts.add(
            'Blok rencana saling bertumpuk pada hari ${_weekday(a.weekday)}.',
          );
        }
      }
      for (final activity in existing) {
        if (excludingActivityIds.contains(activity.id)) continue;
        final sameDate = dateOnly(activity.date) == a.date;
        final recurringDay = _recursOn(activity, a.weekday);
        final excluded = activity.excludedDates.any(
          (d) => dateOnly(d) == a.date,
        );
        final futureOneOffOccurrence =
            activity.recurrence == 'none' &&
            activity.date.weekday == a.weekday &&
            !dateOnly(activity.date).isBefore(a.date) &&
            !excluded;
        if (((sameDate || recurringDay) && !excluded ||
                futureOneOffOccurrence) &&
            activity.ampmHalf == a.half &&
            rangesOverlap(
              activity.startMinute,
              activity.endMinute,
              a.start,
              a.end,
            )) {
          conflicts.add(
            'Bentrok ${_weekday(a.weekday)} ${_formatMinute(a.start)}–${_formatMinute(a.end)} dengan ${activity.title}.',
          );
        }
      }
    }
    return conflicts.toList();
  }

  bool _recursOn(Activity activity, int weekday) =>
      switch (activity.recurrence) {
        'daily' => true,
        'weekday' => weekday <= 5,
        'weekly' => activity.date.weekday == weekday,
        _ => false,
      };

  String _formatMinute(int minute) =>
      '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';
  String _weekday(int day) => const [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ][day - 1];
}

bool _same(List<int> a, List<int> b) =>
    a.length == b.length &&
    List.generate(a.length, (i) => a[i] == b[i]).every((v) => v);
