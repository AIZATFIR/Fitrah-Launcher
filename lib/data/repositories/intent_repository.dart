import 'package:uuid/uuid.dart';
import '../../domain/focus_intent.dart';
import '../../models/focus_intent_document.dart';
import '../../models/habit.dart';
import '../../models/task.dart';
import '../store/focus_store.dart';

class IntentConflict implements Exception {
  const IntentConflict();
  @override
  String toString() =>
      'Data berubah. Tutup dan buka editor lagi untuk memakai versi terbaru.';
}

/// Reads the latest singleton inside each transaction, including across owners.
class IntentRepository {
  IntentRepository(this.store, {DateTime Function()? now})
    : now = now ?? DateTime.now;
  final FocusStore? store;
  final DateTime Function() now;
  static String newId() => const Uuid().v4();
  FocusStore get _db {
    final db = store;
    if (db == null || !db.isDurable) {
      throw StateError('Penyimpanan tidak tersedia. Coba lagi.');
    }
    return db;
  }

  Future<IntentState> read() async {
    final db = _db;
    return db.writeTxn(() async {
      final document = await _latest(db);
      if (document != null) return _decode(document);
      final state = IntentState(sourceStoreId: newId());
      await _put(db, state);
      return state;
    });
  }

  Future<FocusIntentDocument?> _latest(FocusStore db) async {
    final rows = await db.all<FocusIntentDocument>();
    if (rows.length > 1 || rows.any((r) => r.id != 1)) {
      throw const FormatException('Invalid intent singleton');
    }
    return rows.firstOrNull;
  }

  IntentState _decode(FocusIntentDocument row) {
    if (row.id != 1) throw const FormatException('Invalid intent singleton');
    return IntentState.decode(row.payload);
  }

  Future<void> _put(FocusStore db, IntentState state) async {
    final payload = state.encode();
    IntentState.decode(payload);
    await db.put(FocusIntentDocument()..payload = payload);
  }

  Stream<IntentState> watch() async* {
    yield await read();
    await for (final _ in _db.watch()) {
      yield await read();
    }
  }

  Future<IntentState> _change(
    Future<IntentState> Function(IntentState) update,
  ) => _db.writeTxn(() async {
    final row = await _latest(_db);
    final current = row == null
        ? IntentState(sourceStoreId: newId())
        : _decode(row);
    final changed = await update(current);
    final result = changed.copyWith(revision: current.revision + 1);
    await _put(_db, result);
    return result;
  });
  Future<IntentState> importLegacy(String title) => _change((state) async {
    if (state.legacyImported) return state;
    final clean = title.trim();
    if (clean.isEmpty) return state.copyWith(legacyImported: true);
    final goal = IntentGoal(
      id: newId(),
      title: clean,
      pinned: state.pinnedGoal == null,
    );
    return state.copyWith(
      legacyImported: true,
      legacyMappings: [
        ...state.legacyMappings,
        IntentLegacyMapping(
          sourceStoreId: state.sourceStoreId,
          entityType: 'goal',
          legacyId: 'focusGoal',
          stableId: goal.id,
        ),
      ],
      goals: [...state.goals, goal],
    );
  });
  Future<IntentState> saveGoal({
    required String id,
    required String title,
    int? expectedRevision,
    bool? pinned,
    bool? archived,
  }) => _change((state) async {
    final existing = state.goals.where((g) => g.id == id).firstOrNull;
    if (existing != null && expectedRevision != existing.revision) {
      throw const IntentConflict();
    }
    if (existing == null && expectedRevision != null) {
      throw const IntentConflict();
    }
    final goal = IntentGoal(
      id: id,
      title: title.trim(),
      pinned: (archived ?? existing?.archived ?? false)
          ? false
          : (pinned ?? existing?.pinned ?? false),
      archived: archived ?? existing?.archived ?? false,
      revision: (existing?.revision ?? 0) + 1,
    );
    final goals =
        state.goals
            .where((g) => g.id != id)
            .map(
              (g) => goal.pinned && g.pinned
                  ? IntentGoal(
                      id: g.id,
                      title: g.title,
                      archived: g.archived,
                      revision: g.revision + 1,
                    )
                  : g,
            )
            .toList()
          ..add(goal);
    return state.copyWith(goals: goals);
  });
  Future<void> _validateSource(IntentSource source, IntentState state) async {
    if (source.sourceStoreId != state.sourceStoreId) {
      throw StateError(
        'Sumber berasal dari penyimpanan lain dan tidak tersedia.',
      );
    }
    if (source.type == IntentSourceType.habit) {
      final habit = await _db.get<Habit>(source.legacyId);
      if (habit == null || habit.isArchived) {
        throw StateError('Habit tidak tersedia atau sudah diarsipkan.');
      }
    } else {
      final task = await _db.get<Task>(source.legacyId);
      if (task == null || task.isCompleted) {
        throw StateError('Tugas tidak tersedia atau sudah selesai.');
      }
    }
  }

  Future<IntentState> choose({
    required String localDate,
    IntentSourceType? type,
    int? legacyId,
    String? goalId,
    int? expectedRevision,
  }) => _change((state) async {
    validLocalDate(localDate);
    // Historical selection is retained for display; Home commands use today's clock.
    if (localDate != intentLocalDate(now())) {
      throw StateError('Pilihan hanya dapat diubah untuk hari ini.');
    }
    final old = state.selectionFor(localDate);
    if ((old?.revision ?? 0) != (expectedRevision ?? 0)) {
      throw const IntentConflict();
    }
    if ((type == null) != (legacyId == null)) {
      throw ArgumentError('Incomplete source');
    }
    var sources = state.sources;
    var links = state.links;
    IntentSource? source;
    if (type != null) {
      source =
          sources
              .where(
                (s) =>
                    s.sourceStoreId == state.sourceStoreId &&
                    s.type == type &&
                    s.legacyId == legacyId,
              )
              .firstOrNull ??
          IntentSource(
            id: newId(),
            sourceStoreId: state.sourceStoreId,
            type: type,
            legacyId: legacyId!,
          );
      await _validateSource(source, state);
      if (!sources.any((s) => s.id == source!.id)) {
        sources = [...sources, source];
      }
      if (goalId != null) {
        if (!state.goals.any((g) => g.id == goalId && !g.archived)) {
          throw StateError('Tujuan tidak tersedia.');
        }
        links = [
          ...links.where((l) => l.sourceId != source!.id),
          IntentLink(sourceId: source.id, goalId: goalId),
        ];
      } else {
        links = links.where((l) => l.sourceId != source!.id).toList();
      }
    }
    final selection = TodaySelection(
      localDate: localDate,
      sourceId: source?.id,
      chosenAtUtc: now().toUtc(),
      revision: (old?.revision ?? 0) + 1,
    );
    return state.copyWith(
      sources: sources,
      links: links,
      selections: [
        ...state.selections.where((s) => s.localDate != localDate),
        selection,
      ],
    );
  });
}
