import 'dart:convert';

import 'package:fitrah_launcher/services/ai_provider_probe.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'probes the configured endpoint and exact model only on request',
    () async {
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

      await probe.testConnection(
        baseUrl: 'https://provider.test/custom/v1',
        model: 'vendor/model-fast',
        apiKey: 'user-secret',
      );

      expect(requests, hasLength(1));
      expect(
        requests.single.url,
        Uri.parse('https://provider.test/custom/v1/chat/completions'),
      );
      expect(requests.single.headers['authorization'], 'Bearer user-secret');
      final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect(body['model'], 'vendor/model-fast');
      expect(body['messages'], [
        {'role': 'user', 'content': 'Balas singkat: OK.'},
      ]);
      expect(body.keys, containsAll(['model', 'messages']));
    },
  );

  test('allows local compatible servers without an API key', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    http.Request? sent;
    final probe = AiProviderProbe(
      client: MockClient((request) async {
        sent = request;
        return http.Response('{"choices":[{"message":{"content":"OK"}}]}', 200);
      }),
    );
    addTearDown(probe.close);

    await probe.testConnection(
      baseUrl: 'http://192.168.1.20:11434/v1',
      model: 'llama3.2:latest',
      apiKey: '',
    );

    expect(sent!.headers, isNot(contains('authorization')));
  });

  test('never sends a configured provider key over plain HTTP', () async {
    var requestCount = 0;
    final probe = AiProviderProbe(
      client: MockClient((_) async {
        requestCount++;
        return http.Response('{"choices":[]}', 200);
      }),
    );
    addTearDown(probe.close);

    await expectLater(
      probe.testConnection(
        baseUrl: 'http://provider.test/v1',
        model: 'model',
        apiKey: 'user-secret',
      ),
      throwsA(
        isA<AiProviderProbeException>().having(
          (error) => error.message,
          'message',
          contains('HTTPS'),
        ),
      ),
    );
    expect(requestCount, 0);
  });

  test(
    'Android reports that local HTTP providers need an HTTPS endpoint',
    () async {
      var requestCount = 0;
      final probe = AiProviderProbe(
        client: MockClient((_) async {
          requestCount++;
          return http.Response('{"choices":[]}', 200);
        }),
      );
      addTearDown(probe.close);
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      await expectLater(
        probe.testConnection(
          baseUrl: 'http://192.168.1.20:11434/v1',
          model: 'llama3.2:latest',
          apiKey: '',
        ),
        throwsA(
          isA<AiProviderProbeException>().having(
            (error) => error.message,
            'message',
            contains('HTTPS'),
          ),
        ),
      );
      expect(requestCount, 0);
    },
  );

  test(
    'rejects malformed endpoint and model before making a request',
    () async {
      var requestCount = 0;
      final probe = AiProviderProbe(
        client: MockClient((_) async {
          requestCount++;
          return http.Response('', 200);
        }),
      );
      addTearDown(probe.close);

      await expectLater(
        probe.testConnection(
          baseUrl: 'file:///tmp/key',
          model: 'model',
          apiKey: 'k',
        ),
        throwsA(isA<AiProviderProbeException>()),
      );
      await expectLater(
        probe.testConnection(
          baseUrl: 'https://provider.test/v1',
          model: '',
          apiKey: 'k',
        ),
        throwsA(isA<AiProviderProbeException>()),
      );
      expect(requestCount, 0);
    },
  );

  test(
    'reports provider status without echoing the API key or response body',
    () async {
      final probe = AiProviderProbe(
        client: MockClient(
          (_) async => http.Response('user-secret leaked', 401),
        ),
      );
      addTearDown(probe.close);

      await expectLater(
        probe.testConnection(
          baseUrl: 'https://provider.test/v1',
          model: 'model',
          apiKey: 'user-secret',
        ),
        throwsA(
          isA<AiProviderProbeException>()
              .having((error) => error.message, 'message', contains('401'))
              .having(
                (error) => error.message,
                'message',
                isNot(contains('user-secret')),
              ),
        ),
      );
    },
  );

  test(
    'rejects a successful HTTP response with no usable model reply',
    () async {
      final probe = AiProviderProbe(
        client: MockClient((_) async => http.Response('{"choices":[]}', 200)),
      );
      addTearDown(probe.close);

      await expectLater(
        probe.testConnection(
          baseUrl: 'https://provider.test/v1',
          model: 'model',
          apiKey: 'user-secret',
        ),
        throwsA(isA<AiProviderProbeException>()),
      );
    },
  );
}
