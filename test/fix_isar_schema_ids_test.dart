import 'package:flutter_test/flutter_test.dart';
import '../tool/fix_isar_schema_ids.dart';

void main() {
  test('splits wide signed schema ids into JavaScript-safe constants', () {
    final source = '''
      id: 5438919079352502174,
      id: -4242304331580288944,
      id: 4727396763174827,
    ''';

    expect(transformSchemaIds(source), '''
      id: 543891907935250 * 10000 + 2174,
      id: -(424230433158028 * 10000 + 8944),
      id: 4727396763174827,
    ''');
  });
}
