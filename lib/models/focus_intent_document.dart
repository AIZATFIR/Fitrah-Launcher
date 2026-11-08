import 'package:isar_community/isar.dart';

part 'focus_intent_document.g.dart';

/// One transactional aggregate; its versioned payload is validated by IntentState.
@collection
class FocusIntentDocument {
  Id id = 1;
  late String payload;
}
