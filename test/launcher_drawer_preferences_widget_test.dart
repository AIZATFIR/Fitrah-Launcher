import 'package:fitrah_launcher/features/launcher/widgets/fitrah_settings_screen.dart';
import 'package:fitrah_launcher/features/launcher/widgets/launcher_customization_sheet.dart';
import 'package:fitrah_launcher/features/launcher/widgets/niagara_unified_stream_view.dart';
import 'package:fitrah_launcher/providers/sadar_providers.dart';
import 'package:fitrah_launcher/providers/providers.dart';
import 'package:fitrah_launcher/features/launcher/widgets/drawer_preferences_controls.dart';
import 'package:fitrah_launcher/features/launcher/widgets/app_icon_widget.dart';
import 'package:fitrah_launcher/core/theme.dart';
import 'package:fitrah_launcher/features/launcher/providers/launcher_settings_provider.dart';
import 'package:fitrah_launcher/features/launcher/widgets/app_preferences_sheet.dart';
import 'dart:async';
import 'package:fitrah_launcher/features/launcher/models/launcher_settings.dart';
import 'package:fitrah_launcher/features/launcher/services/app_launcher_service.dart';
import 'package:fitrah_launcher/features/launcher/widgets/minimalist_app_drawer.dart';
import 'package:fitrah_launcher/features/launcher/widgets/niagara_wave_scrubber.dart';
import 'package:fitrah_launcher/services/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'launcher_daily_note_widget_test.dart' show Storage;

const alpha = InstalledApp(appName: 'Alpha', packageName: 'org.alpha');
const beta = InstalledApp(appName: 'Beta', packageName: 'org.beta');

class RecordingLauncher extends AppLauncherService {
  final launched = <String>[];
  final details = <String>[];
  @override
  Future<bool> launchApp(String packageName) async {
    launched.add(packageName);
    return true;
  }

  @override
  Future<bool> openAppDetails(String packageName) async {
    details.add(packageName);
    return true;
  }
}

