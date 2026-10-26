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
          ),
        ),
      );
    }

    testWidgets('Renders all Top Prayer timeline items and next countdown', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('Subuh'), findsOneWidget);
      expect(find.text('Dzuhur'), findsOneWidget);
      expect(find.text('Asar'), findsOneWidget);
      expect(find.text('Maghrib'), findsOneWidget);
      expect(find.text('Isya'), findsOneWidget);

      expect(find.textContaining('Berikutnya:'), findsOneWidget);
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
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

    testWidgets('Renders Preset Blok Waktu section with identity tags and add button', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('Preset blok waktu'), findsOneWidget);
      expect(find.textContaining('Identitas: Programmer'), findsOneWidget);
      expect(find.text('SE - Orkestrasi AI'), findsWidgets);
      expect(find.text('LKS ITSSB'), findsOneWidget);
    });

    testWidgets('Starting preset timer transitions to Timer screen', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Find first play arrow button in presets
      final playBtn = find.byIcon(Icons.play_arrow_rounded).first;
      await tester.tap(playBtn);
      await tester.pumpAndSettle();

      // Should be on Timer screen
      expect(find.text('Saat selesai, hasilnya dicatat otomatis ke jam.'), findsOneWidget);
      expect(find.text('Selesai sekarang'), findsOneWidget);
      expect(find.text('Batalkan timer'), findsOneWidget);

      // Finish now returns to Home
      await tester.tap(find.text('Selesai sekarang'));
      await tester.pumpAndSettle();

      expect(find.text('Preset blok waktu'), findsOneWidget);
    });

    testWidgets('Renders Habits section with done toggle and 5-action popover', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Scroll down so habits section and its action buttons are fully visible
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.text('Kebiasaan'), findsOneWidget);
      expect(find.text('Selalu bersikap baik'), findsOneWidget);

      // Tap action button (+) on habit
      final addIcon = find.byIcon(Icons.add).last;
      await tester.tap(addIcon);
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
  });
}
