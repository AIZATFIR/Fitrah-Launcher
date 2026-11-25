import 'package:fitrah_launcher/data/repositories/activity_repository.dart';
import 'package:fitrah_launcher/data/isar_service.dart';
import 'package:fitrah_launcher/data/store/focus_store.dart';
import 'package:fitrah_launcher/data/store/native_focus_store.dart';
import 'package:fitrah_launcher/models/activity.dart';
import 'package:fitrah_launcher/core/time_math.dart';
import 'package:fitrah_launcher/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:convert';
import 'package:isar_community/isar.dart';

void main() {
  late FocusStore store;
  late ActivityRepository repository;
  final seriesStart = DateTime(2026, 11, 2);
  final occurrenceDate = DateTime(2026, 11, 5);
  late Directory dir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (Platform.isLinux) {
      final config =
          jsonDecode(
                await File('.dart_tool/package_config.json').readAsString(),
              )
              as Map<String, dynamic>;
      final packages = (config['packages'] as List)
          .cast<Map<String, dynamic>>();
      final root = Uri.parse(
        packages.firstWhere(
              (p) => p['name'] == 'isar_community_flutter_libs',
            )['rootUri']
            as String,
      );
      await Isar.initializeIsarCore(
        libraries: {ffi.Abi.current(): '${root.path}/linux/libisar.so'},
      );
    }
  });

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('recurring-edit-');
    final isar = (await IsarService.openAt(dir.path)).isar!;
    store = NativeFocusStore(isar);
    repository = ActivityRepository.store(store, NotificationService());
  });

  tearDown(() async {
    await store.close();
    await dir.delete(recursive: true);
  });

  Activity segment({
    required String title,
    required DateTime date,
    required AmPmHalf half,
    required int start,
    required int end,
    String? groupId,
  }) => Activity()
    ..title = title
    ..startMinute = start
    ..endMinute = end
    ..ampmHalf = half
    ..date = date
    ..colorValue = 0xff345678
    ..recurrence = 'none'
    ..groupId = groupId
    ..createdAt = seriesStart
    ..updatedAt = seriesStart;

  Future<List<Activity>> saveWeekdayOvernightSeries() async {
    final group = [
      segment(
        title: 'LKS recurring prep',
        date: DateTime(2026, 11, 6),
        half: AmPmHalf.pm,
        start: 660,
        end: 720,
        groupId: 'weekday-overnight',
      ),
      segment(
        title: 'LKS recurring prep',
        date: DateTime(2026, 11, 7),
        half: AmPmHalf.am,
        start: 0,
        end: 60,
        groupId: 'weekday-overnight',
      ),
    ];
    for (final activity in group) {
      activity.recurrence = 'weekday';
      await repository.upsert(activity);
    }
    return group;
  }

  test('editing one occurrence preserves its recurring series', () async {
    final series = Activity()
      ..title = 'Study LKS'
      ..startMinute = 540
      ..endMinute = 600
      ..ampmHalf = AmPmHalf.am
      ..date = seriesStart
      ..colorValue = 0xff345678
      ..recurrence = 'weekday'
      ..createdAt = seriesStart
      ..updatedAt = seriesStart;
    await repository.upsert(series);

    final editedOccurrence = Activity()
      ..title = 'Practice algorithms'
      ..startMinute = 570
      ..endMinute = 630
      ..ampmHalf = AmPmHalf.am
      ..date = occurrenceDate
      ..colorValue = 0xff123456
      ..recurrence = 'none'
      ..createdAt = seriesStart
      ..updatedAt = seriesStart;

    await repository.editSingleInstance(
      series,
      occurrenceDate,
      editedOccurrence,
    );

    final savedSeries = await repository.get(series.id);
    final rows = await store.activitys.all();
    expect(savedSeries!.title, 'Study LKS');
    expect(savedSeries.recurrence, 'weekday');
    expect(savedSeries.excludedDates, [occurrenceDate]);
    final exception = rows.singleWhere((row) => row.id != series.id);
    expect(exception.title, 'Practice algorithms');
    expect(exception.date, occurrenceDate);
    expect(exception.recurrence, 'none');
    final editedDate = await repository.getByDate(occurrenceDate);
    expect(editedDate, hasLength(1));
    expect(editedDate.single.id, exception.id);
    expect(
      (await repository.getByDate(DateTime(2026, 11, 4))).single.id,
      series.id,
    );
    expect(
      (await repository.getByDate(DateTime(2026, 11, 6))).single.id,
      series.id,
    );
  });

  test(
    'weekday overnight series projects its Friday tail into Saturday',
    () async {
      final group = await saveWeekdayOvernightSeries();

      final saturday = await repository.getByDate(DateTime(2026, 11, 14));

      expect(saturday, hasLength(1));
      expect(saturday.single.id, group.last.id);
      expect(saturday.single.date, DateTime(2026, 11, 14));
    },
  );

  test(
    'same-title activities keep distinct IDs beside recurrence projections',
    () async {
      final recurring = segment(
        title: 'LKS',
        date: DateTime(2026, 11, 2),
        half: AmPmHalf.am,
        start: 540,
        end: 600,
      )..recurrence = 'daily';
      final direct = segment(
        title: 'LKS',
        date: DateTime(2026, 11, 3),
        half: AmPmHalf.am,
        start: 540,
        end: 600,
      );
      await repository.upsert(recurring);
      await repository.upsert(direct);

      final day = await repository.getByDate(DateTime(2026, 11, 3));

      expect(day, hasLength(2));
      expect(day.map((activity) => activity.id).toSet(), {
        recurring.id,
        direct.id,
      });
    },
  );

  test(
    'editing the Friday occurrence from Saturday replaces the full block only once',
    () async {
      final group = await saveWeekdayOvernightSeries();
      final edited = [
        segment(
          title: 'LKS competition prep',
          date: DateTime(2026, 11, 13),
          half: AmPmHalf.pm,
          start: 660,
          end: 720,
          groupId: 'exception-nov-13',
        ),
        segment(
          title: 'LKS competition prep',
          date: DateTime(2026, 11, 14),
          half: AmPmHalf.am,
          start: 0,
          end: 60,
          groupId: 'exception-nov-13',
        ),
      ];

      await repository.editSingleInstanceSpan(
        group.last,
        DateTime(2026, 11, 13),
        edited,
      );

      final savedGroup = await repository.getGroup('weekday-overnight');
      expect(savedGroup, hasLength(2));
      expect(savedGroup[0].excludedDates, [DateTime(2026, 11, 13)]);
      expect(savedGroup[1].excludedDates, [DateTime(2026, 11, 14)]);
      final friday = await repository.getByDate(DateTime(2026, 11, 13));
      final saturday = await repository.getByDate(DateTime(2026, 11, 14));
      final fridayReplacement = friday.singleWhere(
        (activity) => activity.ampmHalf == AmPmHalf.pm,
      );
      expect(fridayReplacement.title, 'LKS competition prep');
      expect(saturday.single.title, 'LKS competition prep');
      expect(fridayReplacement.groupId, 'exception-nov-13');
      expect(saturday.single.groupId, 'exception-nov-13');
      expect(
        (await repository.getByDate(
          DateTime(2026, 11, 20),
        )).singleWhere((activity) => activity.ampmHalf == AmPmHalf.pm).id,
        group.first.id,
      );
      expect(
        (await repository.getByDate(DateTime(2026, 11, 21))).single.id,
        group.last.id,
      );
    },
  );

  test(
    'deleting a grouped recurrence removes the whole selected occurrence',
    () async {
      final group = await saveWeekdayOvernightSeries();

      await repository.deleteSingleInstance(group.last, DateTime(2026, 11, 14));

      expect(await repository.getByDate(DateTime(2026, 11, 14)), isEmpty);
      expect(
        (await repository.getByDate(DateTime(2026, 11, 21))).single.id,
        group.last.id,
      );
      final savedGroup = await repository.getGroup('weekday-overnight');
      expect(savedGroup[0].excludedDates, [DateTime(2026, 11, 13)]);
      expect(savedGroup[1].excludedDates, [DateTime(2026, 11, 14)]);
    },
  );

  test(
    'series edits keep segment IDs and measured activity evidence',
    () async {
      final group = await saveWeekdayOvernightSeries();
      for (var index = 0; index < group.length; index++) {
        final saved = (await repository.get(group[index].id))!
          ..isCompleted = true;
        saved.actualDurationSeconds = (index + 1) * 120;
        saved.excludedDates = [DateTime(2026, 11, 13 + index)];
        await repository.upsert(saved);
      }
      final edited = [
        segment(
          title: 'LKS series edit',
          date: DateTime(2026, 11, 6),
          half: AmPmHalf.pm,
          start: 650,
          end: 720,
          groupId: 'weekday-overnight',
        )..recurrence = 'weekday',
        segment(
          title: 'LKS series edit',
          date: DateTime(2026, 11, 7),
          half: AmPmHalf.am,
          start: 0,
          end: 70,
          groupId: 'weekday-overnight',
        )..recurrence = 'weekday',
      ];

      await repository.replaceSpan(original: group.first, segments: edited);

      final saved = await repository.getGroup('weekday-overnight');
      expect(
        saved.map((activity) => activity.id),
        group.map((activity) => activity.id),
      );
      expect(saved.map((activity) => activity.actualDurationSeconds), [
        120,
        240,
      ]);
      expect(saved.map((activity) => activity.isCompleted), [true, true]);
      expect(saved[0].excludedDates, [DateTime(2026, 11, 13)]);
      expect(saved[1].excludedDates, [DateTime(2026, 11, 14)]);
      expect(saved.map((activity) => activity.title), [
        'LKS series edit',
        'LKS series edit',
      ]);
    },
  );

  test('series edit cannot discard a segment with recorded history', () async {
    final group = await saveWeekdayOvernightSeries();
    final historySegment = (await repository.get(group.last.id))!
      ..actualDurationSeconds = 75;
    await repository.upsert(historySegment);
    final shortened = [
      segment(
        title: 'Shortened recurrence',
        date: DateTime(2026, 11, 6),
        half: AmPmHalf.pm,
        start: 660,
        end: 700,
        groupId: 'weekday-overnight',
      )..recurrence = 'weekday',
    ];

    await expectLater(
      repository.replaceSpan(original: group.first, segments: shortened),
      throwsStateError,
    );

    final saved = await repository.getGroup('weekday-overnight');
    expect(
      saved.map((activity) => activity.id),
      group.map((activity) => activity.id),
    );
    expect(saved.last.actualDurationSeconds, 75);
  });
}
