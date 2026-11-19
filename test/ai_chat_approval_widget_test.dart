import 'dart:convert';

import 'package:fitrah_launcher/data/repositories/activity_repository.dart';
import 'package:fitrah_launcher/data/repositories/preset_repository.dart';
import 'package:fitrah_launcher/features/ai_chat/ai_chat_sheet.dart';
import 'package:fitrah_launcher/providers/providers.dart';
import 'package:fitrah_launcher/services/ai_service.dart';
import 'package:fitrah_launcher/services/notification_service.dart';
import 'package:fitrah_launcher/services/secure_storage_service.dart';
import 'package:fitrah_launcher/services/voice_assistant_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('goal-first chat includes the selected goal with free-form chat', (
    tester,
  ) async {
    var requestCount = 0;
    Map<String, dynamic>? requestBody;
    var openedAiSettings = false;
    final activities = ActivityRepository(null, NotificationService());
    final ai = AiService(
      baseUrl: 'https://model.test/v1',
      apiKey: 'test-key',
      model: 'test-model',
      activityRepo: activities,
      presetRepo: PresetRepository.store(null),
      secureStorage: _TestSecureStorage(),
      httpClient: MockClient((request) async {
        requestCount++;
        requestBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'role': 'assistant',
                  'content': 'Kita mulai dari satu langkah kecil.',
                },
              },
            ],
          }),
          200,
        );
      }),
    );
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiServiceProvider.overrideWithValue(ai),
          voiceAssistantServiceProvider.overrideWithValue(
            _SilentVoiceAssistant(),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 700,
              child: AiChatPanel(
                initialGoal: 'Menang LKS Nasional IT Software Solution',
                onOpenAiSettings: () => openedAiSettings = true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Tujuanmu: Menang LKS Nasional IT Software Solution'),
      findsOneWidget,
    );
    expect(find.text('Bantu aku menyusun langkah'), findsOneWidget);
    expect(requestCount, 0);
    expect(find.text('Atur provider & API key'), findsOneWidget);
    await tester.tap(find.text('Atur provider & API key'));
    expect(openedAiSettings, isTrue);
    await tester.enterText(
      find.byType(TextField),
      'Apa langkah kecil hari ini?',
    );
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(requestCount, 1);
    final messages = requestBody!['messages'] as List;
    final providerTurn = messages.last as Map<String, dynamic>;
    expect(
      providerTurn['content'],
      contains('Menang LKS Nasional IT Software Solution'),
    );
    expect(providerTurn['content'], contains('Apa langkah kecil hari ini?'));
    expect(find.text('Apa langkah kecil hari ini?'), findsOneWidget);
    expect(
      find.textContaining('Menang LKS Nasional IT Software Solution'),
      findsNothing,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('AI settings stay reachable after a conversation has messages', (
    tester,
  ) async {
    var openedAiSettings = false;
    final ai = AiService(
      baseUrl: 'https://model.test/v1',
      apiKey: 'test-key',
      model: 'test-model',
      activityRepo: ActivityRepository(null, NotificationService()),
      presetRepo: PresetRepository.store(null),
      secureStorage: _TestSecureStorage(),
      httpClient: MockClient((_) async => http.Response('{}', 200)),
    );
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiServiceProvider.overrideWithValue(ai),
          aiTranscriptProvider.overrideWith(
            (ref) => [
              ChatMessage(role: 'user', text: 'Aku ingin menang LKS.'),
              ChatMessage(
                role: 'model',
                text: 'Belum bisa tersambung. Coba lagi sebentar.',
              ),
            ],
          ),
          voiceAssistantServiceProvider.overrideWithValue(
            _SilentVoiceAssistant(),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 700,
              child: AiChatPanel(
                onOpenAiSettings: () => openedAiSettings = true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Belum bisa tersambung. Coba lagi sebentar.'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Pengaturan AI'));
    expect(openedAiSettings, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('small chat panel lets the user cancel or apply a reviewed block', (
    tester,
  ) async {
    final date = DateTime.now();
    final activities = ActivityRepository(null, NotificationService());
    final ai = AiService(
      baseUrl: 'https://model.test/v1',
      apiKey: 'test-key',
      model: 'test-model',
      activityRepo: activities,
      presetRepo: PresetRepository.store(null),
      secureStorage: _TestSecureStorage(),
      httpClient: MockClient((request) async {
        if (request.url.path == '/api/chat/secretary') {
          return http.Response('{}', 503);
        }
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'role': 'assistant',
                  'tool_calls': [
                    {
                      'id': 'call-1',
                      'type': 'function',
                      'function': {
                        'name': 'create_activity',
                        'arguments': jsonEncode({
                          'title': 'Belajar LKS',
                          'date': date.toIso8601String().substring(0, 10),
                          'start_hour': 19,
                          'duration_minutes': 30,
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
      }),
    );
    final voice = _SilentVoiceAssistant();
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiServiceProvider.overrideWithValue(ai),
          voiceAssistantServiceProvider.overrideWithValue(voice),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1)),
            child: child!,
          ),
          home: const Scaffold(body: AiChatPanel()),
        ),
      ),
    );

    Future<void> requestChange() async {
      await tester.enterText(find.byType(TextField), 'Jadwalkan belajar LKS');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();
    }

    void expectNoFrameworkError() {
      final error = tester.takeException();
      final details = error is FlutterError
          ? error.diagnostics
                .map((diagnostic) => diagnostic.toString())
                .join('\n')
          : error?.toString();
      expect(error, isNull, reason: details);
    }

    await requestChange();
    // Keep proposal wiring under test independently from the rendered card copy.
    expect(
      ai.pendingActions,
      hasLength(1),
      reason: ai.pendingActions.toString(),
    );
    expect(find.textContaining('Belajar LKS'), findsOneWidget);
    expect(find.text('Perubahan menunggu persetujuan'), findsOneWidget);
    expect(find.text('Terapkan'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
    expect(
      await activities.getByDate(DateTime(date.year, date.month, date.day)),
      isEmpty,
    );
    expectNoFrameworkError();

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.text('Perubahan dibatalkan'), findsOneWidget);
    expect(
      await activities.getByDate(DateTime(date.year, date.month, date.day)),
      isEmpty,
    );
    expectNoFrameworkError();

    await requestChange();
    await tester.tap(find.text('Terapkan'));
    await tester.pumpAndSettle();

    expect(find.text('Diterapkan'), findsOneWidget);
    expect(
      await activities.getByDate(DateTime(date.year, date.month, date.day)),
      hasLength(1),
    );
    expectNoFrameworkError();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _TestSecureStorage extends SecureStorageService {
  _TestSecureStorage() : super(storage: const FlutterSecureStorage());

  @override
  Future<String?> getAiProviderApiKey() async => 'test-key';

  @override
  Future<String?> getGeminiApiKey() async => null;
  @override
  Future<String> getBackendServerUrl() async => 'http://model.test';
  @override
  Future<String?> getOpenRouterKey() async => 'test-openrouter-key';
}

class _SilentVoiceAssistant extends Fake implements VoiceAssistantService {
  @override
  final isListening = ValueNotifier(false);
  @override
  final isSpeaking = ValueNotifier(false);

  @override
  Future<void> speak(String text) async {}
  @override
  Future<void> stopSpeaking() async {}
}
