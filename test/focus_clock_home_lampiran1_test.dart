import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitrah_launcher/features/launcher/widgets/focus_clock_home_view.dart';
import 'package:fitrah_launcher/features/launcher/widgets/launcher_customization_sheet.dart';
import 'package:fitrah_launcher/features/launcher/models/launcher_settings.dart';
import 'package:fitrah_launcher/features/settings/settings_screen.dart';
import 'package:fitrah_launcher/providers/providers.dart';
import 'package:fitrah_launcher/providers/sadar_providers.dart';
import 'package:fitrah_launcher/data/repositories/sadar_repository.dart';
import 'package:fitrah_launcher/domain/focus_intent.dart';
import 'package:fitrah_launcher/providers/intent_providers.dart';
import 'package:fitrah_launcher/models/timer_session.dart';
import 'package:fitrah_launcher/services/secure_storage_service.dart';
import 'launcher_daily_note_test.dart' show NoteStorage;

void main() {
  group('FocusClockHomeView Lampiran 1 & Future Self Sadar System Tests', () {
    Finder homeScrollable() => find
        .descendant(
          of: find.byKey(const ValueKey('focus-clock-home-list')),
          matching: find.byType(Scrollable),
        )
        .first;

    Future<void> expandSupportTools(WidgetTester tester) async {
      final tile = find.text('Catatan & alat');
      await tester.scrollUntilVisible(tile, 300, scrollable: homeScrollable());
      await tester.tap(tile);
      await tester.pumpAndSettle();
    }

    Widget createWidgetUnderTest({
      bool useSampleData = true,
      bool emptyTasks = false,
      double textScale = 1,
      bool showUnverifiedPrayerSchedule = false,
      SadarRepository? sadarRepository,
    }) {
      final storage = NoteStorage()
        ..raw = LauncherSettings(
          widgetDisplayMode: showUnverifiedPrayerSchedule
              ? 'prayer'
              : 'focus_clock',
          showPrayerTimes: true,
        ).toJson();
      return ProviderScope(
        overrides: [
          secureStorageServiceProvider.overrideWithValue(storage),
          if (emptyTasks)
            eisenhowerTasksProvider.overrideWith(
              (ref) => Stream.value(const []),
            ),
          if (emptyTasks)
            intentStateProvider.overrideWith(
              (ref) => Stream.value(
                IntentState(sourceStoreId: 'test-store', legacyImported: true),
              ),
            ),
          if (emptyTasks)
            intentSourceDataProvider.overrideWith(
              (ref) => Stream.value(const IntentSourceData([], [], [])),
            ),
          if (sadarRepository != null)
            sadarRepoProvider.overrideWithValue(sadarRepository),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: FocusClockHomeView(
            onOpenFocusClock: () {},
            onOpenAppDrawer: () {},
            useSampleData: useSampleData,
          ),
        ),
      );
    }

    testWidgets(
      'Renders top agenda carousel by default and toggles Prayer schedule',
      (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        expect(
          find.byKey(const ValueKey('home-agenda-carousel')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('home-menu-button')), findsOneWidget);

        // Prayer display is an explicit menu preference, not a header icon toggle.
        await tester.tap(find.byKey(const ValueKey('home-menu-button')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tampilkan waktu salat'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('home-prayer-setup-cue')),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const ValueKey('home-menu-button')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tampilkan agenda Focus Clock'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('home-agenda-carousel')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'unverified default prayer times open setup without showing a clock time',
      (tester) async {
        await tester.pumpWidget(
          createWidgetUnderTest(showUnverifiedPrayerSchedule: true),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('home-prayer-setup-cue')),
          findsOneWidget,
        );
        expect(find.text('11:52'), findsNothing);

        await tester.tap(find.byKey(const ValueKey('home-prayer-setup-cue')));
        await tester.pumpAndSettle();
        expect(find.byType(LauncherCustomizationSheet), findsOneWidget);
        expect(
          find.text(
            'Nilai awal hanya contoh, bukan hasil lokasi otomatis. Cocokkan dengan sumber waktu di wilayahmu:',
          ),
          findsOneWidget,
        );
        final verifiedSwitch = find.widgetWithText(
          SwitchListTile,
          'Saya sudah mencocokkan semua waktu ini',
        );
        await tester.ensureVisible(verifiedSwitch);
        await tester.pumpAndSettle();
        await tester.tap(verifiedSwitch);
        await tester.pumpAndSettle();
        expect(tester.widget<SwitchListTile>(verifiedSwitch).value, isTrue);
        Navigator.of(tester.element(verifiedSwitch)).pop();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('home-prayer-setup-cue')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('home-prayer-schedule-cue')),
          findsOneWidget,
        );
      },
    );

    testWidgets('Focus Clock menu exposes settings route', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('home-menu-button')));
      await tester.pumpAndSettle();

      expect(find.text('Pengaturan Focus Clock'), findsOneWidget);
    });

    testWidgets('SettingsScreen shows backup controls', (tester) async {
      tester.view.physicalSize = const Size(800, 6000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: SettingsScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text('BACKUP & RESTORE'), findsOneWidget);
      expect(find.text('Export backup'), findsOneWidget);
      expect(find.text('Restore backup'), findsOneWidget);
    });

    testWidgets('AI setup opens at the provider controls on a phone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: SettingsScreen(focusAiConfiguration: true)),
        ),
      );
      await tester.pumpAndSettle();

      final config = find.byKey(const ValueKey('ai-provider-settings'));
      final providerLabel = find.text('Provider');
      expect(config, findsOneWidget);
      expect(providerLabel, findsOneWidget);
      expect(tester.getRect(providerLabel).top, greaterThan(56));
      expect(tester.getRect(providerLabel).bottom, lessThan(844));
    });

    testWidgets('Renders today note card with scratchpad', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await expandSupportTools(tester);

      final homeList = find.byType(ListView).first;
      await tester.scrollUntilVisible(
        find.text('Catatan hari ini'),
        300,
        scrollable: find
            .descendant(of: homeList, matching: find.byType(Scrollable))
            .first,
      );
      expect(find.text('Catatan hari ini'), findsOneWidget);
      expect(
        find.text('Tulis pemikiran, niat, atau catatan hari ini...'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Renders Clock Dial Controls with AM/PM switcher, Cari, Daftar, Timer',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        expect(
          find.byKey(const ValueKey('home-agenda-carousel')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('home-menu-button')));
        await tester.pumpAndSettle();
        expect(find.text('Cari jadwal'), findsOneWidget);
        expect(find.text('Lihat daftar jadwal'), findsOneWidget);
        await tester.tapAt(const Offset(4, 4));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('home-open-focus-timer')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('home-open-focus-timer')));
        await tester.pumpAndSettle();
        expect(find.text('Pusat Timer Fokus'), findsOneWidget);
      },
    );

    testWidgets('Keeps clock controls visible without overflow on a phone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(
        find.byKey(const ValueKey('home-agenda-carousel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('home-open-focus-timer')),
        findsOneWidget,
      );
      await expandSupportTools(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Home Hijri date wraps at 200% text scale', (tester) async {
      tester.view.physicalSize = const Size(360, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest(textScale: 2));
      await tester.pump();

      final hijriDate = find.textContaining('Hijriah ·');
      expect(hijriDate, findsOneWidget);
      final goalHeading = find.text('TUJUAN HARI INI');
      expect(goalHeading, findsOneWidget);
      expect(
        tester.getTopLeft(goalHeading).dy,
        lessThan(tester.getTopLeft(hijriDate).dy),
      );
      final dateParagraph = tester.renderObject<RenderParagraph>(hijriDate);
      expect(dateParagraph.size.height, greaterThan(30));
      expect(dateParagraph.didExceedMaxLines, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Toggles chronological list view and circular clock face dial',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        await tester.tap(find.byKey(const ValueKey('home-menu-button')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lihat daftar jadwal'));
        await tester.pumpAndSettle();

        // In list view, SE - Orkestrasi AI should be listed
        expect(find.text('SE - Orkestrasi AI'), findsWidgets);

        // Tap Ke Jam to return to Dial
        await tester.tap(find.text('Ke Jam'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets('Renders Stacked Identity Cards with Presets and Habits', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await expandSupportTools(tester);

      expect(find.text('Identitas: Programmer'), findsOneWidget);
      expect(find.text('Preset Blok Waktu'), findsWidgets);
      expect(find.text('Kebiasaan & Rutinitas'), findsWidgets);
      expect(find.text('SE - Orkestrasi AI'), findsWidgets);
      expect(find.text('LKS ITSSB'), findsOneWidget);
    });

    testWidgets(
      'Starting preset timer stays open when completion cannot be stored',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();
        await expandSupportTools(tester);

        // Find first play arrow button in presets
        final playBtn = find.byKey(const ValueKey('preset_play_1'));
        final homeList = find.byType(ListView).first;
        final homeScrollable = find
            .descendant(of: homeList, matching: find.byType(Scrollable))
            .first;
        await tester.scrollUntilVisible(
          playBtn,
          300,
          scrollable: homeScrollable,
        );
        await tester.drag(homeList, const Offset(0, -100));
        await tester.pumpAndSettle();
        await tester.tap(playBtn);
        await tester.pumpAndSettle();

        // Should be on Timer screen
        expect(
          find.text('Saat selesai, hasilnya dicatat otomatis ke jam.'),
          findsOneWidget,
        );
        expect(find.text('Selesai sekarang'), findsOneWidget);
        expect(find.text('Batalkan timer'), findsOneWidget);

        // Empty test storage cannot commit this preset; keep it available to retry.
        await tester.tap(find.text('Selesai sekarang'));
        await tester.pumpAndSettle();

        expect(find.text('Selesai sekarang'), findsOneWidget);
        expect(find.text('Batalkan timer'), findsOneWidget);
      },
    );

    testWidgets(
      'Renders Habits section with done toggle and 5-action popover',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();
        await expandSupportTools(tester);

        for (int i = 0; i < 6; i++) {
          if (find
              .text('Deep Coding & Refactoring 30m')
              .evaluate()
              .isNotEmpty) {
            break;
          }
          await tester.drag(find.byType(ListView).first, const Offset(0, -400));
          await tester.pumpAndSettle();
        }

        expect(find.text('Deep Coding & Refactoring 30m'), findsOneWidget);

        // Tap habit title to open the 5-action popover
        await tester.ensureVisible(find.text('Deep Coding & Refactoring 30m'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Deep Coding & Refactoring 30m'));
        await tester.pumpAndSettle();

        // Verify the 5 actions from Lampiran 1
        expect(find.text('Ya'), findsOneWidget);
        expect(find.text('Tidak'), findsOneWidget);
        expect(find.text('Mulai'), findsOneWidget);
        expect(find.text('Catatan'), findsWidgets);
        expect(find.text('Gambar'), findsOneWidget);
      },
    );

    testWidgets(
      'Navigating to Jelas screen displays 3 emotions and 3 gratitude journal items',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        // Open menu
        await tester.tap(find.byKey(const ValueKey('home-menu-button')));
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
      },
    );

    testWidgets('Adds a new Identity block dynamically via Tambah identitas', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('home-menu-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tambah Identitas Baru'));
      await tester.pumpAndSettle();

      // Verify bottom sheet for new identity is open
      expect(find.text('Identitas Baru'), findsOneWidget);
      expect(find.text('Buat Identitas'), findsOneWidget);

      // Enter identity name
      await tester.enterText(
        find.byKey(const ValueKey('new_identity_name_field')),
        'Penulis',
      );
      await tester.pumpAndSettle();

      // Tap create
      await tester.tap(find.text('Buat Identitas'));
      await tester.pumpAndSettle();
      await expandSupportTools(tester);

      // New identity card block should be rendered
      expect(find.text('Identitas: Penulis'), findsOneWidget);
    });

    testWidgets(
      'late preview defaults to tomorrow and retains unsupported task',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: FocusClockHomeView(
                onOpenFocusClock: () {},
                onOpenAppDrawer: () {},
                useSampleData: true,
                now: () => DateTime(2026, 11, 7, 23, 59, 30),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await expandSupportTools(tester);
        for (
          var i = 0;
          i < 6 && find.text('Task & Habit Dump (Inbox)').evaluate().isEmpty;
          i++
        ) {
          await tester.drag(find.byType(ListView).first, const Offset(0, -400));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('Pasang').first);
        await tester.pumpAndSettle();
        expect(find.byType(RangeSlider), findsNothing);
        expect(find.text('Besok 00:00'), findsWidgets);
        await tester.ensureVisible(
          find.widgetWithText(ElevatedButton, 'Pasang ke Focus Clock'),
        );
        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Pasang ke Focus Clock'),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Pratinjau belum mendukung jadwal melewati tengah malam.'),
          findsOneWidget,
        );
        expect(find.text('Selesaikan modul UI Focus Clock'), findsWidgets);
      },
    );

    testWidgets(
      'Clean minimalist interface without bottom dock, and schedules task dump to clock face',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();
        await expandSupportTools(tester);

        // 1. Verify Floating Bottom Dock is removed for clean minimalist experience
        expect(find.text('Beranda'), findsNothing);

        // 2. Scroll to Task Dump section
        for (int i = 0; i < 6; i++) {
          if (find.text('Kotak masuk kegiatan').evaluate().isNotEmpty) {
            break;
          }
          await tester.drag(find.byType(ListView).first, const Offset(0, -400));
          await tester.pumpAndSettle();
        }

        // 3. Verify Task Dump section
        expect(find.text('Kotak masuk kegiatan'), findsOneWidget);
        expect(find.text('Selesaikan modul UI Focus Clock'), findsOneWidget);
        expect(find.text('Sekarang'), findsWidgets);

        // 4. Tap "Pasang" on a dumped task
        final pasangBtn = find.text('Pasang').first;
        await tester.tap(pasangBtn);
        await tester.pumpAndSettle();

        // Verify Interactive Scheduling Sheet is open
        expect(find.text('Pasang ke Focus Clock'), findsWidgets);
        expect(find.byType(RangeSlider), findsNothing);
        expect(find.text('Selesaikan modul UI Focus Clock'), findsWidgets);
      },
    );

    testWidgets('quick add opens as a calm, text-first inbox capture', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();
      await expandSupportTools(tester);
      for (var i = 0; i < 6; i++) {
        if (find.text('Kotak masuk kegiatan').evaluate().isNotEmpty) break;
        await tester.drag(find.byType(ListView).first, const Offset(0, -400));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.text('Tambah').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tambah').first);
      await tester.pumpAndSettle();

      expect(find.text('Catat Cepat ke Dump Inbox'), findsOneWidget);
      expect(find.text('Pilih yang Ada'), findsNothing);
      expect(find.text('Pilih Identitas:'), findsNothing);
      expect(tester.takeException(), isNull);

      final captureField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Nama kegiatan / habit / tugas...',
      );
      await tester.enterText(captureField, 'Latihan LKS');
      expect(
        tester.widget<TextField>(captureField).controller?.text,
        'Latihan LKS',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'empty production capture hides empty source and identity choices',
      (tester) async {
        tester.view.physicalSize = const Size(320, 760);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final emptyRepository = SadarRepository.store(null);
        for (final habit in await emptyRepository.getHabits()) {
          await emptyRepository.deleteHabit(habit.id);
        }
        await tester.pumpWidget(
          createWidgetUnderTest(
            useSampleData: false,
            emptyTasks: true,
            sadarRepository: emptyRepository,
          ),
        );
        await tester.pumpAndSettle();
        final addActivity = find.text('Tambah kegiatan');
        await tester.ensureVisible(addActivity);
        await tester.pumpAndSettle();
        await tester.tap(addActivity);
        await tester.pumpAndSettle();

        expect(find.text('Pilih yang Ada'), findsNothing);
        expect(find.text('Pilih Identitas:'), findsNothing);
        expect(find.text('Catat Cepat ke Dump Inbox'), findsOneWidget);
        expect(find.text('Pilih yang Ada'), findsNothing);
        expect(find.text('Pilih Identitas:'), findsNothing);
      },
    );

    testWidgets('timer hub focuses on an existing paused session', (
      tester,
    ) async {
      final repository = SadarRepository(null);
      final now = DateTime.now();
      await repository.saveTimerSession(
        TimerSession()
          ..habitName = 'Latihan LKS'
          ..sourceKind = TimerSessionSourceKind.free
          ..targetSeconds = 900
          ..accumulatedDurationSeconds = 120
          ..startedAt = now.subtract(const Duration(minutes: 2))
          ..pausedAt = now
          ..status = TimerStateStatus.paused
          ..updatedAt = now,
      );
      await tester.pumpWidget(
        createWidgetUnderTest(sadarRepository: repository),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('home-open-focus-timer')));
      await tester.pumpAndSettle();

      expect(find.text('Sesi dijeda'), findsOneWidget);
      expect(find.text('Latihan LKS').last, findsOneWidget);
      expect(find.text('Fokus Bebas Cepat:'), findsNothing);
      expect(find.text('Buka sesi'), findsOneWidget);

      await tester.tap(find.text('Buka sesi'));
      await tester.pumpAndSettle();
      expect(find.text('Latihan LKS'), findsOneWidget);
    });
  });
}
