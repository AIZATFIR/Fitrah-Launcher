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
    'configured provider uses its exact URL and model regardless of key prefix',
    () async {
      Uri? requestedUri;
      Map<String, dynamic>? requestedBody;
      final client = MockClient((request) async {
        requestedUri = request.url;
        requestedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'role': 'assistant', 'content': 'Provider reply'},
              },
            ],
          }),
          200,
        );
      });
      final ai = AiService(
        baseUrl: 'https://provider.test/custom/v1',
        apiKey: '',
        model: 'chosen-model-v7',
        activityRepo: ActivityRepository(null, NotificationService()),
        presetRepo: PresetRepository.store(null),
        secureStorage: _ConfiguredProviderStorage(),
        httpClient: client,
      );

      await ai.send('Hello');

      expect(
        requestedUri,
        Uri.parse('https://provider.test/custom/v1/chat/completions'),
      );
      expect(requestedBody?['model'], 'chosen-model-v7');
    },
  );

  test(
    'configured Google endpoint receives goal-first guidance and prior turns once',
    () async {
      final requests = <Map<String, dynamic>>[];
      final client = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        requests.add(body);
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'role': 'assistant',
                  'content': 'Mari pilih satu langkah kecil.',
                },
              },
            ],
          }),
          200,
        );
      });
      final ai = AiService(
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
        apiKey: '',
        model: 'test-model',
        activityRepo: ActivityRepository(null, NotificationService()),
        presetRepo: PresetRepository.store(null),
        secureStorage: _GeminiSecureStorage(),
        httpClient: client,
      );

      await ai.send('Aku ingin menang LKS nasional');
      await ai.send('Aku kewalahan dengan latihan');

      final firstContents = requests[0]['messages'] as List;
      expect(firstContents, hasLength(2));
      expect(
        (firstContents.last as Map)['content'],
        'Aku ingin menang LKS nasional',
      );
      expect(requests[0]['model'], 'test-model');
      final guidance = ((firstContents.first as Map)['content'] as String)
          .toLowerCase();
      expect(guidance, contains('dengarkan'));
      expect(guidance, contains('langkah berikutnya'));
      expect(guidance, isNot(contains('90-120 menit')));

      final followUp = requests[1]['messages'] as List;
      expect(followUp.map((item) => (item as Map)['role']).toList(), [
        'system',
        'user',
        'assistant',
        'user',
      ]);
      expect((followUp.last as Map)['content'], 'Aku kewalahan dengan latihan');
      expect(
        followUp.where(
          (item) => (item as Map)['content'] == 'Aku kewalahan dengan latihan',
        ),
        hasLength(1),
      );
    },
  );

  test(
    'configured provider returns an inert typed goal plan and keeps readable history',
    () async {
      var calls = 0;
      final requests = <Map<String, dynamic>>[];
      final client = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        requests.add(body);
        calls++;
        if (calls == 1) {
          final tools = (body['tools'] as List).cast<Map<String, dynamic>>();
          expect(
            tools.any(
              (tool) =>
                  (tool['function'] as Map)['name'] == 'propose_goal_plan',
            ),
            isTrue,
          );
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'role': 'assistant',
                    'content': 'Rencana sudah disimpan.',
                    'tool_calls': [
                      {
                        'id': 'plan-1',
                        'type': 'function',
                        'function': {
                          'name': 'propose_goal_plan',
                          'arguments': jsonEncode({
                            'goal': {
                              'title': 'Win the LKS',
                              'why': 'Practice consistently',
                              'targetDate': '2027-07-15',
                            },
                            'assumptions': ['School mornings are unavailable.'],
                            'blocks': [
                              {
                                'weekday': 1,
                                'startMinute': 1080,
                                'durationMinutes': 60,
                              },
                            ],
                          }),
                        },
                      },
                    ],
                  },
                },
              ],
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'role': 'assistant', 'content': 'Mari lanjutkan.'},
              },
            ],
          }),
          200,
        );
      });
      final activityRepo = ActivityRepository(null, NotificationService());
      final ai = AiService(
        baseUrl: 'https://provider.test/v1',
        apiKey: '',
        model: 'chosen-model',
        activityRepo: activityRepo,
        presetRepo: PresetRepository.store(null),
        secureStorage: _ConfiguredProviderStorage(),
        httpClient: client,
      );

      final reply = await ai.send(
        'Bantu susun latihan mingguan.',
        allowActions: true,
      );
      final pending = ai.pendingGoalPlan!;
      expect(reply, contains('Belum ada perubahan yang diterapkan'));
      expect(pending.proposal.goal.title, 'Win the LKS');
      expect(pending.proposal.blocks.single.startMinute, 1080);
      expect(await activityRepo.getByDate(DateTime.now()), isEmpty);

      await ai.send('Kita bisa mulai kecil?', allowActions: true);
      expect(pending.isPending, isFalse);
      final secondTurns = requests[1]['messages'] as List;
      final assistantTurns = secondTurns
          .where((turn) => (turn as Map)['role'] == 'assistant')
          .cast<Map>()
          .toList();
      expect(assistantTurns.last['content'], contains('Belum ada perubahan'));
      expect(secondTurns.map((turn) => (turn as Map)['role']).toList(), [
        'system',
        'user',
        'assistant',
        'tool',
        'assistant',
        'user',
      ]);
    },
  );

  test(
    'malformed structured goal output creates no pending proposal',
    () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'role': 'assistant',
                  'content': null,
                  'tool_calls': [
                    {
                      'id': 'plan-bad',
                      'type': 'function',
                      'function': {
                        'name': 'propose_goal_plan',
                        'arguments': '{not valid json',
                      },
                    },
                  ],
                },
              },
            ],
          }),
          200,
        ),
      );
      final ai = AiService(
        baseUrl: 'https://provider.test/v1',
        apiKey: '',
        model: 'chosen-model',
        activityRepo: ActivityRepository(null, NotificationService()),
        presetRepo: PresetRepository.store(null),
        secureStorage: _ConfiguredProviderStorage(),
        httpClient: client,
      );

      final reply = await ai.send('Buat rencana latihan.', allowActions: true);
      expect(reply, contains('belum bisa dibaca'));
      expect(ai.pendingGoalPlan, isNull);
      expect(ai.pendingActions, isEmpty);
    },
  );

  test('Gemini history preserves tool calls and their results', () async {
    final geminiRequests = <Map<String, dynamic>>[];
    final client = MockClient((request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      if (request.url.host == 'generativelanguage.googleapis.com') {
        geminiRequests.add(body);
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'role': 'assistant',
                  'content': 'Kita bisa mulai dari satu langkah.',
                },
              },
            ],
          }),
          200,
        );
      }
      final messages = body['messages'] as List;
      if (messages.any((message) => (message as Map)['role'] == 'tool')) {
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'role': 'assistant', 'content': 'Jadwalmu kosong.'},
              },
            ],
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {
                'role': 'assistant',
                'content': null,
                'tool_calls': [
                  {
                    'id': 'call-list',
                    'type': 'function',
                    'function': {'name': 'list_activities', 'arguments': '{}'},
                  },
                ],
              },
            },
          ],
        }),
        200,
      );
    });
    final storage = _SwitchableGeminiStorage();
    final ai = AiService(
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
      apiKey: '',
      model: 'test-model',
      activityRepo: ActivityRepository(null, NotificationService()),
      presetRepo: PresetRepository.store(null),
      secureStorage: storage,
      httpClient: client,
    );

    await ai.send('Lihat jadwalku', allowActions: true);
    storage.useGemini = true;
    await ai.send('Aku perlu langkah berikutnya');

    final turns = geminiRequests.single['messages'] as List;
    expect(turns.map((turn) => (turn as Map)['role']).toList(), [
      'system',
      'user',
      'assistant',
      'tool',
      'assistant',
      'user',
    ]);
    expect((turns[2] as Map)['tool_calls'], isA<List>());
    expect((turns[3] as Map)['content'], contains('activities'));
    expect((turns[4] as Map)['content'], 'Jadwalmu kosong.');
    expect((turns.last as Map)['content'], 'Aku perlu langkah berikutnya');
  });

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
        'create_activity' => {
          'title': 'Belajar LKS',
          'date': date.toIso8601String().substring(0, 10),
          'start_hour': 23,
          'duration_minutes': 30,
        },
        'update_activity' => {
          'id': targetActivityId,
          'title': 'Judul baru',
          'start_hour': 22,
          'duration_minutes': 30,
        },
        _ => {
          'goal_title': 'LKS',
          'target_date': date
              .add(const Duration(days: 60))
              .toIso8601String()
              .substring(0, 10),
          'daily_hours': 2,
        },
      };
      return http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {
                'role': 'assistant',
                'content': 'Jadwal sudah aku terapkan.',
                'tool_calls': [
                  {
                    'id': 'call-1',
                    'type': 'function',
                    'function': {
                      'name': toolToReturn,
                      'arguments': jsonEncode(arguments),
                    },
                  },
                ],
              },
            },
          ],
        }),
        200,
      );
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

    final reply = await ai.send(
      'Jadwalkan belajar LKS malam ini',
      allowActions: true,
    );
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
    expect(
      await activityRepo.getByDate(DateTime(date.year, date.month, date.day)),
      isEmpty,
    );

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
    final readOnlyReply = await ai.send(
      'Buat jadwal belajar',
      allowActions: false,
    );
    expect(advertisedTools, isNot(contains('create_activity')));
    expect(ai.pendingActions, isEmpty);
    expect(readOnlyReply, contains('tidak ada perubahan jadwal diterapkan'));
    expect(
      await activityRepo.getByDate(DateTime(date.year, date.month, date.day)),
      hasLength(2),
    );
  });

  test(
    'chat does not repeat a model claim that a schedule was applied',
    () async {
      final ai = AiService(
        baseUrl: 'https://model.test/v1',
        apiKey: '',
        model: 'test-model',
        activityRepo: ActivityRepository(null, NotificationService()),
        presetRepo: PresetRepository.store(null),
        secureStorage: _ReadOnlyBackendStorage(),
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode({'reply': 'Jadwal sudah aku terapkan.'}),
            200,
          ),
        ),
      );

      final reply = await ai.send('Atur jadwal belajarku', allowActions: true);

      expect(reply, isNot(contains('Jadwal sudah aku terapkan')));
      expect(reply, contains('Belum ada perubahan jadwal diterapkan'));
    },
  );

  test(
    'chat guards natural claims that an activity was already created',
    () async {
      final ai = AiService(
        baseUrl: 'https://model.test/v1',
        apiKey: '',
        model: 'test-model',
        activityRepo: ActivityRepository(null, NotificationService()),
        presetRepo: PresetRepository.store(null),
        secureStorage: _ReadOnlyBackendStorage(),
        httpClient: MockClient(
          (request) async => http.Response.bytes(
            utf8.encode(
              jsonEncode({'reply': 'Berhasil, sudah aku buat “Belajar LKS”.'}),
            ),
            200,
          ),
        ),
      );

      final reply = await ai.send(
        'Buat jadwal belajar LKS',
        allowActions: true,
      );

      expect(reply, isNot(contains('Berhasil, sudah aku buat')));
      expect(reply, contains('Belum ada perubahan jadwal diterapkan'));
    },
  );
}

