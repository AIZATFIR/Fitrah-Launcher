import 'dart:ui' show SemanticsAction, SemanticsFlag;

import 'launcher_daily_note_test.dart' show NoteStorage;
import 'package:fitrah_launcher/services/secure_storage_service.dart';
import 'package:fitrah_launcher/core/time_math.dart';
import 'package:fitrah_launcher/providers/providers.dart';
import 'package:fitrah_launcher/providers/intent_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitrah_launcher/features/launcher/fitrah_launcher_shell.dart';
import 'package:fitrah_launcher/features/launcher/models/launcher_settings.dart';
import 'package:fitrah_launcher/features/launcher/providers/launcher_settings_provider.dart';
import 'package:fitrah_launcher/features/launcher/services/app_launcher_service.dart';
import 'package:fitrah_launcher/features/launcher/widgets/fitrah_home_view.dart';
import 'package:fitrah_launcher/features/launcher/widgets/minimalist_app_drawer.dart';
import 'package:fitrah_launcher/features/launcher/widgets/focus_clock_home_view.dart';
import 'package:fitrah_launcher/features/launcher/widgets/niagara_wave_scrubber.dart';
import 'package:fitrah_launcher/data/repositories/sadar_repository.dart';
import 'package:fitrah_launcher/models/habit.dart';
import 'package:fitrah_launcher/providers/sadar_providers.dart';

