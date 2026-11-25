import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AiProviderProbeException implements Exception {
  const AiProviderProbeException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Sends a small user-requested chat completion to validate the configured
/// OpenAI-compatible provider, endpoint, credential, and model together.
class AiProviderProbe {
  AiProviderProbe({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  static Uri chatCompletionsUri(String baseUrl, {String apiKey = ''}) {
    final parsed = Uri.tryParse(baseUrl.trim());
    if (parsed == null ||
        (parsed.scheme != 'https' && parsed.scheme != 'http') ||
        parsed.host.isEmpty ||
        parsed.userInfo.isNotEmpty ||
        parsed.hasQuery ||
        parsed.hasFragment) {
      throw const AiProviderProbeException(
        'Base URL harus berupa alamat HTTP(S) provider yang valid.',
      );
    }
    if (parsed.scheme == 'http' && apiKey.trim().isNotEmpty) {
      throw const AiProviderProbeException(
        'API key tidak akan dikirim lewat HTTP. Gunakan endpoint HTTPS.',
      );
    }
    if (parsed.scheme == 'http' &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android) {
      throw const AiProviderProbeException(
        'Android memerlukan endpoint HTTPS. Ollama di komputer perlu alamat HTTPS yang bisa dijangkau HP.',
      );
    }
    final basePath = parsed.path.replaceFirst(RegExp(r'/+$'), '');
    return parsed.replace(path: '$basePath/chat/completions');
  }

  Future<void> testConnection({
    required String baseUrl,
    required String model,
    required String apiKey,
  }) async {
    final trimmedModel = model.trim();
    if (trimmedModel.isEmpty) {
      throw const AiProviderProbeException('Isi nama model terlebih dahulu.');
    }
    final key = apiKey.trim();
    final uri = chatCompletionsUri(baseUrl, apiKey: key);

    late final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if (key.isNotEmpty) 'Authorization': 'Bearer $key',
            },
            body: jsonEncode({
              'model': trimmedModel,
              'messages': [
                {'role': 'user', 'content': 'Balas singkat: OK.'},
              ],
            }),
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const AiProviderProbeException(
        'Provider belum menjawab dalam 20 detik. Periksa jaringan dan alamat provider.',
      );
    } on AiProviderProbeException {
      rethrow;
    } on Exception {
      throw const AiProviderProbeException(
        'Tidak dapat menghubungi provider. Periksa Base URL dan jaringan.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = switch (response.statusCode) {
        401 || 403 => 'API key ditolak',
        404 => 'Endpoint atau model tidak ditemukan',
        429 => 'Batas permintaan provider tercapai',
        _ => 'Provider menolak permintaan',
      };
      throw AiProviderProbeException('$message (HTTP ${response.statusCode}).');
    }

    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const AiProviderProbeException(
        'Provider menjawab dengan format yang tidak dikenali.',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const AiProviderProbeException(
        'Provider menjawab dengan format yang tidak dikenali.',
      );
    }
    final choices = decoded['choices'];
    final first = choices is List && choices.isNotEmpty ? choices.first : null;
    final message = first is Map ? first['message'] : null;
    final content = message is Map ? message['content'] : null;
    final hasReply = content is String && content.trim().isNotEmpty;
    if (!hasReply) {
      throw const AiProviderProbeException(
        'Provider merespons, tetapi model tidak mengembalikan jawaban. Periksa nama model.',
      );
    }
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}
