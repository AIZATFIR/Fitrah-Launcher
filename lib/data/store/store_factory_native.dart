import '../isar_service.dart';
import 'focus_store.dart';
import 'native_focus_store.dart';

Future<FocusStore> openFocusStore() async =>
    NativeFocusStore((await IsarService.open()).isar!);
