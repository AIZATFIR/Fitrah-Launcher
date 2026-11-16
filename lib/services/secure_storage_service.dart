import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _keyGeminiApiKey = 'gemini_api_key';
  static const _keyOpenRouterKey = 'openrouter_api_key';
  static const _keyAiProviderApiKey = 'ai_provider_api_key';
  static const _keyBackendUrl = 'backend_server_url';
  static const _keyVoiceEnabled = 'voice_enabled';

  /// Default local backend server URL for openrouter fallback
  static const defaultBackendUrl = 'http://localhost:3000';

  // ── Gemini API Key (BYOK) ──────────────────────────────────────────────────
  Future<String?> getGeminiApiKey() async {
    return await _storage.read(key: _keyGeminiApiKey);
  }

  Future<void> setGeminiApiKey(String? key) async {
    if (key == null || key.trim().isEmpty) {
      await _storage.delete(key: _keyGeminiApiKey);
    } else {
      await _storage.write(key: _keyGeminiApiKey, value: key.trim());
    }
  }

  // ── OpenRouter Key (Optional fallback) ────────────────────────────────────
  Future<String?> getOpenRouterKey() async {
    return await _storage.read(key: _keyOpenRouterKey);
  }

  Future<void> setOpenRouterKey(String? key) async {
    if (key == null || key.trim().isEmpty) {
      await _storage.delete(key: _keyOpenRouterKey);
    } else {
      await _storage.write(key: _keyOpenRouterKey, value: key.trim());
    }
  }

  /// Current credential shared by all OpenAI-compatible and Gemini providers.
  Future<String?> getAiProviderApiKey() async {
    for (final key in [
      _keyAiProviderApiKey,
      _keyGeminiApiKey,
      _keyOpenRouterKey,
    ]) {
      final value = await _storage.read(key: key);
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  /// Moves an existing credential to the unified entry before removing old
  /// secure-storage copies. A failed write leaves every legacy copy intact.
  Future<String?> migrateAiProviderApiKey({
    String? legacyAppSettingsKey,
  }) async {
    final current = await _storage.read(key: _keyAiProviderApiKey);
    if (current != null && current.trim().isNotEmpty) return current.trim();

    final gemini = await _storage.read(key: _keyGeminiApiKey);
    final openRouter = await _storage.read(key: _keyOpenRouterKey);
    final value = [gemini, openRouter, legacyAppSettingsKey]
        .whereType<String>()
        .map((entry) => entry.trim())
        .firstWhere((entry) => entry.isNotEmpty, orElse: () => '');
    if (value.isEmpty) return null;

    await _storage.write(key: _keyAiProviderApiKey, value: value);
    await _deleteLegacyAiKeys();
    return value;
  }

  /// Persists a configured provider key before clearing any compatibility copy.
  Future<void> setAiProviderApiKey(String? key) async {
    final value = key?.trim() ?? '';
    if (value.isEmpty) {
      await _storage.delete(key: _keyAiProviderApiKey);
      await _deleteLegacyAiKeys();
      return;
    }
    await _storage.write(key: _keyAiProviderApiKey, value: value);
    await _deleteLegacyAiKeys();
  }

  Future<void> _deleteLegacyAiKeys() async {
    await _storage.delete(key: _keyGeminiApiKey);
    await _storage.delete(key: _keyOpenRouterKey);
  }

  // ── Backend Server URL ─────────────────────────────────────────────────────
  Future<String> getBackendServerUrl() async {
    final url = await _storage.read(key: _keyBackendUrl);
    return (url != null && url.trim().isNotEmpty)
        ? url.trim()
        : defaultBackendUrl;
  }

  Future<void> setBackendServerUrl(String? url) async {
    if (url == null || url.trim().isEmpty) {
      await _storage.delete(key: _keyBackendUrl);
    } else {
      await _storage.write(key: _keyBackendUrl, value: url.trim());
    }
  }

  // ── Voice Output Enabled ───────────────────────────────────────────────────
  Future<bool> isVoiceEnabled() async {
    final val = await _storage.read(key: _keyVoiceEnabled);
    return val != 'false'; // Enabled by default
  }

  Future<void> setVoiceEnabled(bool enabled) async {
    await _storage.write(key: _keyVoiceEnabled, value: enabled.toString());
  }

  // ── Sadar Onboarding State ───────────────────────────────────────────────
  static const _keySadarOnboarding = 'sadar_onboarding_completed';

  Future<bool> isSadarOnboardingDone() async {
    final val = await _storage.read(key: _keySadarOnboarding);
    return val == 'true';
  }

  Future<void> setSadarOnboardingDone(bool done) async {
    await _storage.write(key: _keySadarOnboarding, value: done.toString());
  }

  // ── Generic Custom Key-Value Storage ──────────────────────────────────────
  Future<String?> readCustomKey(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> writeCustomKey(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<void> deleteCustomKey(String key) async {
    await _storage.delete(key: key);
  }

  /// Clear all stored secure credentials
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
