import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_clock/features/launcher/fitrah_launcher_shell.dart';
import 'package:focus_clock/features/launcher/services/app_launcher_service.dart';
import 'package:focus_clock/features/launcher/widgets/fitrah_home_view.dart';
import 'package:focus_clock/features/launcher/widgets/minimalist_app_drawer.dart';

void main() {
  group('Fitrah Launcher Tests', () {
    test('InstalledApp model firstLetter calculation and copyWith', () {
      const app1 = InstalledApp(appName: 'Browser', packageName: 'com.android.browser');
      expect(app1.firstLetter, 'B');

      const app2 = InstalledApp(appName: '1Password', packageName: 'com.onepassword');
      expect(app2.firstLetter, '#');

      final updated = app1.copyWith(isFavorite: true);
      expect(updated.isFavorite, true);
      expect(updated.appName, 'Browser');
    });

    testWidgets('FitrahHomeView renders clock header and agenda sections', (tester) async {
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

      expect(find.text('AGENDA HARI INI'), findsOneWidget);
      expect(find.text('KEBIASAAN & FITRAH'), findsOneWidget);
      expect(find.text('Refleksi Hari Ini'), findsOneWidget);
    });

    testWidgets('MinimalistAppDrawer renders search bar and app list', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MinimalistAppDrawer(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Cari aplikasi...'), findsOneWidget);
      expect(find.text('FAVORIT'), findsOneWidget);
    });

    testWidgets('FitrahLauncherShell initial page is center Home', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FitrahLauncherShell(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(FitrahHomeView), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);
    });
  });
}
