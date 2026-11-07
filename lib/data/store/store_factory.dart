import 'focus_store.dart';
import 'store_factory_native.dart'
    if (dart.library.js_interop) 'store_factory_web.dart'
    as platform;

Future<FocusStore> openFocusStore() => platform.openFocusStore();
