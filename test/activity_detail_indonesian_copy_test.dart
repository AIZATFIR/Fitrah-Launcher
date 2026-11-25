import 'package:fitrah_launcher/core/time_math.dart';
import 'package:fitrah_launcher/features/activity_detail/activity_detail_sheet.dart';
import 'package:fitrah_launcher/models/activity.dart';
import 'package:fitrah_launcher/models/app_settings.dart';
import 'package:fitrah_launcher/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('activity editor labels its controls in Indonesian', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith((ref) => Stream.value(AppSettings())),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showActivityDetailSheet(
                  context,
                  activity: _activity(recurrence: 'none'),
                  mode: DetailMode.create,
                ),
                child: const Text('Buka editor'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buka editor'));
    await tester.pumpAndSettle();

    expect(find.text('Kegiatan baru'), findsOneWidget);
    expect(find.text('Mulai'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
    expect(find.text('Sekali'), findsOneWidget);
    expect(find.text('Setiap hari'), findsOneWidget);
    expect(find.text('Hari kerja'), findsOneWidget);
    expect(find.text('Setiap minggu'), findsOneWidget);
    expect(find.text('Cepat'), findsAtLeastNWidgets(1));
    expect(find.text('Rinci 14 mnt'), findsOneWidget);
    expect(find.text('Fokus mendalam'), findsAtLeastNWidgets(1));
    expect(find.text('Batal'), findsOneWidget);
    expect(find.text('Simpan'), findsOneWidget);
  });

  testWidgets('weekday recurrence summary says working days', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith((ref) => Stream.value(AppSettings())),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showActivityDetailSheet(
                  context,
                  activity: _activity(recurrence: 'weekday'),
                ),
                child: const Text('Buka jadwal'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buka jadwal'));
    await tester.pumpAndSettle();

    expect(find.text('Ulangi hari kerja'), findsOneWidget);
  });
}

Activity _activity({required String recurrence}) => Activity()
  ..title = 'Latihan LKS'
  ..startMinute = 540
  ..endMinute = 600
  ..ampmHalf = AmPmHalf.am
  ..date = DateTime(2026, 11, 20)
  ..colorValue = 0xff345678
  ..recurrence = recurrence
  ..createdAt = DateTime(2026, 11, 1)
  ..updatedAt = DateTime(2026, 11, 1);
