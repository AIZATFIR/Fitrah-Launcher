import 'dart:async';

import 'package:fitrah_launcher/features/launcher/models/launcher_settings.dart';
import 'package:fitrah_launcher/features/launcher/widgets/focus_clock_home_view.dart';
import 'package:fitrah_launcher/services/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class Storage extends SecureStorageService {
  String? raw;
  bool failRead = false;
  bool failWrite = false;
  Completer<void>? readGate;
  Completer<void>? writeGate;

  @override
  Future<String?> readCustomKey(String key) async {
    if (readGate != null) await readGate!.future;
    if (failRead) throw StateError('read');
    return raw;
  }

  @override
  Future<void> writeCustomKey(String key, String value) async {
    if (writeGate != null) await writeGate!.future;
    if (failWrite) throw StateError('write');
    raw = value;
  }
}

void main() {
  Future<void> showHome(
    WidgetTester tester,
    Storage storage,
    DateTime Function() now,
  ) async {
    tester.view.physicalSize = const Size(800, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [secureStorageServiceProvider.overrideWithValue(storage)],
        child: MaterialApp(
          home: FocusClockHomeView(
            onOpenFocusClock: () {},
            onOpenAppDrawer: () {},
            now: now,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final note = find.widgetWithText(
    TextField,
    'Tulis pemikiran, niat, atau catatan hari ini...',
  );
  testWidgets('recreated Home surfaces a failed previous-day draft', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var today = DateTime(2026, 11, 7);
    final storage = Storage()..failWrite = true;
    final container = ProviderContainer(
      overrides: [secureStorageServiceProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    Widget home(Key key) => UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: FocusClockHomeView(
          key: key,
          onOpenFocusClock: () {},
          onOpenAppDrawer: () {},
          now: () => today,
        ),
      ),
    );
    await tester.pumpWidget(home(const ValueKey('first')));
    await tester.pumpAndSettle();
    await tester.enterText(note, 'unresolved');
    await tester.pumpAndSettle();
    today = DateTime(2026, 11, 8);
    await tester.pumpWidget(home(const ValueKey('second')));
    await tester.pumpAndSettle();
    expect(find.text('unresolved'), findsOneWidget);
    expect(find.text('Gagal menyimpan'), findsOneWidget);
    storage.failWrite = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('unresolved'), findsNothing);
    expect(
      LauncherSettings.fromJson(storage.raw!).dailyNotes['2026-11-07'],
      'unresolved',
    );
  });

  testWidgets('recreated Home observes an in-flight save finish', (
    tester,
  ) async {
    final storage = Storage();
    final container = ProviderContainer(
      overrides: [secureStorageServiceProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    Widget home(Key key) => UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: FocusClockHomeView(
          key: key,
          onOpenFocusClock: () {},
          onOpenAppDrawer: () {},
          now: () => DateTime(2026, 11, 7),
        ),
      ),
    );
    await tester.pumpWidget(home(const ValueKey('first')));
    await tester.pumpAndSettle();
    storage.writeGate = Completer<void>();
    await tester.enterText(note, 'saving');
    await tester.pump();
    await tester.pumpWidget(home(const ValueKey('second')));
    await tester.pump();
    expect(find.text('saving'), findsOneWidget);
    expect(find.text('Menyimpan…'), findsOneWidget);
    expect(find.text('Gagal menyimpan'), findsNothing);
    storage.writeGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Tersimpan'), findsOneWidget);
    expect(find.text('saving'), findsOneWidget);
  });

  testWidgets('recreated Home shows the saved note', (tester) async {
    final storage = Storage();
    await showHome(tester, storage, () => DateTime(2026, 11, 7));
    await tester.enterText(note, 'saved across recreation');
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await showHome(tester, storage, () => DateTime(2026, 11, 7));
    expect(find.text('saved across recreation'), findsOneWidget);
  });

  testWidgets('editing waits for the initial saved note to load', (
    tester,
  ) async {
    final storage = Storage()
      ..raw = LauncherSettings(dailyNotes: {'2026-11-07': 'saved'}).toJson()
      ..readGate = Completer<void>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [secureStorageServiceProvider.overrideWithValue(storage)],
        child: MaterialApp(
          home: FocusClockHomeView(
            onOpenFocusClock: () {},
            onOpenAppDrawer: () {},
            now: () => DateTime(2026, 11, 7),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.widget<TextField>(note).enabled, isFalse);
    storage.readGate!.complete();
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(note).enabled, isTrue);
    expect(find.text('saved'), findsOneWidget);
  });

  testWidgets('load failure is visible and retry hydrates stored note', (
    tester,
  ) async {
    final storage = Storage()
      ..raw = LauncherSettings(dailyNotes: {'2026-11-07': 'saved'}).toJson()
      ..failRead = true;
    await showHome(tester, storage, () => DateTime(2026, 11, 7));
    expect(find.text('Gagal memuat'), findsOneWidget);
    storage.failRead = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('saved'), findsOneWidget);
    expect(find.text('Gagal memuat'), findsNothing);
  });

  testWidgets('write failure retains draft and retry saves it', (tester) async {
    final storage = Storage()..failWrite = true;
    await showHome(tester, storage, () => DateTime(2026, 11, 7));
    await tester.enterText(note, 'draft');
    await tester.pumpAndSettle();
    expect(find.text('Gagal menyimpan'), findsOneWidget);
    expect(find.text('draft'), findsOneWidget);
    storage.failWrite = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(
      LauncherSettings.fromJson(storage.raw!).dailyNotes['2026-11-07'],
      'draft',
    );
    expect(find.text('Tersimpan'), findsOneWidget);
  });

  testWidgets('failed old-day draft remains until saved before switching day', (
    tester,
  ) async {
    var today = DateTime(2026, 11, 7, 23, 59);
    final storage = Storage()..failWrite = true;
    await showHome(tester, storage, () => today);
    await tester.enterText(note, 'old day');
    await tester.pumpAndSettle();
    today = DateTime(2026, 11, 8);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('old day'), findsOneWidget);
    expect(find.text('Gagal menyimpan'), findsOneWidget);
    storage.failWrite = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('old day'), findsNothing);
    await tester.enterText(note, 'new day');
    await tester.pumpAndSettle();
    expect(LauncherSettings.fromJson(storage.raw!).dailyNotes, {
      '2026-11-07': 'old day',
      '2026-11-08': 'new day',
    });
  });
}