void main() {
  Future<ProviderContainer> show(
    WidgetTester tester,
    Storage storage, {
    List<InstalledApp> apps = const [alpha, beta],
    double scale = 1,
    bool active = false,
    Widget? home,
    void Function(String)? onIcon,
    AppLauncherService? launcher,
  }) async {
    final container = ProviderContainer(
      overrides: [
        secureStorageServiceProvider.overrideWithValue(storage),
        if (launcher != null)
          appLauncherServiceProvider.overrideWithValue(launcher),
        habitsStreamProvider.overrideWith((ref) => Stream.value([])),
        habitEntriesStreamProvider.overrideWith(
          (ref, range) => Stream.value([]),
        ),
        eisenhowerTasksProvider.overrideWith((ref) => Stream.value([])),
        installedAppsFutureProvider.overrideWith((ref) async => apps),
        appIconProvider.overrideWith((ref, package) async {
          onIcon?.call(package);
          return null;
        }),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData.dark().copyWith(
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            ),
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: home ?? MinimalistAppDrawer(isActive: active),
        ),
      ),
    );
    await tester.pump();
    return container;
  }

  testWidgets('icon-free rows still launch apps and expose app details', (
    tester,
  ) async {
    final launcher = RecordingLauncher();
    final store = Storage()
      ..raw = LauncherSettings(showAppIcons: false).toJson();
    await show(tester, store, launcher: launcher);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beta'));
    await tester.pumpAndSettle();
    expect(launcher.launched, ['org.beta']);
    await tester.longPress(find.text('Beta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Info aplikasi'));
    await tester.pumpAndSettle();
    expect(launcher.details, ['org.beta']);
    expect(find.byType(AppPreferencesSheet), findsNothing);
  });

  testWidgets('app options use localized Bookpaper action labels', (
    tester,
  ) async {
    await show(tester, Storage());
    await tester.pumpAndSettle();
    await tester.longPress(find.text('Beta'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<BottomSheet>(find.byType(BottomSheet)).backgroundColor,
      AppPalette.bg,
    );
    expect(find.text('Tambah ke Favorit'), findsOneWidget);
    expect(find.text('Sembunyikan Aplikasi'), findsOneWidget);
    expect(find.text('Info aplikasi'), findsOneWidget);
    expect(find.text('Hapus aplikasi'), findsOneWidget);
    expect(find.text('App info'), findsNothing);
    for (final label in [
      'Tambah ke Favorit',
      'Sembunyikan Aplikasi',
      'Info aplikasi',
      'Hapus aplikasi',
    ]) {
      expect(
        tester.getSize(find.widgetWithText(ListTile, label)).height,
        greaterThanOrEqualTo(48),
      );
    }
  });

  testWidgets(
    'icons hidden in favorite, normal and search rows never request icons',
    (tester) async {
      final requests = <String>[];
      final store = Storage()
        ..raw = LauncherSettings(
          showAppIcons: false,
          favoritePackages: {'org.alpha'},
        ).toJson();
      final container = await show(tester, store, onIcon: requests.add);
      await tester.pumpAndSettle();
      expect(find.byType(AppIconWidget), findsNothing);
      expect(requests, isEmpty);
      final row = find
          .ancestor(of: find.text('Beta'), matching: find.byType(InkWell))
          .first;
      expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(AppIconWidget), findsNothing);
      expect(requests, isEmpty);
      await container
          .read(launcherSettingsProvider.notifier)
          .setShowAppIcons(true);
      await tester.pumpAndSettle();
      expect(find.byType(AppIconWidget), findsWidgets);
      expect(requests, contains('org.alpha'));
    },
  );

  testWidgets(
    'shared controls gate hydration, keep failed requested value and retry at large text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final store = Storage()..readGate = Completer<void>();
      await show(
        tester,
        store,
        scale: 2,
        home: const Scaffold(
          body: SingleChildScrollView(child: DrawerPreferencesControls()),
        ),
      );
      expect(find.byType(SwitchListTile), findsNothing);
      store.failRead = true;
      store.readGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Gagal memuat preferensi.'), findsOneWidget);
      store.failRead = false;
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      store.failWrite = true;
      await tester.tap(find.text('Tampilkan ikon aplikasi'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SwitchListTile>(
              find.widgetWithText(SwitchListTile, 'Tampilkan ikon aplikasi'),
            )
            .value,
        isTrue,
      );
      expect(
        find.textContaining('Gagal menyimpan preferensi.'),
        findsOneWidget,
      );
      store.failWrite = false;
      store.writeGate = Completer<void>();
      await tester.ensureVisible(find.text('Coba lagi'));
      await tester.tap(find.text('Coba lagi'));
      await tester.pump();
      expect(find.text('Menyimpan…'), findsOneWidget);
      for (final tile in tester.widgetList<SwitchListTile>(
        find.byType(SwitchListTile),
      )) {
        expect(tile.onChanged, isNull);
      }
      store.writeGate!.complete();
      await tester.pumpAndSettle();
      expect(LauncherSettings.fromJson(store.raw!).showAppIcons, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('active drawer opens search after delayed hydration', (
    tester,
  ) async {
    final store = Storage()
      ..raw = LauncherSettings(autoFocusSearch: true).toJson()
      ..readGate = Completer<void>();
    await show(tester, store, active: true);
    expect(find.byType(TextField), findsNothing);
    store.readGate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
      isTrue,
    );
  });

  testWidgets(
    'inactive or disposed drawer does not steal focus after hydration',
    (tester) async {
      final store = Storage()
        ..raw = LauncherSettings(autoFocusSearch: true).toJson()
        ..readGate = Completer<void>();
      final container = await show(tester, store, active: true);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: MinimalistAppDrawer(isActive: false)),
        ),
      );
      store.readGate!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('settings and App Drawer sheet share committed values', (
    tester,
  ) async {
    final store = Storage();
    final container = await show(
      tester,
      store,
      home: const FitrahSettingsScreen(),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tampilkan ikon aplikasi'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Daftar aplikasi'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Daftar aplikasi'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Geser layar utama ke kiri'), findsOneWidget);
    final tiles = tester.widgetList<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Tampilkan ikon aplikasi'),
    );
    expect(tiles.every((tile) => !tile.value), isTrue);
    await tester.tap(find.text('Tampilkan ikon aplikasi').last);
    await tester.pumpAndSettle();
    expect(container.read(launcherSettingsProvider).showAppIcons, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home display mode selection reflects its committed value', (
    tester,
  ) async {
    final store = Storage()
      ..raw = LauncherSettings(widgetDisplayMode: 'focus_clock').toJson();
    final container = await show(
      tester,
      store,
      home: const FitrahSettingsScreen(),
    );
    await tester.scrollUntilVisible(
      find.text('Layar utama'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Layar utama'));
    await tester.pumpAndSettle();

    final prayerOption = find
        .ancestor(
          of: find.text('Waktu Sholat'),
          matching: find.byType(Container),
        )
        .first;
    BoxDecoration optionDecoration() =>
        tester.widget<Container>(prayerOption).decoration! as BoxDecoration;
    expect(optionDecoration().border!.top.color, Colors.white24);

    await tester.tap(find.text('Waktu Sholat'));
    await tester.pumpAndSettle();

    expect(
      container.read(launcherSettingsProvider).widgetDisplayMode,
      'prayer',
    );
    expect(LauncherSettings.fromJson(store.raw!).widgetDisplayMode, 'prayer');
    expect(optionDecoration().border!.top.color, Colors.white);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings labels match available behavior and licenses open', (
    tester,
  ) async {
    await show(tester, Storage(), home: const FitrahSettingsScreen());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Beri ulasan di Play Store'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Use device wallpaper ★'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Lainnya'),
      -250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Lainnya'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Credits & Open Source Licenses'));
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('palette save failure stays open and never reports success', (
    tester,
  ) async {
    await show(
      tester,
      Storage()..failWrite = true,
      home: const FitrahSettingsScreen(),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Tema dan warna aksen'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Tema dan warna aksen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sky Blue (Fokus & Jernih)'));
    await tester.pumpAndSettle();

    expect(find.text('Pilih Tema & Warna Aksen'), findsOneWidget);
    expect(find.text('Tema belum tersimpan. Coba lagi.'), findsOneWidget);
  });

  testWidgets('customization drawer controls scroll at 320dp and 200 percent', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await show(
      tester,
      Storage(),
      scale: 2,
      home: const Scaffold(body: LauncherCustomizationSheet()),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Tampilkan ikon aplikasi'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester
          .getSize(
            find.widgetWithText(SwitchListTile, 'Tampilkan ikon aplikasi'),
          )
          .height,
      greaterThanOrEqualTo(48),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('legacy icon rows and keyboard wait for hydrated preferences', (
    tester,
  ) async {
    final requests = <String>[];
    final store = Storage()
      ..raw = LauncherSettings(
        showAppIcons: false,
        autoFocusSearch: true,
        favoritePackages: {'org.alpha'},
      ).toJson()
      ..readGate = Completer<void>();
    await show(
      tester,
      store,
      onIcon: requests.add,
      home: NiagaraUnifiedStreamView(onOpenFocusClock: () {}),
    );
    expect(find.text('Alpha'), findsNothing);
    expect(find.text('Memuat preferensi…'), findsOneWidget);
    store.readGate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(AppIconWidget), findsNothing);
    expect(requests, isEmpty);
    final field = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == 'Cari aplikasi...',
    );
    expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);
    await tester.enterText(field, 'Alpha');
    await tester.pumpAndSettle();
    expect(find.byType(AppIconWidget), findsNothing);
    expect(requests, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'preference off cancels pending automatic focus and disposal is safe',
    (tester) async {
      final store = Storage()
        ..raw = LauncherSettings(autoFocusSearch: true).toJson()
        ..readGate = Completer<void>();
      final container = await show(tester, store, active: true);
      final off = container
          .read(launcherSettingsProvider.notifier)
          .setAutoFocusSearch(false);
      store.readGate!.complete();
      await off;
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('disposing before hydration completes never schedules focus', (
    tester,
  ) async {
    final store = Storage()
      ..raw = LauncherSettings(autoFocusSearch: true).toJson()
      ..readGate = Completer<void>();
    await show(tester, store, active: true);
    await tester.pumpWidget(const SizedBox());
    store.readGate!.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'saved hidden apps never flash during pending or failed hydration',
    (tester) async {
      final store = Storage()
        ..raw = LauncherSettings(hiddenPackages: {'org.alpha'}).toJson()
        ..readGate = Completer<void>();
      await show(tester, store);
      expect(find.text('Alpha'), findsNothing);
      expect(find.text('Memuat preferensi…'), findsOneWidget);
      expect(find.textContaining(RegExp(r'^\d{2}:\d{2}$')), findsOneWidget);
      expect(
        find.textContaining(
          RegExp(r'^(Senin|Selasa|Rabu|Kamis|Jumat|Sabtu|Minggu), '),
        ),
        findsOneWidget,
      );
      expect(find.text('Pengaturan Launcher'), findsOneWidget);
      store.failRead = true;
      store.readGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Alpha'), findsNothing);
      expect(find.text('Gagal memuat preferensi.'), findsOneWidget);
      expect(find.textContaining(RegExp(r'^\d{2}:\d{2}$')), findsOneWidget);
      expect(
        find.textContaining(
          RegExp(r'^(Senin|Selasa|Rabu|Kamis|Jumat|Sabtu|Minggu), '),
        ),
        findsOneWidget,
      );
      expect(find.text('Pengaturan Launcher'), findsOneWidget);
      store.failRead = false;
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(find.text('Alpha'), findsNothing);
      expect(find.text('Beta'), findsOneWidget);
    },
  );

  testWidgets('hide favorite, unique search, all hidden manager and restore', (
    tester,
  ) async {
    final store = Storage()
      ..raw = LauncherSettings(
        favoritePackages: {'org.alpha'},
        hiddenPackages: {'org.beta'},
      ).toJson();
    await show(tester, store, apps: [alpha, alpha, beta]);
    await tester.pumpAndSettle();
    expect(find.text('Favorit'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'alpha');
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsNothing);
    await tester.longPress(find.text('Alpha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sembunyikan Aplikasi'));
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsNothing);
    expect(
      find.text('Tidak ada aplikasi yang cocok dengan pencarian.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Aplikasi tersembunyi'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<BottomSheet>(find.byType(BottomSheet)).backgroundColor,
      AppPalette.bg,
    );
    await tester.tap(find.text('Tampilkan Alpha'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('Aplikasi tersembunyi').last)).pop();
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsOneWidget);
    expect(LauncherSettings.fromJson(store.raw!).favoritePackages, {
      'org.alpha',
    });
  });

  testWidgets(
    'app save stays open on failure, retries, prevents conflicting pending writes',
    (tester) async {
      final store = Storage()
        ..raw = LauncherSettings(favoritePackages: {}).toJson()
        ..failWrite = true;
      await show(tester, store);
      await tester.pumpAndSettle();
      await tester.longPress(find.text('Alpha'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tambah ke Favorit'));
      await tester.pumpAndSettle();
      expect(find.text('Gagal menyimpan preferensi.'), findsOneWidget);
      expect(find.text('Tambah ke Favorit'), findsOneWidget);
      store.failWrite = false;
      store.writeGate = Completer<void>();
      await tester.tap(find.text('Coba lagi'));
      await tester.pump();
      expect(find.text('Menyimpan…'), findsOneWidget);
      final hideTile = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Sembunyikan Aplikasi'),
      );
      expect(hideTile.enabled, isFalse);
      expect(LauncherSettings.fromJson(store.raw!).favoritePackages, isEmpty);
      store.writeGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Tambah ke Favorit'), findsNothing);
      expect(LauncherSettings.fromJson(store.raw!).favoritePackages, {
        'org.alpha',
      });
    },
  );

  testWidgets(
    'all hidden restore errors and pending controls fit 320dp at 200 percent',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final store = Storage()
        ..raw = LauncherSettings(
          favoritePackages: {},
          hiddenPackages: {'org.alpha', 'org.beta', 'org.unavailable.app'},
        ).toJson()
        ..failWrite = true;
      await show(tester, store, scale: 2);
      await tester.pumpAndSettle();
      expect(find.text('Semua aplikasi disembunyikan.'), findsOneWidget);
      await tester.tap(find.text('Aplikasi tersembunyi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tampilkan Alpha'));
      await tester.pumpAndSettle();
      expect(find.text('Gagal menyimpan preferensi.'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Coba lagi'),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      expect(
        tester.getSize(find.widgetWithText(TextButton, 'Coba lagi')).height,
        greaterThanOrEqualTo(48),
      );
      store.failWrite = false;
      store.writeGate = Completer<void>();
      await tester.tap(find.text('Coba lagi'));
      await tester.pump();
      final buttons = find.descendant(
        of: find.byType(HiddenAppsSheet),
        matching: find.byType(TextButton),
      );
      expect(buttons, findsWidgets);
      for (final element in buttons.evaluate()) {
        expect((element.widget as TextButton).onPressed, isNull);
      }
      store.writeGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Tampilkan Alpha'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'large text app options wrap long names and expose 48dp actions',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const app = InstalledApp(
        appName: 'An exceptionally long application title with several words',
        packageName: 'org.long.application',
      );
      await show(tester, Storage(), apps: [app], scale: 2);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(app.appName));
      await tester.pumpAndSettle();
      await tester.longPressAt(
        tester.getTopLeft(find.text(app.appName)) + const Offset(10, 20),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Tambah ke Favorit'),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      final favorite = find.widgetWithText(ListTile, 'Tambah ke Favorit');
      expect(tester.getSize(favorite).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'letter seek reaches offscreen real header after favorites and variable rows',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final apps = [
        for (var i = 0; i < 35; i++)
          InstalledApp(
            appName: 'A long application title taking several lines $i',
            packageName: 'org.app$i',
          ),
        const InstalledApp(appName: 'Zebra', packageName: 'org.zebra'),
      ];
      final store = Storage()
        ..raw = LauncherSettings(
          favoritePackages: {'org.app0'},
          hiddenPackages: {'org.app1'},
        ).toJson();
      await show(tester, store, apps: apps, scale: 2);
      await tester.pumpAndSettle();
      tester
          .widget<NiagaraWaveScrubber>(find.byType(NiagaraWaveScrubber))
          .onLetterSelected('Z');
      await tester.pumpAndSettle();
      expect(find.text('Zebra').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('durable hide undo reports failed save and retries honestly', (
    tester,
  ) async {
    final store = Storage()
      ..raw = LauncherSettings(favoritePackages: {}).toJson();
    await show(tester, store);
    await tester.pumpAndSettle();
    await tester.longPress(find.text('Alpha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sembunyikan Aplikasi'));
    await tester.pumpAndSettle();
    expect(LauncherSettings.fromJson(store.raw!).hiddenPackages, {'org.alpha'});
    store.failWrite = true;
    await tester.tap(find.text('URUNGKAN'));
    await tester.pumpAndSettle();
    expect(find.text('Gagal menyimpan preferensi.'), findsOneWidget);
    expect(find.text('Alpha'), findsNothing);
    store.failWrite = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsOneWidget);
    expect(LauncherSettings.fromJson(store.raw!).hiddenPackages, isEmpty);
  });

  testWidgets(
    'unavailable hidden package stays manageable without installed list',
    (tester) async {
      final store = Storage()
        ..raw = LauncherSettings(
          hiddenPackages: {'org.unavailable.app'},
        ).toJson();
      await show(tester, store, apps: []);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aplikasi tersembunyi'));
      await tester.pumpAndSettle();
      expect(
        find.text('Saat ini tidak terpasang atau tidak tersedia'),
        findsOneWidget,
      );
      await tester.tap(find.text('Tampilkan org.unavailable.app'));
      await tester.pumpAndSettle();
      expect(find.text('Tidak ada aplikasi tersembunyi.'), findsOneWidget);
      expect(LauncherSettings.fromJson(store.raw!).hiddenPackages, isEmpty);
    },
  );

  testWidgets(
    'nonalphabetic groups stay unique and newer navigation cancels seeking',
    (tester) async {
      final apps = [
        const InstalledApp(appName: '1 App', packageName: 'org.number'),
        const InstalledApp(appName: '日本語', packageName: 'org.japanese'),
        for (var i = 0; i < 30; i++)
          InstalledApp(appName: 'App $i', packageName: 'org.app$i'),
        const InstalledApp(appName: 'Zebra', packageName: 'org.zebra'),
      ];
      await show(tester, Storage(), apps: apps);
      await tester.pumpAndSettle();
      final scrubber = tester.widget<NiagaraWaveScrubber>(
        find.byType(NiagaraWaveScrubber),
      );
      scrubber.onLetterSelected('Z');
      scrubber.onLetterSelected('A');
      await tester.pumpAndSettle();
      expect(find.text('A').hitTestable(), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
