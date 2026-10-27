import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitrah_launcher/features/launcher/widgets/focus_clock_home_view.dart';

void main() {
  group('FocusClockHomeView Lampiran 1 & Future Self Sadar System Tests', () {
    Widget createWidgetUnderTest() {
      return ProviderScope(
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

    testWidgets('Renders Left Rail buttons with notes count and status dots', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('Kemarin'), findsOneWidget);
      expect(find.text('Catatan'), findsOneWidget);
      expect(find.text('Penting'), findsOneWidget);
    });

    testWidgets('Renders Right Tools Rail with Ganti, Daftar, 24/12h, Cari, Timer', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('Ganti'), findsOneWidget);
      expect(find.text('Daftar'), findsOneWidget);
      expect(find.text('24 jam'), findsOneWidget);
      expect(find.text('Cari'), findsOneWidget);
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

      // Tap Daftar again to return to Dial
      await tester.tap(find.text('Daftar'));
      await tester.pumpAndSettle();
    });

    testWidgets('Renders Stacked Identity Cards with Presets and Habits', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
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
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Find first play arrow button in presets
      final playBtn = find.byKey(const ValueKey('preset_play_1'));
      await tester.tap(playBtn);
      await tester.pumpAndSettle();

      // Should be on Timer screen
      expect(find.text('Saat selesai, hasilnya dicatat otomatis ke jam.'), findsOneWidget);
      expect(find.text('Selesai sekarang'), findsOneWidget);
      expect(find.text('Batalkan timer'), findsOneWidget);

      // Finish now returns to Home
      await tester.tap(find.text('Selesai sekarang'));
      await tester.pumpAndSettle();

      expect(find.text('Identitas: Programmer'), findsOneWidget);
    });

    testWidgets('Renders Habits section with done toggle and 5-action popover', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

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
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Scroll down until the Add Identity button is visible in ListView
      for (int i = 0; i < 5; i++) {
        if (find.text('Tambah Blok Identitas Baru').evaluate().isNotEmpty) break;
        await tester.drag(find.byType(ListView).first, const Offset(0, -400));
        await tester.pumpAndSettle();
      }

      // Drag a bit more to clear bottom dock
      await tester.drag(find.byType(ListView).first, const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(find.text('Tambah Blok Identitas Baru'), findsOneWidget);
      await tester.tap(find.text('Tambah Blok Identitas Baru'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify bottom sheet for new identity is open
      expect(find.text('Identitas Baru'), findsOneWidget);
      expect(find.text('Buat Identitas'), findsOneWidget);

      // Enter identity name
      await tester.enterText(find.byType(TextField).first, 'Penulis');
      await tester.pumpAndSettle();

      // Tap create
      await tester.tap(find.text('Buat Identitas'));
      await tester.pumpAndSettle();

      // New identity card block should be rendered
      expect(find.text('Identitas: Penulis'), findsOneWidget);
    });

    testWidgets('Renders App Launcher dock, quick launcher bar, and schedules task dump to clock face', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool appDrawerOpened = false;
      bool focusClockOpened = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: FocusClockHomeView(
              onOpenFocusClock: () => focusClockOpened = true,
              onOpenAppDrawer: () => appDrawerOpened = true,
              useSampleData: true,
            ),
          ),
        ),
      );
      await tester.pump();

      // 1. Verify Floating Bottom Dock
      expect(find.text('Focus Clock'), findsWidgets);
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('App Launcher'), findsOneWidget);

      // Tap App Launcher in dock
      await tester.tap(find.text('App Launcher'));
      expect(appDrawerOpened, isTrue);

      // Tap Focus Clock in dock
      await tester.tap(find.text('Focus Clock').first);
      expect(focusClockOpened, isTrue);

      // 2. Verify Task Dump section
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

