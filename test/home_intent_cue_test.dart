import 'package:fitrah_launcher/services/notification_service.dart';
import 'package:fitrah_launcher/features/launcher/widgets/focus_clock_home_view.dart';
import 'package:fitrah_launcher/core/time_math.dart';
import 'package:fitrah_launcher/models/timer_session.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitrah_launcher/data/repositories/intent_repository.dart';
import 'package:fitrah_launcher/data/repositories/sadar_repository.dart';
import 'package:fitrah_launcher/data/store/focus_store.dart';
import 'package:fitrah_launcher/data/store/live_model_codec.dart';
import 'package:fitrah_launcher/domain/focus_intent.dart';
import 'package:fitrah_launcher/features/launcher/widgets/home_intent_cue.dart';
import 'package:fitrah_launcher/models/activity.dart';
import 'package:fitrah_launcher/models/focus_intent_document.dart';
import 'package:fitrah_launcher/models/habit.dart';
import 'package:fitrah_launcher/models/habit_entry.dart';
import 'package:fitrah_launcher/models/task.dart';
import 'package:fitrah_launcher/providers/intent_providers.dart';
import 'package:fitrah_launcher/providers/providers.dart';
import 'package:fitrah_launcher/services/sadar_timer_engine.dart';

void main() {
  final now = DateTime(2026, 11, 8, 10);
  late _Store store;
  late IntentRepository repo;

  const sourceId = '33333333-3333-4333-8333-333333333333';
  const storeId = '11111111-1111-4111-8111-111111111111';
  Future<void> show(
    WidgetTester tester, {
    IntentState? state,
    void Function(Habit)? habitAction,
    void Function(Habit, String?, String?)? attributedHabitAction,
    void Function(Habit)? habitSchedule,
    ValueChanged<IntentGoal?>? assistantAction,
    Future<void> Function(Task, {String? goalId, String? goalTitle})?
    taskAction,
    Stream<IntentState>? intentStream,
    double width = 800,
    double textScale = 1,
    Color foreground = Colors.black,
    Color secondary = Colors.grey,
    Color accent = Colors.green,
    Color surface = Colors.white,
  }) async {
    tester.view.physicalSize = Size(width, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await store.put(
      FocusIntentDocument()
        ..payload =
            (state ?? IntentState(sourceStoreId: storeId, legacyImported: true))
                .encode(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          focusStoreProvider.overrideWithValue(store),
          notificationServiceProvider.overrideWithValue(NotificationService()),
          currentDateProvider.overrideWith((ref) => DateTime(2020, 1, 1)),
          intentRepositoryProvider.overrideWithValue(repo),
          intentInitializationProvider.overrideWith((ref) async {}),
          intentNowProvider.overrideWithValue(now),
          timerEngineProvider.overrideWith(
            (ref) => SadarTimerEngine(SadarRepository.store(store)),
          ),
          if (intentStream != null)
            intentStateProvider.overrideWith((ref) => intentStream),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: HomeIntentCue(
                foreground: foreground,
                secondary: secondary,
                accent: accent,
                surface: surface,
                onHabitTimer: habitAction ?? (_) {},
                onAttributedHabitTimer: attributedHabitAction,
                onHabitSchedule: habitSchedule,
                onAssistant: assistantAction,
                onTaskAction:
                    taskAction ??
                    (task, {String? goalId, String? goalTitle}) async {},
                onSession: () {},
              ),
            ),
          ),
        ),
      ),
    );
    if (intentStream == null) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  IntentState selected(
    IntentSourceType type, {
    List<IntentGoal> goals = const [],
    List<IntentLink> links = const [],
  }) => IntentState(
    sourceStoreId: storeId,
    legacyImported: true,
    goals: goals,
    links: links,
    sources: [
      IntentSource(
        id: sourceId,
        sourceStoreId: storeId,
        type: type,
        legacyId: 7,
      ),
    ],
    selections: [
      TodaySelection(
        localDate: '2026-11-08',
        sourceId: sourceId,
        chosenAtUtc: now.toUtc(),
      ),
    ],
  );
  setUp(() {
    store = _Store();
    repo = IntentRepository(store, now: () => now);
  });
  tearDown(() async {
    unawaited(store.close());
  });

  testWidgets('goal header opens the assistant with the pinned goal', (
    tester,
  ) async {
    IntentGoal? goalSentToAssistant;
    await show(
      tester,
      state: IntentState(
        sourceStoreId: storeId,
        legacyImported: true,
        goals: const [
          IntentGoal(
            id: '22222222-2222-4222-8222-222222222222',
            title: 'Menang LKS Nasional IT Software Solution',
            pinned: true,
          ),
        ],
      ),
      assistantAction: (goal) => goalSentToAssistant = goal,
    );

    expect(find.text('Tanya AI'), findsOneWidget);
    await tester.tap(find.text('Tanya AI'));
    expect(goalSentToAssistant?.id, '22222222-2222-4222-8222-222222222222');
    expect(
      goalSentToAssistant?.title,
      'Menang LKS Nasional IT Software Solution',
    );
  });

  testWidgets('goal cue keeps Tanya AI visible at 320dp without overflow', (
    tester,
  ) async {
    await show(
      tester,
      width: 320,
      state: IntentState(
        sourceStoreId: storeId,
        legacyImported: true,
        goals: const [
          IntentGoal(
            id: '22222222-2222-4222-8222-222222222222',
            title: 'Menang LKS',
            pinned: true,
          ),
        ],
      ),
      assistantAction: (_) {},
    );

    expect(find.text('Menang LKS'), findsOneWidget);
    expect(find.text('Tanya AI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('goal heading wraps at 200% text scale without truncation', (
    tester,
  ) async {
    await show(
      tester,
      width: 320,
      textScale: 2,
      state: IntentState(
        sourceStoreId: storeId,
        legacyImported: true,
        goals: const [
          IntentGoal(
            id: '22222222-2222-4222-8222-222222222222',
            title: 'Menang LKS',
            pinned: true,
          ),
        ],
      ),
      assistantAction: (_) {},
    );

    expect(find.text('Tanya AI'), findsOneWidget);
    expect(
      tester
          .renderObject<RenderParagraph>(find.text('TUJUAN UTAMA'))
          .didExceedMaxLines,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('timed daily choice passes its explicitly linked goal snapshot', (
    tester,
  ) async {
    await store.put(
      Habit()
        ..id = 7
        ..name = 'LKS'
        ..unit = HabitUnit.min
        ..habitType = 'timed'
        ..target = 45
        ..colorValue = 0xff123456
        ..createdAt = now,
    );
    String? goalId;
    String? goalTitle;
    await show(
      tester,
      state: selected(
        IntentSourceType.habit,
        goals: const [
          IntentGoal(
            id: '22222222-2222-4222-8222-222222222222',
            title: 'Win nationals',
          ),
        ],
        links: const [
          IntentLink(
            sourceId: sourceId,
            goalId: '22222222-2222-4222-8222-222222222222',
          ),
        ],
      ),
      attributedHabitAction: (_, id, title) {
        goalId = id;
        goalTitle = title;
      },
    );
    await tester.tap(find.text('Mulai fokus'));
    expect(goalId, '22222222-2222-4222-8222-222222222222');
    expect(goalTitle, 'Win nationals');
  });

  testWidgets('scheduled task action is one tap away from starting focus', (
    tester,
  ) async {
    await store.put(
      Task()
        ..id = 7
        ..title = 'Latihan LKS'
        ..activityId = 14
        ..createdAt = now,
    );
    String? receivedGoalId;
    String? receivedGoalTitle;
    await show(
      tester,
      state: selected(
        IntentSourceType.task,
        goals: const [
          IntentGoal(
            id: '22222222-2222-4222-8222-222222222222',
            title: 'Win nationals',
          ),
        ],
        links: const [
          IntentLink(
            sourceId: sourceId,
            goalId: '22222222-2222-4222-8222-222222222222',
          ),
        ],
      ),
      taskAction: (task, {String? goalId, String? goalTitle}) async {
        receivedGoalId = goalId;
        receivedGoalTitle = goalTitle;
      },
    );

    expect(find.text('Mulai fokus'), findsOneWidget);
    expect(find.text('Buka jadwal tugas'), findsNothing);
    await tester.tap(find.text('Mulai fokus'));
    await tester.pumpAndSettle();
    expect(receivedGoalId, '22222222-2222-4222-8222-222222222222');
    expect(receivedGoalTitle, 'Win nationals');
  });

  testWidgets('loading and failed intent differ from empty and expose retry', (
    tester,
  ) async {
    final stream = StreamController<IntentState>();
    await show(tester, intentStream: stream.stream);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Apa arah yang ingin kamu jaga?'), findsNothing);
    stream.addError(StateError('read failed'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Belum dapat memuat:'), findsOneWidget);
    expect(find.text('Coba lagi tujuan'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    unawaited(stream.close());
  });
  testWidgets('empty goal shows a clear validation message without saving', (
    tester,
  ) async {
    await show(tester);
    await tester.tap(find.byTooltip('Ubah tujuan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah tujuan'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Tulis tujuan agar bisa disimpan.'), findsOneWidget);
    expect(find.textContaining('FormatException'), findsNothing);
    expect((await repo.read()).goals, isEmpty);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets(
    'goal save retains draft on failure and locks fields, cancel and duplicate submit while pending',
    (tester) async {
      await show(tester);
      await tester.tap(find.byTooltip('Ubah tujuan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tambah tujuan'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Durable direction');
      store.failIntent = true;
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(find.textContaining('write failed'), findsOneWidget);
      expect(find.text('Durable direction'), findsOneWidget);
      expect((await repo.read()).goals, isEmpty);
      store.failIntent = false;
      store.gate = Completer<void>();
      await tester.tap(find.text('Simpan'));
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Simpan'))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Batal'))
            .onPressed,
        isNull,
      );
      expect(
        tester.widget<AbsorbPointer>(find.byType(AbsorbPointer).last).absorbing,
        true,
      );
      store.gate!.complete();
      await tester.pumpAndSettle();
      expect((await repo.read()).goals.single.title, 'Durable direction');
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'binary is unit correct, commit failure stays actionable, completion hides prompt',
    (tester) async {
      final habit = Habit()
        ..id = 7
        ..name = 'Binary action'
        ..unit = HabitUnit.binary
        ..habitType = 'binary'
        ..colorValue = 0xff123456
        ..createdAt = now;
      await store.put(habit);
      await show(tester, state: selected(IntentSourceType.habit));
      store.failEntry = true;
      await tester.tap(find.text('Tandai dilakukan'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Belum tersimpan'), findsOneWidget);
      expect(await store.all<HabitEntry>(), isEmpty);
      store.failEntry = false;
      await tester.tap(find.text('Tandai dilakukan'));
      await tester.pumpAndSettle();
      final entry = (await store.all<HabitEntry>()).single;
      expect(entry.habitId, 7);
      expect(entry.valueCompleted, 1);
      expect(entry.actualDurationMinutes, 0);
      expect(entry.actualDurationSeconds, 0);
      expect(find.text('Tandai dilakukan'), findsNothing);
      expect(find.textContaining('Pilihan hari ini selesai'), findsOneWidget);
    },
  );
  testWidgets(
    'count asks absolute unit quantity without creating measured duration',
    (tester) async {
      await store.put(
        Habit()
          ..id = 7
          ..name = 'Count'
          ..unit = HabitUnit.count
          ..habitType = 'count'
          ..target = 5
          ..colorValue = 0xff123456
          ..createdAt = now,
      );
      await show(tester, state: selected(IntentSourceType.habit));
      await tester.tap(find.text('Catat jumlah'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '3');
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      final entry = (await store.all<HabitEntry>()).single;
      expect(entry.valueCompleted, 3);
      expect(entry.actualDurationMinutes, 0);
      expect(entry.status, HabitStatus.unmarked);
    },
  );
  testWidgets('count check-in preserves existing measured duration evidence', (
    tester,
  ) async {
    await store.put(
      Habit()
        ..id = 7
        ..name = 'Count with evidence'
        ..unit = HabitUnit.count
        ..habitType = 'count'
        ..target = 5
        ..colorValue = 0xff123456
        ..createdAt = now,
    );
    await store.put(
      HabitEntry()
        ..id = 17
        ..habitId = 7
        ..dateString = '2026-11-08'
        ..targetSnapshot = 5
        ..valueCompleted = 1
        ..actualDurationMinutes = 2
        ..actualDurationSeconds = 123
        ..updatedAt = now,
    );
    await show(tester, state: selected(IntentSourceType.habit));
    await tester.tap(find.text('Catat jumlah'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '4');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    final entry = (await store.all<HabitEntry>()).single;
    expect(entry.valueCompleted, 4);
    expect(entry.actualDurationMinutes, 2);
    expect(entry.actualDurationSeconds, 123);
  });

  testWidgets(
    'timed habit and duplicate task title dispatch exact IDs with visible relationship',
    (tester) async {
      await store.put(
        Habit()
          ..id = 7
          ..name = 'Same'
          ..colorValue = 0xff123456
          ..createdAt = now,
      );
      int? habitId;
      int? scheduledId;
      await show(
        tester,
        state: selected(IntentSourceType.habit),
        habitAction: (h) => habitId = h.id,
        habitSchedule: (h) => scheduledId = h.id,
      );
      await tester.tap(find.text('Atur waktu'));
      expect(scheduledId, 7);
      await tester.tap(find.text('Mulai fokus'));
      await tester.pumpAndSettle();
      expect(habitId, 7);
      await tester.pumpWidget(const SizedBox());
      await store.put(
        Task()
          ..id = 7
          ..title = 'Same'
          ..createdAt = now,
      );
      await store.put(
        Task()
          ..id = 8
          ..title = 'Same'
          ..createdAt = now,
      );
      const goal = IntentGoal(
        id: '22222222-2222-4222-8222-222222222222',
        title: 'Long direction',
        pinned: true,
      );
      int? taskId;
      await show(
        tester,
        state: selected(
          IntentSourceType.task,
          goals: [goal],
          links: [
            const IntentLink(
              sourceId: sourceId,
              goalId: '22222222-2222-4222-8222-222222222222',
            ),
          ],
        ),
        taskAction: (t, {String? goalId, String? goalTitle}) async {
          taskId = t.id;
        },
      );
      expect(find.text('Tujuan: Long direction'), findsOneWidget);
      await tester.tap(find.text('Jadwalkan tugas'));
      await tester.pumpAndSettle();
      expect(taskId, 7);
    },
  );
  testWidgets('choice editor modal follows each active Home palette', (
    tester,
  ) async {
    await store.put(
      Habit()
        ..id = 7
        ..name = 'Palette action'
        ..unit = HabitUnit.binary
        ..habitType = 'binary'
        ..colorValue = 0xff123456
        ..createdAt = now,
    );
    for (final palette in [
      (
        foreground: const Color(0xffeff5f8),
        secondary: const Color(0xff90a3b5),
        accent: const Color(0xff38bdf8),
        surface: const Color(0xff121924),
      ),
      (
        foreground: const Color(0xfff7f2eb),
        secondary: const Color(0xffa89f95),
        accent: const Color(0xffe8c89a),
        surface: const Color(0xff1d1916),
      ),
    ]) {
      await show(
        tester,
        foreground: palette.foreground,
        secondary: palette.secondary,
        accent: palette.accent,
        surface: palette.surface,
      );
      await tester.tap(find.text('Pilih tindakan hari ini'));
      await tester.pumpAndSettle();

      final dialog = tester.element(find.byType(AlertDialog).last);
      final theme = Theme.of(dialog);
      expect(theme.colorScheme.primary, palette.accent);
      expect(theme.colorScheme.onPrimary, palette.surface);
      expect(theme.colorScheme.onSurface, palette.foreground);
      expect(theme.dialogTheme.backgroundColor, palette.surface);
      expect(theme.textTheme.bodyLarge?.color, palette.foreground);
      expect(theme.inputDecorationTheme.fillColor, isNotNull);
      expect(theme.inputDecorationTheme.fillColor, isNot(palette.accent));
      expect(theme.inputDecorationTheme.labelStyle?.color, palette.secondary);
      expect(theme.progressIndicatorTheme.color, palette.accent);
      expect(
        (theme.inputDecorationTheme.enabledBorder as OutlineInputBorder)
            .borderSide
            .color,
        palette.secondary.withValues(alpha: 0.42),
      );
      expect(
        (theme.inputDecorationTheme.focusedBorder as OutlineInputBorder)
            .borderSide
            .color,
        palette.accent,
      );

      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets(
    'choice editor saves explicit link, retains failed draft, reopens and clears durably',
    (tester) async {
      await store.put(
        Habit()
          ..id = 7
          ..name = 'My habit'
          ..unit = HabitUnit.binary
          ..habitType = 'binary'
          ..colorValue = 0xff123456
          ..createdAt = now,
      );
      const goal = IntentGoal(
        id: '22222222-2222-4222-8222-222222222222',
        title: 'My direction',
        pinned: true,
      );
      await show(
        tester,
        state: IntentState(
          sourceStoreId: storeId,
          legacyImported: true,
          goals: [goal],
        ),
      );
      await tester.tap(find.text('Pilih tindakan hari ini'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('My habit').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('My direction').last);
      await tester.pumpAndSettle();
      store.failIntent = true;
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(find.textContaining('write failed'), findsOneWidget);
      expect(find.text('My habit'), findsOneWidget);
      expect(
        Theme.of(
          tester.element(find.byType(AlertDialog).last),
        ).colorScheme.primary,
        Colors.green,
      );
      store.failIntent = false;
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(find.text('Tujuan: My direction'), findsOneWidget);
      final saved = await repo.read();
      expect(saved.links.single.goalId, goal.id);
      expect(
        saved.sourceFor(saved.selectionFor('2026-11-08')!.sourceId)!.legacyId,
        7,
      );
      await tester.pumpWidget(const SizedBox());
      await show(tester, state: saved);
      expect(find.text('My habit'), findsOneWidget);
      await tester.tap(find.text('Ganti tindakan'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kosongkan pilihan').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect((await repo.read()).selectionFor('2026-11-08')!.sourceId, isNull);
    },
  );

  testWidgets(
    'foreign source editor preserves identity until an explicit local selection',
    (tester) async {
      await store.put(
        Habit()
          ..id = 7
          ..name = 'Unrelated local habit'
          ..unit = HabitUnit.binary
          ..habitType = 'binary'
          ..colorValue = 0xff123456
          ..createdAt = now,
      );
      final foreign = IntentSource(
        id: sourceId,
        sourceStoreId: '44444444-4444-4444-8444-444444444444',
        type: IntentSourceType.habit,
        legacyId: 7,
      );
      final state = selected(
        IntentSourceType.habit,
      ).copyWith(sources: [foreign]);
      await show(tester, state: state);
      await tester.tap(find.text('Pilih tindakan hari ini'));
      await tester.pumpAndSettle();
      expect(find.text('Pilihan tersimpan tidak tersedia'), findsOneWidget);
      expect(find.text('Unrelated local habit'), findsNothing);
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      final unchanged = await repo.read();
      expect(unchanged.selectionFor('2026-11-08')!.sourceId, sourceId);
      expect(unchanged.sources.single.sourceStoreId, foreign.sourceStoreId);
      expect(unchanged.selectionFor('2026-11-08')!.revision, 1);
      await tester.tap(find.text('Pilih tindakan hari ini'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unrelated local habit').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      final converted = await repo.read();
      final local = converted.sourceFor(
        converted.selectionFor('2026-11-08')!.sourceId,
      )!;
      expect(local.sourceStoreId, storeId);
      expect(local.id, isNot(sourceId));
      expect(local.legacyId, 7);
      expect(
        converted.sources.where((s) => s.id == sourceId).single.sourceStoreId,
        foreign.sourceStoreId,
      );
    },
  );

  testWidgets(
    'unboxed goal cue has one editor and one primary action at 320dp and 200 percent text',
    (tester) async {
      await store.put(
        Habit()
          ..id = 7
          ..name = 'A long action that remains readable on a narrow screen'
          ..unit = HabitUnit.binary
          ..habitType = 'binary'
          ..colorValue = 0xff123456
          ..createdAt = now,
      );
      const goal = IntentGoal(
        id: '22222222-2222-4222-8222-222222222222',
        title: 'A longer direction that must wrap without hiding its editor',
        pinned: true,
      );
      await show(
        tester,
        state: selected(IntentSourceType.habit, goals: [goal]),
        width: 320,
        textScale: 2,
        surface: const Color(0xff23222b),
      );
      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Ubah tujuan'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(HomeIntentCue),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).color == Colors.white,
          ),
        ),
        findsNothing,
      );
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.style!.backgroundColor!.resolve({}), Colors.green);
      await tester.ensureVisible(find.byTooltip('Ubah tujuan'));
      await tester.tap(find.byTooltip('Ubah tujuan'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Tambah tujuan'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Tambah tujuan'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'selected persisted same-name habit schedules exact source from Home',
    (tester) async {
      for (final id in [7, 8]) {
        await store.put(
          Habit()
            ..id = id
            ..name = 'LKS same'
            ..target = 45
            ..colorValue = 0xff123456
            ..createdAt = now,
        );
      }
      await store.put(
        FocusIntentDocument()
          ..payload = selected(IntentSourceType.habit).encode(),
      );
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            focusStoreProvider.overrideWithValue(store),
            notificationServiceProvider.overrideWithValue(
              NotificationService(),
            ),
            intentRepositoryProvider.overrideWithValue(repo),
            intentInitializationProvider.overrideWith((ref) async {}),
            intentNowProvider.overrideWithValue(now),
          ],
          child: MaterialApp(
            home: FocusClockHomeView(
              onOpenFocusClock: () {},
              onOpenAppDrawer: () {},
              now: () => now,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Atur waktu'));
      await tester.pumpAndSettle();
      expect(find.text('Dari Kebiasaan & Rutinitas:'), findsOneWidget);
      await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, 'Pasang ke Focus Clock'),
      );
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Pasang ke Focus Clock'),
      );
      await tester.pumpAndSettle();
      final blocks = await store.all<Activity>();
      expect(blocks, isNotEmpty);
      expect(blocks.every((a) => a.habitId == 7), isTrue);
      expect(
        blocks.map((a) => a.endMinute - a.startMinute).reduce((a, b) => a + b),
        45,
      );
      expect(await store.all<Task>(), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'direct scheduled legacy task opens clock at its date and half without changing IDs',
    (tester) async {
      final date = DateTime(2026, 11, 12);
      await store.put(
        Task()
          ..id = 7
          ..title = 'Direct task'
          ..date = date
          ..ampmHalf = AmPmHalf.pm
          ..startMinute = 60
          ..endMinute = 90
          ..createdAt = now,
      );
      await store.put(
        FocusIntentDocument()
          ..payload = selected(
            IntentSourceType.task,
            goals: const [
              IntentGoal(
                id: '22222222-2222-4222-8222-222222222222',
                title: 'Win nationals',
              ),
            ],
            links: const [
              IntentLink(
                sourceId: sourceId,
                goalId: '22222222-2222-4222-8222-222222222222',
              ),
            ],
          ).encode(),
      );
      var opened = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            focusStoreProvider.overrideWithValue(store),
            notificationServiceProvider.overrideWithValue(
              NotificationService(),
            ),
            intentRepositoryProvider.overrideWithValue(repo),
            intentInitializationProvider.overrideWith((ref) async {}),
            intentNowProvider.overrideWithValue(now),
          ],
          child: MaterialApp(
            home: FocusClockHomeView(
              onOpenFocusClock: () => opened = true,
              onOpenAppDrawer: () {},
              now: () => now,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buka jadwal tugas'));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FocusClockHomeView)),
      );
      expect(opened, true);
      expect(container.read(currentDateProvider), date);
      expect(container.read(ampmHalfProvider), AmPmHalf.pm);
      expect(container.read(tasksByHalfProvider).single.id, 7);
      final task = (await store.all<Task>()).single;
      expect(task.id, 7);
      expect(task.activityId, isNull);
      expect(task.date, date);
      expect(await store.all<Activity>(), isEmpty);
    },
  );

  testWidgets(
    'already scheduled task opens exact existing block without duplicate scheduling',
    (tester) async {
      await store.put(
        Task()
          ..id = 7
          ..title = 'Scheduled exact task'
          ..activityId = 42
          ..startMinute = 600
          ..endMinute = 650
          ..createdAt = now,
      );
      await store.put(
        Activity()
          ..id = 42
          ..title = 'Exact existing block'
          ..ampmHalf = AmPmHalf.am
          ..startMinute = 600
          ..endMinute = 650
          ..date = DateTime(2026, 11, 8)
          ..colorValue = 0xff123456
          ..createdAt = now
          ..updatedAt = now,
      );
      await store.put(
        FocusIntentDocument()
          ..payload = selected(
            IntentSourceType.task,
            goals: const [
              IntentGoal(
                id: '22222222-2222-4222-8222-222222222222',
                title: 'Win nationals',
              ),
            ],
            links: const [
              IntentLink(
                sourceId: sourceId,
                goalId: '22222222-2222-4222-8222-222222222222',
              ),
            ],
          ).encode(),
      );
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            focusStoreProvider.overrideWithValue(store),
            notificationServiceProvider.overrideWithValue(
              NotificationService(),
            ),
            intentRepositoryProvider.overrideWithValue(repo),
            intentInitializationProvider.overrideWith((ref) async {}),
            intentNowProvider.overrideWithValue(now),
          ],
          child: MaterialApp(
            home: FocusClockHomeView(
              onOpenFocusClock: () {},
              onOpenAppDrawer: () {},
              now: () => now,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mulai fokus'));
      await tester.pumpAndSettle();
      expect(find.text('Exact existing block'), findsWidgets);
      final active = await SadarRepository.store(store).getActiveTimerSession();
      expect(active?.activityId, 42);
      expect(active?.goalId, '22222222-2222-4222-8222-222222222222');
      expect(active?.goalTitleSnapshot, 'Win nationals');
      expect((await store.all<Activity>()).length, 1);
    },
  );

  testWidgets(
    'active session wins over chosen action, changing choice never replaces session',
    (tester) async {
      await store.put(
        Habit()
          ..id = 7
          ..name = 'Next action'
          ..colorValue = 0xff123456
          ..createdAt = now,
      );
      await show(tester, state: selected(IntentSourceType.habit));
      final engine = ProviderScope.containerOf(
        tester.element(find.byType(HomeIntentCue)),
      ).read(timerEngineProvider.notifier);
      await engine.waitUntilRestored();
      await engine.startNonHabit(
        title: 'Authoritative session',
        sourceKind: TimerSessionSourceKind.free,
        targetSeconds: 1200,
      );
      await store.put(
        Habit()
          ..id = 7
          ..name = 'Next action'
          ..colorValue = 0xff123456
          ..createdAt = now,
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Sesi berjalan: Authoritative session'),
        findsOneWidget,
      );
      expect(find.text('Mulai fokus'), findsNothing);
      await repo.choose(localDate: '2026-11-08', expectedRevision: 1);
      await tester.pumpAndSettle();
      expect(engine.currentState.habitName, 'Authoritative session');
      expect(engine.currentState.isActive, true);
      await engine.pause();
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Sesi dijeda: Authoritative session'),
        findsOneWidget,
      );
      expect(find.text('Lanjutkan sesi'), findsOneWidget);
    },
  );
  testWidgets('uncertain restored session shows recovery notice on Home', (
    tester,
  ) async {
    await SadarRepository.store(store).saveTimerSession(
      TimerSession()
        ..habitId = 7
        ..habitName = 'Saved session'
        ..sourceKind = TimerSessionSourceKind.habit
        ..targetSeconds = 600
        ..startedAt = now.subtract(const Duration(hours: 1))
        ..runningSince = now.subtract(const Duration(hours: 1))
        ..accumulatedDurationSeconds = 45
        ..status = TimerStateStatus.running
        ..updatedAt = now,
    );
    await show(tester);

    expect(find.text(timerRecoveryNotice), findsOneWidget);
    expect(find.text('Lanjutkan sesi'), findsOneWidget);
  });
  testWidgets(
    'unknown legacy habit offers generic detail without invented sets',
    (tester) async {
      await store.put(
        Habit()
          ..id = 7
          ..name = 'Legacy type'
          ..habitType = 'legacy-custom'
          ..hybridSets = 99
          ..hybridDurationSeconds = 999
          ..colorValue = 0xff123456
          ..createdAt = now,
      );
      await show(
        tester,
        state: selected(IntentSourceType.habit),
        habitAction: (_) => fail('unknown type started timer'),
      );
      await tester.tap(find.text('Lihat rincian'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Jenis habit ini belum didukung'),
        findsOneWidget,
      );
      expect(find.textContaining('99 set'), findsNothing);
      expect(find.textContaining('999 detik'), findsNothing);
      expect(await store.all<HabitEntry>(), isEmpty);
    },
  );
  testWidgets(
    'hybrid home action opens the shared timer; it does not complete optimistically',
    (tester) async {
      Habit? opened;
      await store.put(
        Habit()
          ..id = 7
          ..name = 'Sets'
          ..habitType = 'hybrid'
          ..hybridSets = 4
          ..hybridDurationSeconds = 45
          ..colorValue = 0xff123456
          ..createdAt = now,
      );
      await show(
        tester,
        state: selected(IntentSourceType.habit),
        habitAction: (habit) => opened = habit,
      );
      expect(find.text('Mulai rangkaian'), findsOneWidget);
      await tester.tap(find.text('Mulai rangkaian'));
      await tester.pumpAndSettle();
      expect(opened?.id, 7);
      expect(opened?.hybridSets, 4);
      expect(opened?.hybridDurationSeconds, 45);
      expect(await store.all<HabitEntry>(), isEmpty);
    },
  );
  testWidgets(
    'progression home action confirms and records the current step once',
    (tester) async {
      final progression = Habit()
        ..id = 7
        ..name = 'Strength'
        ..habitType = 'progression'
        ..colorValue = 0xff123456
        ..createdAt = now;
      await store.put(progression);
      await show(tester, state: selected(IntentSourceType.habit));

      expect(find.text('Catat langkah'), findsOneWidget);
      await tester.tap(find.text('Catat langkah'));
      await tester.pumpAndSettle();
      expect(find.text('Catat langkah hari ini?'), findsOneWidget);
      expect(
        find.textContaining(progression.currentStep.title),
        findsNWidgets(2),
      );
      expect(await store.all<HabitEntry>(), isEmpty);

      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      final entries = await SadarRepository.store(
        store,
      ).getEntriesForDateRange('2026-11-08', '2026-11-08');
      expect(entries, hasLength(1));
      expect(entries.single.status, HabitStatus.yes);
      expect(entries.single.targetSnapshot, progression.currentStep.target);
      expect(
        (await SadarRepository.store(
          store,
        ).getHabitById(7))?.currentProgressionIndex,
        1,
      );
      expect(find.text('Batalkan langkah'), findsOneWidget);
      await tester.tap(find.text('Batalkan langkah'));
      await tester.pumpAndSettle();
      expect(find.text('Batalkan langkah hari ini?'), findsOneWidget);
      await tester.tap(find.text('Batalkan'));
      await tester.pumpAndSettle();
      expect(
        (await SadarRepository.store(
          store,
        ).getHabitById(7))?.currentProgressionIndex,
        0,
      );
      expect(
        (await SadarRepository.store(
          store,
        ).getEntriesForDateRange('2026-11-08', '2026-11-08')).single.status,
        HabitStatus.unmarked,
      );
    },
  );
}

class _Store extends FocusStore {
  final rows = <String, Map<int, Map<String, dynamic>>>{};
  final changes = StreamController<void>.broadcast();
  bool failIntent = false, failEntry = false;
  Completer<void>? gate;
  int nextId = 100;
  @override
  bool get isDurable => true;
  @override
  Future<List<T>> all<T>() async =>
      (rows[LiveModelCodec.collectionFor<T>()]?.values ?? [])
          .map(
            (e) => LiveModelCodec.decode<T>(
              jsonDecode(jsonEncode(e)) as Map<String, dynamic>,
            ),
          )
          .toList();
  @override
  Future<T?> get<T>(int id) async {
    final m = rows[LiveModelCodec.collectionFor<T>()]?[id];
    return m == null
        ? null
        : LiveModelCodec.decode<T>(
            jsonDecode(jsonEncode(m)) as Map<String, dynamic>,
          );
  }

  @override
  Future<int> put<T>(T value) async {
    final row = value as Object;
    if (row is FocusIntentDocument) {
      if (failIntent) throw StateError('write failed');
      if (gate != null) await gate!.future;
    }
    if (row is HabitEntry && failEntry) throw StateError('entry write failed');
    var id = LiveModelCodec.id(row);
    if (id < 0 || id > 9000000) {
      id = nextId++;
      LiveModelCodec.setId(row, id);
    }
    (rows[LiveModelCodec.collectionFor<T>()] ??= {})[id] =
        LiveModelCodec.encode(row);
    changes.add(null);
    return id;
  }

  @override
  Future<bool> delete<T>(int id) async =>
      rows[LiveModelCodec.collectionFor<T>()]?.remove(id) != null;
  @override
  Future<void> clear() async => rows.clear();
  @override
  Future<R> txn<R>(Future<R> Function() action) => action();
  @override
  Future<R> writeTxn<R>(Future<R> Function() action) => action();
  @override
  Stream<void> watch() async* {
    yield null;
    yield* changes.stream;
  }

  @override
  Future<void> close() => changes.close();
}
