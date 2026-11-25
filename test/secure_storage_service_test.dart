// ignore_for_file: depend_on_referenced_packages

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:fitrah_launcher/services/secure_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'unified provider key prefers its value then falls back to legacy keys',
    () async {
      final original = FlutterSecureStoragePlatform.instance;
      final values = <String, String>{'gemini_api_key': 'AIza-legacy'};
      FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
        values,
      );
      addTearDown(() => FlutterSecureStoragePlatform.instance = original);
      final service = SecureStorageService();

      expect(await service.getAiProviderApiKey(), 'AIza-legacy');
      values['ai_provider_api_key'] = 'sk-unified';
      expect(await service.getAiProviderApiKey(), 'sk-unified');
    },
  );

  test(
    'legacy secure key is migrated and removed only after unified write',
    () async {
      final original = FlutterSecureStoragePlatform.instance;
      final values = <String, String>{'openrouter_api_key': 'sk-or-legacy'};
      FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
        values,
      );
      addTearDown(() => FlutterSecureStoragePlatform.instance = original);
      final service = SecureStorageService();

      expect(await service.migrateAiProviderApiKey(), 'sk-or-legacy');
      expect(values['ai_provider_api_key'], 'sk-or-legacy');
      expect(values.containsKey('openrouter_api_key'), isFalse);
    },
  );

  test(
    'legacy AppSettings key is copied into secure storage for migration',
    () async {
      final original = FlutterSecureStoragePlatform.instance;
      final values = <String, String>{};
      FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
        values,
      );
      addTearDown(() => FlutterSecureStoragePlatform.instance = original);
      final service = SecureStorageService();

      expect(
        await service.migrateAiProviderApiKey(
          legacyAppSettingsKey: 'legacy-db-secret',
        ),
        'legacy-db-secret',
      );
      expect(values['ai_provider_api_key'], 'legacy-db-secret');
    },
  );

  test('failed unified write preserves the only legacy credential', () async {
    final original = FlutterSecureStoragePlatform.instance;
    final values = <String, String>{'gemini_api_key': 'AIza-legacy'};
    FlutterSecureStoragePlatform.instance = _FailingWriteStorage(values);
    addTearDown(() => FlutterSecureStoragePlatform.instance = original);
    final service = SecureStorageService();

    await expectLater(service.migrateAiProviderApiKey(), throwsStateError);
    expect(values['gemini_api_key'], 'AIza-legacy');
    expect(values.containsKey('ai_provider_api_key'), isFalse);
  });
}

class _FailingWriteStorage extends TestFlutterSecureStoragePlatform {
  _FailingWriteStorage(super.data);

  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) async {
    throw StateError('simulated secure-storage write failure');
  }
}
