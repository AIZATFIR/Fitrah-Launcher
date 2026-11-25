import 'package:fitrah_launcher/providers/intent_providers.dart';
import 'dart:async';

import 'package:fitrah_launcher/data/store/focus_store.dart';
import 'package:fitrah_launcher/features/launcher/widgets/focus_clock_home_view.dart';
import 'package:fitrah_launcher/models/activity.dart';
import 'package:fitrah_launcher/models/task.dart';
import 'package:fitrah_launcher/providers/providers.dart';
import 'package:fitrah_launcher/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> showHome(
    WidgetTester tester,
    _Store store, {
    Stream<List<Task>>? tasks,
    NotificationService? notifications,
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          focusStoreProvider.overrideWithValue(store),
          intentInitializationProvider.overrideWith((ref) async {}),
          if (tasks != null)
            eisenhowerTasksProvider.overrideWith((ref) => tasks),
          if (notifications != null)
            notificationServiceProvider.overrideWithValue(notifications),
        ],
        child: MaterialApp(
          home: FocusClockHomeView(
            onOpenFocusClock: () {},
            onOpenAppDrawer: () {},
            now: () => DateTime(2026, 11, 7, 10),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Catatan & alat'));
    await tester.tap(find.text('Catatan & alat'));
    await tester.pumpAndSettle();
  }

  testWidgets('creates persisted task and deletes the exact duplicate ID', (
    tester,
  ) async {
    final store = _Store();
    store.taskRows[1] = Task()
      ..id = 1
      ..title = 'Sama'
      ..createdAt = DateTime(2026);
    store.nextId = 2;
    await showHome(tester, store);
    await tester.tap(find.widgetWithText(TextButton, 'Tambah').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Sama');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Simpan'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(store.taskRows.keys, containsAll([1, 2]));
    expect(find.text('Sama'), findsNWidgets(2));
    final close = find.descendant(
      of: find.byType(IconButton),
      matching: find.byIcon(Icons.close_rounded),
    );
    await tester.tap(close.last);
    await tester.pumpAndSettle();
    expect(store.taskRows.keys, [2]);
    expect(find.text('Sama'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await showHome(tester, store);
    expect(find.text('Sama'), findsOneWidget);
  });

  testWidgets('loading and failure are visible', (tester) async {
    final store = _Store();
    final pending = StreamController<List<Task>>();
    addTearDown(pending.close);
    await showHome(tester, store, tasks: pending.stream);
    expect(find.text('Memuat tugas…'), findsOneWidget);
    pending.addError(StateError('failed'));
    await tester.pumpAndSettle();
    expect(find.text('Gagal memuat tugas. Coba lagi.'), findsOneWidget);
    expect(find.textContaining('Belum ada tugas di dump inbox'), findsNothing);
  });

  testWidgets('save locks dialog until write succeeds', (tester) async {
    final store = _Store()..gate = Completer<void>();
    await showHome(tester, store);
    await tester.tap(find.text('Tambah kegiatan').last);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(find.byType(TextField).last, 'Tertahan');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Simpan'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).last).enabled,
      isFalse,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Batal'))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Simpan'))
          .onPressed,
      isNull,
    );
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Tambah tindakan hari ini'), findsOneWidget);
    store.gate!.complete();
    await tester.pumpAndSettle();
    expect(store.taskRows.values.single.title, 'Tertahan');
    expect(find.text('Tambah tindakan hari ini'), findsNothing);
  });

  testWidgets('failed save retains input and enables retry', (tester) async {
    final store = _Store()..failTaskWrite = true;
    await showHome(tester, store);
    await tester.tap(find.text('Tambah kegiatan').last);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(find.byType(TextField).last, 'Coba lagi');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Simpan'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Gagal menyimpan. Coba lagi.'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller!.text,
      'Coba lagi',
    );
    expect(
      tester
          .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Simpan'))
          .onPressed,
      isNotNull,
    );
    store.failTaskWrite = false;
    await tester.tap(find.widgetWithText(ElevatedButton, 'Simpan'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(store.taskRows.values.single.title, 'Coba lagi');
  });

  testWidgets('notification failure after commit still reports success', (
    tester,
  ) async {
    final store = _Store();
    store.taskRows[1] = Task()
      ..id = 1
      ..title = 'Jadwalkan'
      ..createdAt = DateTime(2026);
    store.nextId = 2;
    await showHome(tester, store, notifications: _FailNotification());
    await tester.tap(find.text('Sekarang').first);
    await tester.pumpAndSettle();
    expect(store.taskRows[1]!.activityId, isNotNull);
    expect(store.activities, hasLength(1));
    expect(find.textContaining('dijadwalkan'), findsOneWidget);
  });
}

class _FailNotification extends NotificationService {
  @override
  Future<void> scheduleForActivity(Activity a, {int leadMinutes = 1}) async =>
      throw StateError('notification failed');
}

class _Store extends FocusStore {
  final taskRows = <int, Task>{};
  final activities = <int, Activity>{};
  final changes = StreamController<void>.broadcast();
  int nextId = 1;
  int nextActivity = 1;
  Completer<void>? gate;
  bool failTaskWrite = false;
  @override
  bool get isDurable => true;
  @override
  Future<List<T>> all<T>() async {
    if (T == Task) return taskRows.values.cast<T>().toList();
    if (T == Activity) return activities.values.cast<T>().toList();
    return [];
  }

  @override
  Future<T?> get<T>(int id) async {
    if (T == Task) return taskRows[id] as T?;
    if (T == Activity) return activities[id] as T?;
    return null;
  }

  @override
  Future<int> put<T>(T row) async {
    if (row is Task) {
      if (failTaskWrite) throw StateError('write failed');
      if (gate != null) await gate!.future;
      if (row.id <= 0 || row.id > 1000000) row.id = nextId++;
      taskRows[row.id] = row;
      changes.add(null);
      return row.id;
    }
    if (row is Activity) {
      if (row.id <= 0 || row.id > 1000000) row.id = nextActivity++;
      activities[row.id] = row;
      changes.add(null);
      return row.id;
    }
    return 0;
  }

  @override
  Future<bool> delete<T>(int id) async {
    final removed = taskRows.remove(id) != null;
    changes.add(null);
    return removed;
  }

  @override
  Future<void> clear() async {
    taskRows.clear();
    activities.clear();
  }

  @override
  Future<R> txn<R>(Future<R> Function() action) => action();
  @override
  Future<R> writeTxn<R>(Future<R> Function() action) => action();
  @override
  Stream<void> watch() async* {
    yield null;
    yield* changes.stream;
  }

  @override
  Future<void> close() => changes.close();
}
