import 'dart:convert';

import 'package:fitrah_launcher/models/app_settings.dart';
import 'package:fitrah_launcher/providers/providers.dart';
import 'package:fitrah_launcher/services/ai_provider_probe.dart';
import 'package:fitrah_launcher/services/secure_storage_service.dart';
import 'package:fitrah_launcher/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('AI settings only probe on tap and label saved key honestly', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final requests = <http.Request>[];
    final probe = AiProviderProbe(
      client: MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': 'OK'},
              },
            ],
          }),
          200,
        );
      }),
    );
    addTearDown(probe.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith((ref) => Stream.value(AppSettings())),
          secureStorageServiceProvider.overrideWithValue(_ProviderStorage()),
          aiProviderProbeProvider.overrideWithValue(probe),
        ],
        child: const MaterialApp(
          home: SettingsScreen(focusAiConfiguration: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('API key tersimpan'), findsOneWidget);
    expect(find.text('Connected'), findsNothing);
    expect(requests, isEmpty);

    final testButton = find.text('Uji koneksi');
    await tester.ensureVisible(testButton);
    await tester.tap(testButton);
    await tester.pumpAndSettle();

    expect(requests, hasLength(1));
    expect(requests.single.url.path, '/v1beta/openai/chat/completions');
    expect(requests.single.headers['authorization'], 'Bearer saved-key');
    final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
    expect(body['model'], 'gemini-2.5-flash');
    expect(find.text('Koneksi berhasil · gemini-2.5-flash'), findsOneWidget);
  });
}

class _ProviderStorage extends SecureStorageService {
  @override
  Future<String?> migrateAiProviderApiKey({
    String? legacyAppSettingsKey,
  }) async => 'saved-key';

  @override
  Future<bool> isVoiceEnabled() async => false;

  @override
  Future<void> setVoiceEnabled(bool enabled) async {}
}
