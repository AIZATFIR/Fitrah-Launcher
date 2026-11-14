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

      expect(find.text('Fajr'), findsOneWidget);
      expect(find.text('Dhuhr'), findsOneWidget);
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
      expect(find.text('Search apps'), findsOneWidget);
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

    testWidgets('Home follows the saved prayer versus Focus Events setting', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
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
      expect(find.byKey(const ValueKey('home-current-event')), findsOneWidget);
      expect(container.read(launcherSettingsProvider).showHabitsWidget, isTrue);
      expect(
        find.byKey(const ValueKey('home-agenda-carousel')),
        findsOneWidget,
      );
      expect(
        tester
            .getSemantics(
              find.byKey(const ValueKey('home-prayer-focus-toggle')),
            )
            .label,
        'Tampilkan waktu sholat',
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
      await tester.drag(homeList, const Offset(0, 1200));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('home-prayer-focus-toggle')));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.mosque_rounded), findsOneWidget);
      expect(find.text('Subuh'), findsOneWidget);
      expect(
        tester
            .getSemantics(
              find.byKey(const ValueKey('home-prayer-focus-toggle')),
            )
            .hasFlag(SemanticsFlag.isToggled),
        isTrue,
      );
      expect(
        LauncherSettings.fromJson(storage.raw!).widgetDisplayMode,
        'prayer',
      );

      await container
          .read(launcherSettingsProvider.notifier)
          .togglePrayerTimes(false);
      await tester.pumpAndSettle();
      expect(find.text('Subuh'), findsNothing);
      expect(
        tester
            .getSemantics(
              find.byKey(const ValueKey('home-prayer-focus-toggle')),
            )
            .label,
        'Waktu sholat nonaktif. Aktifkan di Pengaturan Home',
      );
      await tester.tap(find.byKey(const ValueKey('home-prayer-focus-toggle')));
      await tester.pumpAndSettle();
      expect(
        find.text('Aktifkan baris waktu sholat di Pengaturan Home.'),
        findsOneWidget,
      );

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

      semantics.dispose();
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
        RegExp(
          r'^Jam jadwal hari ini\. Sekarang pukul \d{2}:\d{2}\. Ketuk untuk menambah jadwal\.$',
        ).hasMatch(clockSemantics.label),
        isTrue,
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
}