void main() {
  group('Fitrah Launcher Tests', () {
    test('InstalledApp model firstLetter calculation and copyWith', () {
      const app1 = InstalledApp(
        appName: 'Browser',
        packageName: 'com.android.browser',
      );
      expect(app1.firstLetter, 'B');

      const app2 = InstalledApp(
        appName: '1Password',
        packageName: 'com.onepassword',
      );
      expect(app2.firstLetter, '#');

      final updated = app1.copyWith(isFavorite: true);
      expect(updated.isFavorite, true);
      expect(updated.appName, 'Browser');
    });

    testWidgets('FitrahHomeView renders clock header and agenda sections', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: FitrahHomeView(
              onOpenFocusClock: () {},
              onOpenAppDrawer: () {},
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Fajr'), findsNothing);
      expect(find.text('Dhuhr'), findsNothing);
      expect(find.text('Belum Ada Event Focus Clock'), findsOneWidget);
    });

    testWidgets('MinimalistAppDrawer renders search bar and app list', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureStorageServiceProvider.overrideWithValue(NoteStorage()),
            installedAppsFutureProvider.overrideWith(
              (_) async => const [
                InstalledApp(appName: 'Test App', packageName: 'test.app'),
              ],
            ),
          ],
          child: const MaterialApp(home: MinimalistAppDrawer()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(NiagaraWaveScrubber), findsOneWidget);
      expect(find.text('Test App'), findsOneWidget);
      final searchFab = find.byIcon(Icons.search_rounded);
      expect(searchFab, findsOneWidget);
      await tester.tap(searchFab);
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Cari aplikasi'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Test');
      await tester.pump();
      expect(find.text('Test App'), findsOneWidget);
    });

    testWidgets('FitrahLauncherShell initial page is center Home', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: FitrahLauncherShell())),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(FocusClockHomeView), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('Hari Ini'), findsOneWidget);
      expect(find.text('Jam'), findsOneWidget);
      expect(find.text('Habit'), findsOneWidget);
      expect(find.text('Aplikasi'), findsOneWidget);
      await tester.drag(
        find.byKey(const ValueKey('focus-clock-home-list')),
        const Offset(0, -1400),
      );
      await tester.pumpAndSettle();
      expect(find.text('Semua'), findsWidgets);
      final semuaButton = find.widgetWithText(TextButton, 'Semua');
      expect(tester.widget<TextButton>(semuaButton).onPressed, isNotNull);
      await tester.drag(
        find.byKey(const ValueKey('focus-clock-home-list')),
        const Offset(0, 450),
      );
      await tester.pumpAndSettle();
      await tester.tap(semuaButton);
      await tester.pumpAndSettle();
      expect(
        tester.widget<PageView>(find.byType(PageView)).controller!.page,
        2,
      );
      await tester.tap(find.text('Hari Ini'));
      await tester.pumpAndSettle();
      final shellScaffold = tester.widget<Scaffold>(
        find
            .descendant(
              of: find.byType(FitrahLauncherShell),
              matching: find.byType(Scaffold),
            )
            .first,
      );
      expect(shellScaffold.bottomNavigationBar, isA<NavigationBar>());
      await tester.tap(find.text('Jam'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<PageView>(find.byType(PageView)).controller!.page,
        0,
      );
      await tester.tap(find.text('Hari Ini'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<PageView>(find.byType(PageView)).controller!.page,
        1,
      );
      await tester.tap(find.text('Habit'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<PageView>(find.byType(PageView)).controller!.page,
        2,
      );
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        2,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        tester.widget<PageView>(find.byType(PageView)).controller!.page,
        1,
      );
      await tester.tap(find.text('Aplikasi'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<PageView>(find.byType(PageView)).controller!.page,
        3,
      );
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        3,
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FitrahLauncherShell)),
      );
      final actual = container.read(intentNowProvider);
      final pageView = tester.widget<PageView>(find.byType(PageView));
      pageView.onPageChanged!(0);
      container.read(currentDateProvider.notifier).state = DateTime(2030, 1, 1);
      container.read(ampmHalfProvider.notifier).state = AmPmHalf.pm;
      pageView.onPageChanged!(1);
      expect(container.read(currentDateProvider), dateOnly(actual));
      expect(container.read(ampmHalfProvider), halfOfNow(actual));
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('active launcher shell applies the saved wallpaper preset', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureStorageServiceProvider.overrideWithValue(NoteStorage()),
          ],
          child: const MaterialApp(home: FitrahLauncherShell()),
        ),
      );
      await tester.pump();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FitrahLauncherShell)),
      );
      await container
          .read(launcherSettingsProvider.notifier)
          .setWallpaperType('forest_night');
      await tester.pump();

      expect(
        tester
            .widget<ColoredBox>(
              find.byKey(const ValueKey('launcher-wallpaper-base')),
            )
            .color,
        const Color(0xFF0A150E),
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Home uses saved Focus Clock mode and widget visibility', (
      tester,
    ) async {
      final storage = NoteStorage()
        ..raw = LauncherSettings(widgetDisplayMode: 'focus_clock').toJson();
      final container = ProviderContainer(
        overrides: [secureStorageServiceProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: FocusClockHomeView(
              onOpenFocusClock: () {},
              onOpenAppDrawer: () {},
              useSampleData: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
      expect(find.text('Subuh'), findsNothing);
      expect(find.byKey(const ValueKey('home-date-hijri')), findsOneWidget);
      // The compact Home uses its inline "SEKARANG" cue instead of the
      // expanded dial's separate current-event badge.
      expect(find.byKey(const ValueKey('home-current-event')), findsNothing);
      expect(container.read(launcherSettingsProvider).showHabitsWidget, isTrue);
      expect(
        find.byKey(const ValueKey('home-agenda-carousel')),
        findsOneWidget,
      );
      final homeList = find.byType(ListView).first;
      final homeScrollable = find
          .descendant(of: homeList, matching: find.byType(Scrollable))
          .first;
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('home-habit-grid')),
        300,
        scrollable: homeScrollable,
      );
      expect(find.byKey(const ValueKey('home-habit-grid')), findsOneWidget);
      await container
          .read(launcherSettingsProvider.notifier)
          .setWidgetDisplayMode('prayer');
      await tester.pumpAndSettle();
      await tester.drag(homeList, const Offset(0, 1400));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('home-prayer-setup-cue')),
        findsOneWidget,
      );
      expect(
        LauncherSettings.fromJson(storage.raw!).widgetDisplayMode,
        'prayer',
      );

      await container
          .read(launcherSettingsProvider.notifier)
          .togglePrayerTimes(false);
      await container
          .read(launcherSettingsProvider.notifier)
          .setWidgetDisplayMode('focus_clock');
      await tester.pumpAndSettle();
      expect(find.text('Subuh'), findsNothing);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('home-habit-grid')),
        300,
        scrollable: homeScrollable,
      );
      expect(find.byKey(const ValueKey('home-habit-grid')), findsOneWidget);
      final notifier = container.read(launcherSettingsProvider.notifier);
      await notifier.toggleWidget(
        showHero: false,
        showAgenda: false,
        showHabits: false,
      );
      await notifier.setClockFormat(showDate: false);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-habit-grid')), findsNothing);
      await tester.drag(homeList, const Offset(0, 1200));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-date-hijri')), findsNothing);
      expect(find.byKey(const ValueKey('home-current-event')), findsNothing);
      expect(find.byKey(const ValueKey('home-agenda-carousel')), findsNothing);
      expect(find.byKey(const ValueKey('home-habit-grid')), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Home analog clock exposes its current time and action', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: FocusClockHomeView(
              onOpenFocusClock: () {},
              onOpenAppDrawer: () {},
              useSampleData: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final clockSemantics = tester.getSemantics(
        find.byKey(const ValueKey('home-analog-clock')),
      );
      expect(clockSemantics.hasFlag(SemanticsFlag.isButton), isTrue);
      expect(
        clockSemantics.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );
      expect(
        clockSemantics.label,
        startsWith('Buka jam jadwal. Sekarang pukul '),
      );
      semantics.dispose();
      await tester.pumpWidget(const SizedBox());
    });

    test('LauncherSettings serialization, defaults, and copyWith', () {
      final settings = LauncherSettings();
      expect(settings.wallpaperType, 'system');
      expect(settings.is24h, true);
      expect(settings.showSeconds, false);
      expect(settings.dockPackages.length, 4);
      expect(settings.autoFocusSearch, false);

      final modified = settings.copyWith(
        wallpaperType: 'midnight_slate',
        showSeconds: true,
        dockPackages: ['app1', 'app2', 'app3', 'app4'],
        autoFocusSearch: false,
      );
      expect(modified.wallpaperType, 'midnight_slate');
      expect(modified.showSeconds, true);
      expect(modified.autoFocusSearch, false);

      final jsonStr = modified.toJson();
      final decoded = LauncherSettings.fromJson(jsonStr);
      expect(decoded.wallpaperType, 'midnight_slate');
      expect(decoded.showSeconds, true);
      expect(decoded.dockPackages, ['app1', 'app2', 'app3', 'app4']);
      expect(decoded.autoFocusSearch, false);
    });
  });

  testWidgets('four destination labels remain operable at 200% text scale', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 720);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const FitrahLauncherShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    const labels = ['Jam', 'Hari Ini', 'Habit', 'Aplikasi'];
    for (var index = 0; index < labels.length; index++) {
      final label = labels[index];
      expect(find.text(label), findsWidgets);
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        index,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home habits title and Semua route fit 320dp at 200% text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 720);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sadarRepoProvider.overrideWithValue(SadarRepository(null))],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const FitrahLauncherShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final homeList = find.byKey(const ValueKey('focus-clock-home-list'));
    final title = find.text('Kebiasaan hari ini');
    for (var i = 0; i < 14; i++) {
      final rect = title.evaluate().isEmpty ? null : tester.getRect(title);
      if (rect != null && rect.top >= 0 && rect.bottom <= 720) break;
      await tester.drag(
        homeList,
        Offset(0, rect != null && rect.top < 0 ? 240 : -500),
      );
      await tester.pumpAndSettle();
    }
    expect(title, findsOneWidget);
    expect(find.text('Semua'), findsWidgets);
    final viewport = const Rect.fromLTWH(0, 0, 320, 720);
    expect(viewport.contains(tester.getRect(title).topLeft), isTrue);
    final button = find.widgetWithText(TextButton, 'Semua');
    expect(viewport.contains(tester.getRect(button).topLeft), isTrue);
    expect(viewport.contains(tester.getRect(button).bottomRight), isTrue);
    expect(tester.takeException(), isNull);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(tester.widget<PageView>(find.byType(PageView)).controller!.page, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Habits library starts at the top at large text scale', (
    tester,
  ) async {
    final repo = SadarRepository(null);
    for (final existing in await repo.getHabits()) {
      await repo.deleteHabit(existing.id, hardDelete: true);
    }
    await repo.upsertHabit(
      Habit()
        ..name = 'Latihan LKS'
        ..createdAt = DateTime(2026, 1, 1)
        ..colorValue = Colors.blue.toARGB32(),
    );
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(411, 914);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sadarRepoProvider.overrideWithValue(repo)],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const FitrahLauncherShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Habit'));
    await tester.pumpAndSettle();

    final title = tester.getRect(find.text('Semua kebiasaan'));
    expect(title.top, lessThan(64));
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty Habits destination keeps its create action available', (
    tester,
  ) async {
    final repo = SadarRepository(null);
    for (final habit in await repo.getHabits()) {
      await repo.deleteHabit(habit.id, hardDelete: true);
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sadarRepoProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: FitrahLauncherShell()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Habit'));
    await tester.pumpAndSettle();
    expect(find.text('Semua kebiasaan'), findsOneWidget);
    expect(find.text('Belum ada kebiasaan'), findsOneWidget);
    final addButton = find.widgetWithText(OutlinedButton, 'Tambah');
    expect(tester.widget<OutlinedButton>(addButton).onPressed, isNotNull);
    await tester.tap(addButton);
    await tester.pumpAndSettle();
    expect(find.text('Kebiasaan Bermakna Baru'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