class _TestSecureStorage extends SecureStorageService {
  _TestSecureStorage() : super(storage: const FlutterSecureStorage());

  @override
  Future<String?> getGeminiApiKey() async => null;
  @override
  Future<String?> getAiProviderApiKey() async => null;
  @override
  Future<String> getBackendServerUrl() async => 'http://model.test';
  @override
  Future<String?> getOpenRouterKey() async => 'test-openrouter-key';
}

class _GeminiSecureStorage extends SecureStorageService {
  _GeminiSecureStorage() : super(storage: const FlutterSecureStorage());

  @override
  Future<String?> getGeminiApiKey() async => 'AIza-test-key';
  @override
  Future<String?> getAiProviderApiKey() async => 'AIza-test-key';
  @override
  Future<String> getBackendServerUrl() async => 'http://model.test';
  @override
  Future<String?> getOpenRouterKey() async => null;
}

class _ConfiguredProviderStorage extends SecureStorageService {
  _ConfiguredProviderStorage() : super(storage: const FlutterSecureStorage());

  @override
  Future<String?> getGeminiApiKey() async => null;
  @override
  Future<String?> getAiProviderApiKey() async => 'sk-custom-provider-key';
  @override
  Future<String> getBackendServerUrl() async => 'http://model.test';
  @override
  Future<String?> getOpenRouterKey() async => null;
}

class _SwitchableGeminiStorage extends SecureStorageService {
  _SwitchableGeminiStorage() : super(storage: const FlutterSecureStorage());

  bool useGemini = false;

  @override
  Future<String?> getGeminiApiKey() async => useGemini ? 'AIza-test-key' : null;
  @override
  Future<String?> getAiProviderApiKey() async =>
      useGemini ? 'AIza-test-key' : null;
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
  Future<String?> getAiProviderApiKey() async => null;
  @override
  Future<String> getBackendServerUrl() async => 'http://model.test';
  @override
  Future<String?> getOpenRouterKey() async => null;
}
