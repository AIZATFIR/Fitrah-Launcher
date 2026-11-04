import 'dart:io';

const _wideIdRadix = 10000;
final _maxSafeJavascriptInteger = BigInt.parse('9007199254740991');
final _schemaIdPattern = RegExp(r'(\bid:\s*)(-?\d+)(\s*,)');

String transformSchemaIds(String source) {
  return source.replaceAllMapped(_schemaIdPattern, (match) {
    final value = BigInt.parse(match.group(2)!);
    if (value.abs() <= _maxSafeJavascriptInteger) return match[0]!;

    final absolute = value.abs();
    final quotient = absolute ~/ BigInt.from(_wideIdRadix);
    final remainder = absolute % BigInt.from(_wideIdRadix);
    final expression = '$quotient * $_wideIdRadix + $remainder';
    final signedExpression = value.isNegative ? '-($expression)' : expression;
    return '${match.group(1)}$signedExpression${match.group(3)}';
  });
}

void main() {
  final models = Directory('lib/models');
  if (!models.existsSync()) {
    stderr.writeln('Run this script from the project root.');
    exitCode = 1;
    return;
  }

  var changed = 0;
  for (final entity in models.listSync()) {
    if (entity is! File || !entity.path.endsWith('.g.dart')) continue;
    final source = entity.readAsStringSync();
    final transformed = transformSchemaIds(source);
    if (source == transformed) continue;
    entity.writeAsStringSync(transformed);
    changed++;
  }

  stdout.writeln('Rewrote wide schema IDs in $changed generated file(s).');
}
