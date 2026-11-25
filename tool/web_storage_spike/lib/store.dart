import 'package:drift/drift.dart';

part 'store.g.dart';

class Activities extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get localDate => text()();
  TextColumn get status => text()();
  IntColumn get actualSeconds => integer()();
  @override
  Set<Column> get primaryKey => {id};
}

class Habits extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  @override
  Set<Column> get primaryKey => {id};
}

class Entries extends Table {
  TextColumn get sessionId => text()();
  TextColumn get habitId => text().references(Habits, #id)();
  TextColumn get localDate => text()();
  IntColumn get actualSeconds => integer()();
  @override
  Set<Column> get primaryKey => {sessionId};
}

class Settings extends Table {
  IntColumn get id => integer().check(id.equals(0))();
  TextColumn get goal => text()();
  TextColumn get credential => text()();
  @override
  Set<Column> get primaryKey => {id};
}

class Sessions extends Table {
  IntColumn get id => integer().check(id.equals(1))();
  TextColumn get sessionId => text().unique()();
  TextColumn get activityId => text().references(Activities, #id)();
  TextColumn get habitId => text().references(Habits, #id)();
  TextColumn get localDate => text()();
  TextColumn get status => text()();
  IntColumn get actualSeconds => integer()();
  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Activities, Habits, Entries, Settings, Sessions])
class SpikeStore extends _$SpikeStore {
  SpikeStore(super.connection);
  @override
  int get schemaVersion => 1;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );

  Future<void> seed() => transaction(() async {
    await into(
      habits,
    ).insert(HabitsCompanion.insert(id: 'habit-41', title: 'Read'));
    await into(settings).insert(
      SettingsCompanion.insert(
        id: const Value(0),
        goal: 'Baca 20 halaman — tujuan 🌱',
        credential: 'SYNTHETIC-NON-SECRET',
      ),
    );
  });

  Future<void> start(String sessionId) => transaction(() async {
    await into(activities).insert(
      ActivitiesCompanion.insert(
        id: 'activity-$sessionId',
        title: 'Synthetic reading',
        localDate: '2026-11-06',
        status: 'active',
        actualSeconds: 67,
      ),
    );
    await into(sessions).insert(
      SessionsCompanion.insert(
        id: const Value(1),
        sessionId: sessionId,
        activityId: 'activity-$sessionId',
        habitId: 'habit-41',
        localDate: '2026-11-06',
        status: 'running',
        actualSeconds: 67,
      ),
    );
  });

  Future<void> complete({bool injectFailure = false}) => transaction(() async {
    final session = await select(sessions).getSingleOrNull();
    if (session == null) return;
    await (update(activities)..where((a) => a.id.equals(session.activityId)))
        .write(const ActivitiesCompanion(status: Value('completed')));
    await into(entries).insert(
      EntriesCompanion.insert(
        sessionId: session.sessionId,
        habitId: session.habitId,
        localDate: session.localDate,
        actualSeconds: session.actualSeconds,
      ),
    );
    if (injectFailure) throw StateError('Injected completion failure');
    await delete(sessions).go();
  });

  Selectable<QueryRow> snapshotQuery() => customSelect(
    '''
    SELECT (SELECT count(*) FROM activities) AS activities,
      (SELECT count(*) FROM activities WHERE status = 'completed') AS completed,
      (SELECT count(*) FROM entries) AS entries,
      (SELECT count(*) FROM sessions) AS sessions
  ''',
    readsFrom: {activities, entries, sessions},
  );

  Future<Map<String, dynamic>> snapshot() async =>
      (await snapshotQuery().getSingle()).data;
}
