import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fitrah_launcher/services/ai_action_proposal.dart';
import 'package:fitrah_launcher/data/repositories/activity_repository.dart';
import 'package:fitrah_launcher/data/repositories/preset_repository.dart';
import 'package:fitrah_launcher/services/ai_service.dart';
import 'package:fitrah_launcher/services/notification_service.dart';
import 'package:fitrah_launcher/services/secure_storage_service.dart';
import 'package:fitrah_launcher/models/activity.dart';
import 'package:fitrah_launcher/core/time_math.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'a proposed action stays unapplied until the user approves it',
    () async {
      var writes = 0;
      final proposal = AiActionProposal(
        name: 'create_activity',
        summary: 'Belajar LKS',
        arguments: const {'title': 'Belajar LKS'},
        apply: () async => writes++,
      );

      expect(writes, 0);
      expect(proposal.isPending, isTrue);

      await proposal.approve();

      expect(writes, 1);
      expect(proposal.isPending, isFalse);
      expect(proposal.isApplied, isTrue);
    },
  );

  test('a dismissed proposal cannot later be applied', () async {
    var writes = 0;
    final proposal = AiActionProposal(
      name: 'delete_activity',
      summary: 'Hapus aktivitas #7',
      arguments: const {'id': 7},
      apply: () async => writes++,
    );

    proposal.dismiss();
    await proposal.approve();

    expect(writes, 0);
    expect(proposal.isPending, isFalse);
    expect(proposal.isApplied, isFalse);
  });

  test('a failed approval stays pending and a retry is allowed', () async {
    var attempts = 0;
    final proposal = AiActionProposal(
      name: 'create_activity',
      summary: 'Belajar LKS',
      arguments: const {'title': 'Belajar LKS'},
      apply: () async {
        attempts++;
        if (attempts == 1) throw StateError('conflict');
        return {'success': true};
      },
    );

    await expectLater(proposal.approve(), throwsStateError);
    expect(proposal.isPending, isTrue);

    await proposal.approve();

    expect(attempts, 2);
    expect(proposal.isApplied, isTrue);
  });

  test('AI activity tool remains a proposal until approved', () async {
    final date = DateTime.now();
    final activityRepo = ActivityRepository(null, NotificationService());
    var advertisedTools = <String>[];
    var toolToReturn = 'create_activity';
    var targetActivityId = 0;
    final client = MockClient((request) async {
      if (request.url.path == '/api/chat/secretary') {
        return http.Response('{}', 503);
      }
      final payload = jsonDecode(request.body) as Map<String, dynamic>;
      advertisedTools = (payload['tools'] as List)
          .map((tool) => (tool as Map)['function'] as Map)
          .map((function) => function['name'] as String)
          .toList();
      final arguments = switch (toolToReturn) {
        'create_activity' => {'title': 'Belajar LKS', 'date': date.toIso8601String().substring(0, 10), 'start_hour': 23, 'duration_minutes': 30},
        'update_activity' => {'id': targetActivityId, 'title': 'Judul baru', 'start_hour': 22, 'duration_minutes': 30},
        _ => {'goal_title': 'LKS', 'target_date': date.add(const Duration(days: 60)).toIso8601String().substring(0, 10), 'daily_hours': 2},
      };
      return http.Response(jsonEncode({
        'choices': [{'message': {
          'role': 'assistant', 'content': 'Jadwal sudah aku terapkan.',
          'tool_calls': [{'id': 'call-1', 'type': 'function', 'function': {
            'name': toolToReturn, 'arguments': jsonEncode(arguments),
          }}],
        }}],
      }), 200);
    });
    final ai = AiService(
      baseUrl: 'https://model.test/v1',
      apiKey: 'test-key',
      model: 'test-model',
      activityRepo: activityRepo,
      presetRepo: PresetRepository.store(null),
      secureStorage: _TestSecureStorage(),
      httpClient: client,
    );

    final reply = await ai.send('Jadwalkan belajar LKS malam ini', allowActions: true);
    expect(reply, contains('Belum ada perubahan yang diterapkan'));
    expect(reply, isNot(contains('Jadwal sudah aku terapkan')));
    expect(advertisedTools, isNot(contains('generate_blueprint')));
    expect(advertisedTools, isNot(contains('schedule_adaptive_goal')));
    expect(
      await activityRepo.getByDate(DateTime(date.year, date.month, date.day)),
      isEmpty,
    );
    expect(ai.pendingActions, hasLength(1));
    expect(ai.pendingActions.single.summary, contains('30 menit'));
    expect(ai.pendingActions.single.summary, contains('Belajar LKS'));

    final staleProposal = ai.pendingActions.single;
    await ai.send('Gimana jadwalnya?', allowActions: true);
    expect(staleProposal.isPending, isFalse);
    await staleProposal.approve();
    expect(await activityRepo.getByDate(DateTime(date.year, date.month, date.day)), isEmpty);

    ai.reset();
    await ai.send('Jadwalkan belajar LKS malam ini', allowActions: true);
    await ai.pendingActions.single.approve();

    final activities = await activityRepo.getByDate(
      DateTime(date.year, date.month, date.day),
    );
    expect(activities, hasLength(1));
    expect(activities.single.title, 'Belajar LKS');

    final conflict = Activity()
      ..title = 'Komitmen lama'
      ..date = DateTime(date.year, date.month, date.day)
      ..ampmHalf = AmPmHalf.pm
      ..startMinute = 10 * 60
      ..endMinute = 11 * 60
      ..colorValue = 0xFFFFFFFF
      ..createdAt = date
      ..updatedAt = date;
    await activityRepo.upsert(conflict);
    targetActivityId = activities.single.id;
    toolToReturn = 'update_activity';
    ai.reset();
    await ai.send('Pindah dan ganti nama jadwal LKS', allowActions: true);
    await expectLater(ai.pendingActions.single.approve(), throwsStateError);
    final unchanged = await activityRepo.get(targetActivityId);
    expect(unchanged?.title, 'Belajar LKS');

    toolToReturn = 'schedule_adaptive_goal';
    ai.reset();
    final bulkReply = await ai.send('Buatkan jadwal latihan LKS');
    expect(ai.pendingActions, isEmpty);
    expect(bulkReply, contains('belum dapat diterapkan'));

    toolToReturn = 'create_activity';
    ai.reset();
    final readOnlyReply = await ai.send('Buat jadwal belajar', allowActions: false);
    expect(advertisedTools, isNot(contains('create_activity')));
    expect(ai.pendingActions, isEmpty);
    expect(readOnlyReply, contains('tidak ada perubahan jadwal diterapkan'));
    expect(await activityRepo.getByDate(DateTime(date.year, date.month, date.day)), hasLength(2));
  });

  test('chat does not repeat a model claim that a schedule was applied', () async {
    final ai = AiService(
      baseUrl: 'https://model.test/v1',
      apiKey: '',
      model: 'test-model',
      activityRepo: ActivityRepository(null, NotificationService()),
      presetRepo: PresetRepository.store(null),
      secureStorage: _ReadOnlyBackendStorage(),
      httpClient: MockClient((request) async => http.Response(
        jsonEncode({'reply': 'Jadwal sudah aku terapkan.'}),
        200,
      )),
    );

    final reply = await ai.send('Atur jadwal belajarku', allowActions: true);

    expect(reply, isNot(contains('Jadwal sudah aku terapkan')));
    expect(reply, contains('Belum ada perubahan jadwal diterapkan'));
  });

  test('chat guards natural claims that an activity was already created', () async {
    final ai = AiService(
      baseUrl: 'https://model.test/v1',
      apiKey: '',
      model: 'test-model',
      activityRepo: ActivityRepository(null, NotificationService()),
      presetRepo: PresetRepository.store(null),
      secureStorage: _ReadOnlyBackendStorage(),
      httpClient: MockClient((request) async => http.Response.bytes(
        utf8.encode(jsonEncode({'reply': 'Berhasil, sudah aku buat “Belajar LKS”.'})),
        200,
      )),
    );

    final reply = await ai.send('Buat jadwal belajar LKS', allowActions: true);

    expect(reply, isNot(contains('Berhasil, sudah aku buat')));
    expect(reply, contains('Belum ada perubahan jadwal diterapkan'));
  });
}

class _TestSecureStorage extends SecureStorageService {
  _TestSecureStorage() : super(storage: const FlutterSecureStorage());

  @override
  Future<String?> getGeminiApiKey() async => null;
  @override
  Future<String> getBackendServerUrl() async => 'http://model.test';
  @override
  Future<String?> getOpenRouterKey() async => 'test-openrouter-key';
}

class _ReadOnlyBackendStorage extends SecureStorageService {
  _ReadOnlyBackendStorage() : super(storage: const FlutterSecureStorage());

  @override
  Future<String?> getGeminiApiKey() async => null;
  @override
  Future<String> getBackendServerUrl() async => 'http://model.test';
  @override
  Future<String?> getOpenRouterKey() async => null;
}
