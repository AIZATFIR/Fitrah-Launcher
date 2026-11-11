import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:fitrah_launcher/features/launcher/widgets/focus_clock_home_view.dart';
import 'package:fitrah_launcher/services/secure_storage_service.dart';
import 'dart:convert';

class _MemorySecureStorage extends SecureStorageService {
  final Map<String, String> values = {};

  @override
  Future<String?> readCustomKey(String key) async => values[key];

  @override
  Future<void> writeCustomKey(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> deleteCustomKey(String key) async {
    values.remove(key);
  }
}

void main() {
  test('Active timer preserves start date and elapsed time through restoration', () {
    final startedAt = DateTime(2026, 11, 11, 23, 59);
    final timer = ActiveTimer(
      label: 'Fokus malam',
      totalSeconds: 45 * 60,
      leftSeconds: 45 * 60,
      isRunning: true,
      startHour: 23.0,
      hasStarted: true,
      sessionStartedAt: startedAt,
      runningSince: startedAt,
    );

    final restored = ActiveTimer.fromJson(
      jsonDecode(jsonEncode(timer.toJson())) as Map<String, dynamic>,
    );

    expect(restored.sessionStartedAt, startedAt);
    expect(restored.entryDateString(DateTime(2026, 11, 12)), '2026-11-11');
    expect(restored.elapsedSecondsAt(startedAt.add(const Duration(minutes: 2))), 120);
    expect(restored.remainingAt(startedAt.add(const Duration(minutes: 2))), 45 * 60 - 120);
  });

  group('FocusClockHomeView Lampiran 1 & Future Self Sadar System Tests', () {
    Widget createWidgetUnderTest({SecureStorageService? storage}) {
      return ProviderScope(
        overrides: [
          if (storage != null) secureStorageServiceProvider.overrideWithValue(storage),
        ],
        child: MaterialApp(
          home: FocusClockHomeView(
            onOpenFocusClock: () {},
            onOpenAppDrawer: () {},
            useSampleData: true,
          ),
        ),
      );
    }

    testWidgets('Renders top agenda carousel by default and toggles Prayer schedule', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Top bar toggle button starts on schedule_rounded (agenda mode)
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);

      // Tap toggle button to switch to prayer schedule
      await tester.tap(find.byIcon(Icons.schedule_rounded));
      await tester.pumpAndSettle();

      // Now prayer times are visible
      expect(find.text('Subuh'), findsOneWidget);
      expect(find.text('Dzuhur'), findsOneWidget);
      expect(find.text('Asar'), findsOneWidget);
      expect(find.text('Maghrib'), findsOneWidget);
      expect(find.text('Isya'), findsOneWidget);

      // Tap again to switch back
      await tester.tap(find.byIcon(Icons.mosque_rounded));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
    });

    testWidgets('Renders Obsidian Daily Note Card with scratchpad', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('DAILY NOTE'), findsOneWidget);
      expect(find.text('Tulis pemikiran, niat, atau catatan hari ini...'), findsOneWidget);
    });

    testWidgets('Renders Clock Dial Controls with AM/PM switcher, Cari, Daftar, Timer', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('AM'), findsOneWidget);
      expect(find.text('PM'), findsOneWidget);
      expect(find.text('Cari'), findsOneWidget);
      expect(find.text('Daftar'), findsOneWidget);
      expect(find.text('Timer'), findsOneWidget);
    });

    testWidgets('Toggles chronological list view and circular clock face dial', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Tap Daftar
      await tester.tap(find.text('Daftar'));
      await tester.pumpAndSettle();

      // In list view, SE - Orkestrasi AI should be listed
      expect(find.text('SE - Orkestrasi AI'), findsWidgets);

      // Tap Ke Jam to return to Dial
      await tester.tap(find.text('Ke Jam'));
      await tester.pumpAndSettle();
    });

    testWidgets('Renders Stacked Identity Cards with Presets and Habits', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('Identitas: Programmer'), findsOneWidget);
      expect(find.text('Preset Blok Waktu'), findsWidgets);
      expect(find.text('Kebiasaan & Rutinitas'), findsWidgets);
      expect(find.text('SE - Orkestrasi AI'), findsWidgets);
      expect(find.text('LKS ITSSB'), findsOneWidget);
    });

    testWidgets('Starting preset timer transitions to Timer screen', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Find first play arrow button in presets
      final playBtn = find.byKey(const ValueKey('preset_play_1'));
      await tester.scrollUntilVisible(playBtn, 300, scrollable: find.byType(Scrollable).first);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -100));
      await tester.pumpAndSettle();
      await tester.tap(playBtn);
      await tester.pumpAndSettle();

      // Should be on Timer screen
      expect(find.text('Saat selesai, hasilnya dicatat otomatis ke jam.'), findsOneWidget);
      expect(find.text('Selesai sekarang'), findsOneWidget);
      expect(find.text('Batalkan timer'), findsOneWidget);

      // Finish now returns to Home
      await tester.tap(find.text('Selesai sekarang'));
      await tester.pumpAndSettle();

      final identitasText = find.text('Identitas: Programmer');
      await tester.scrollUntilVisible(identitasText, -300, scrollable: find.byType(Scrollable).first);
      expect(identitasText, findsOneWidget);
    });

    testWidgets('Restored timer accounts for elapsed wall-clock time', (tester) async {
      final storage = _MemorySecureStorage();
      final now = DateTime.now();
      storage.values['focus_clock_active_timer_v1'] = jsonEncode({
        'label': 'LKS ITSSB',
        'totalSeconds': 2700,
        'elapsedBeforeRun': 0,
        'isRunning': true,
        'runningSince': now.subtract(const Duration(minutes: 4)).toIso8601String(),
        'source': 'preset',
        'sourceId': 2,
        'identity': 'Programmer',
        'startHour': 8.0,
        'hasStarted': true,
      });
      const channel = MethodChannel('fitrah_launcher/apps');
      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (_) async => null);
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      await tester.pumpWidget(createWidgetUnderTest(storage: storage));
      await tester.pump();

      expect(find.text('Saat selesai, hasilnya dicatat otomatis ke jam.'), findsOneWidget);
      expect(find.text('43:59'), findsOneWidget);
    });

    testWidgets('Renders Habits section with done toggle and 5-action popover', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      for (int i = 0; i < 6; i++) {
        if (find.text('Deep Coding & Refactoring 30m').evaluate().isNotEmpty) break;
        await tester.drag(find.byType(ListView).first, const Offset(0, -400));
        await tester.pumpAndSettle();
      }

      expect(find.text('Deep Coding & Refactoring 30m'), findsOneWidget);

      // Tap habit title to open the 5-action popover
      await tester.tap(find.text('Deep Coding & Refactoring 30m'));
      await tester.pumpAndSettle();

      // Verify the 5 actions from Lampiran 1
      expect(find.text('Ya'), findsOneWidget);
      expect(find.text('Tidak'), findsOneWidget);
      expect(find.text('Mulai'), findsOneWidget);
      expect(find.text('Catatan'), findsWidgets);
      expect(find.text('Gambar'), findsOneWidget);
    });

    testWidgets('Navigating to Jelas screen displays 3 emotions and 3 gratitude journal items', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Open menu
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      // Tap Jelas
      await tester.tap(find.text('Jelas: visual dan syukur'));
      await tester.pumpAndSettle();

      // Verify Jelas screen content
      expect(find.text('Jelas'), findsOneWidget);
      expect(find.text('Mulai visualisasi 3 menit'), findsOneWidget);
      expect(find.text('3 emosi utama'), findsOneWidget);

      // Scroll down to see gratitude section
      await tester.drag(find.byType(ListView).first, const Offset(0, -350));
      await tester.pumpAndSettle();

      expect(find.text('Jurnal syukur, 3 hal'), findsOneWidget);
      expect(find.text('Simpan syukur ke catatan'), findsOneWidget);
    });

    testWidgets('Adds a new Identity block dynamically via Tambah Blok Identitas Baru', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final addIdentityBtn = find.text('Tambah Blok Identitas Baru');
      await tester.scrollUntilVisible(addIdentityBtn, 400, scrollable: find.byType(Scrollable).first);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
      await tester.pumpAndSettle();
      await tester.tap(addIdentityBtn);
      await tester.pumpAndSettle();

      // Verify bottom sheet for new identity is open
      expect(find.text('Identitas Baru'), findsOneWidget);
      expect(find.text('Buat Identitas'), findsOneWidget);

      // Enter identity name
      await tester.enterText(find.byKey(const ValueKey('new_identity_name_field')), 'Penulis');
      await tester.pumpAndSettle();

      // Tap create
      await tester.tap(find.text('Buat Identitas'));
      await tester.pumpAndSettle();

      // Scroll up to locate the updated preset section
      for (int i = 0; i < 8; i++) {
        if (find.text('Identitas: Penulis').evaluate().isNotEmpty) break;
        await tester.drag(find.byType(ListView).first, const Offset(0, 300), warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      // New identity card block should be rendered
      expect(find.text('Identitas: Penulis'), findsOneWidget);
    });

    testWidgets('Clean minimalist interface without bottom dock, and schedules task dump to clock face', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // 1. Verify Floating Bottom Dock is removed for clean minimalist experience
      expect(find.text('Beranda'), findsNothing);

      // 2. Scroll to Task Dump section
      for (int i = 0; i < 6; i++) {
        if (find.text('Task & Habit Dump (Inbox)').evaluate().isNotEmpty) break;
        await tester.drag(find.byType(ListView).first, const Offset(0, -400));
        await tester.pumpAndSettle();
      }

      // 3. Verify Task Dump section
      expect(find.text('Task & Habit Dump (Inbox)'), findsOneWidget);
      expect(find.text('Selesaikan modul UI Focus Clock'), findsOneWidget);
      expect(find.text('Sekarang'), findsWidgets);

      // 4. Tap "Pasang" on a dumped task
      final pasangBtn = find.text('Pasang').first;
      await tester.tap(pasangBtn);
      await tester.pumpAndSettle();

      // Verify Interactive Scheduling Sheet is open
      expect(find.text('Pasang ke Focus Clock'), findsWidgets);
      expect(find.byType(RangeSlider), findsOneWidget);
    });
  });
}
