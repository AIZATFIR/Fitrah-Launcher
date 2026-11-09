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

void main() {
  Future<ProviderContainer> show(
    WidgetTester tester,
    Storage storage, {
    List<InstalledApp> apps = const [alpha, beta],
    double scale = 1,
  }) async {
    final container = ProviderContainer(
      overrides: [
        secureStorageServiceProvider.overrideWithValue(storage),
        installedAppsFutureProvider.overrideWith((ref) async => apps),
        appIconProvider.overrideWith((ref, package) async => null),
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
          home: const MinimalistAppDrawer(),
        ),
      ),
    );
    await tester.pump();
    return container;
  }

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
        find.textContaining(RegExp(r'^(Mon|Tue|Wed|Thu|Fri|Sat|Sun), ')),
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
        find.textContaining(RegExp(r'^(Mon|Tue|Wed|Thu|Fri|Sat|Sun), ')),
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
    expect(find.text('Alpha'), findsNWidgets(2));
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
