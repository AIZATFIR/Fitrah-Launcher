import '../../models/app_settings.dart';
import 'browser_focus_store.dart';
import 'focus_store.dart';

Future<FocusStore> openFocusStore() async {
  final store = await BrowserFocusStore.open();
  try {
    await store.writeTxn(() async {
      if (await store.get<AppSettings>(0) == null) {
        await store.put(AppSettings());
      }
    });
    return store;
  } catch (_) {
    await store.close();
    rethrow;
  }
}
