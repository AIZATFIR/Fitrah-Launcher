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
