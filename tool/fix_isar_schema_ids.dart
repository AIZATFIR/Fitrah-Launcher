import 'dart:io';

const _wideIdRadix = 10000;
final _maxSafeJavascriptInteger = BigInt.parse('9007199254740991');
final _schemaIdPattern = RegExp(r'(\bid:\s*)(-?\d+)(\s*,)');
const _preservedPropertyIds = <String, Map<String, int>>{
  'timer_session.g.dart': {
    'accumulatedDurationSeconds': 0,
    'activityId': 1,
    'attributionLocalDate': 2,
    'clockBootCount': 3,
    'clockElapsedRealtimeMillis': 4,
    'habitId': 5,
    'habitName': 6,
    'habitTargetSnapshot': 7,
    'pausedAt': 8,
    'runningSince': 9,
    'sessionId': 10,
    'sourceColorValue': 11,
    'sourceIdentity': 12,
    'sourceKindIndex': 13,
    'startedAt': 14,
    'status': 15,
    'targetSeconds': 16,
    'updatedAt': 17,
    'goalId': 18,
    'goalTitleSnapshot': 19,
  },
  'terminal_focus_session.g.dart': {
    'activityId': 0,
    'actualDurationSeconds': 1,
    'completedAt': 2,
    'habitId': 3,
    'sessionId': 4,
    'sourceIdentity': 5,
    'sourceKind': 6,
    'startedAt': 7,
    'status': 8,
    'titleSnapshot': 9,
    'goalId': 10,
    'goalTitleSnapshot': 11,
  },
};

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

String transformPreservedPropertyIds(String source, String fileName) {
  final desiredIds = _preservedPropertyIds[fileName];
  if (desiredIds == null) return source;

  final propertiesStart = source.indexOf('  properties: {');
  if (propertiesStart < 0) return source;
  final propertiesEnd = source.indexOf('\n  },', propertiesStart);
  if (propertiesEnd < 0) return source;
  var properties = source.substring(propertiesStart, propertiesEnd);
  final generatedIds = <String, int>{};
  final propertyPattern = RegExp(r"r'([^']+)': PropertySchema\(\s*id:\s*(\d+)");
  for (final match in propertyPattern.allMatches(properties)) {
    generatedIds[match.group(1)!] = int.parse(match.group(2)!);
  }
  if (generatedIds.keys
          .toSet()
          .difference(desiredIds.keys.toSet())
          .isNotEmpty ||
      desiredIds.keys
          .toSet()
          .difference(generatedIds.keys.toSet())
          .isNotEmpty) {
    throw StateError('Unexpected Isar properties in $fileName.');
  }

  for (final entry in desiredIds.entries) {
    final pattern = RegExp(
      "(r'${RegExp.escape(entry.key)}': PropertySchema\\(\\s*id:\\s*)\\d+",
    );
    properties = properties.replaceFirstMapped(
      pattern,
      (match) => '${match.group(1)}${entry.value}',
    );
  }
  var transformed =
      source.substring(0, propertiesStart) +
      properties +
      source.substring(propertiesEnd);

  final functionName = fileName == 'timer_session.g.dart'
      ? '_timerSessionDeserializeProp'
      : '_terminalFocusSessionDeserializeProp';
  final functionStart = transformed.indexOf('P $functionName<P>');
  if (functionStart < 0) return transformed;
  final functionEnd = transformed.indexOf('\n}\n', functionStart) + 2;
  if (functionEnd < 2) return transformed;
  var function = transformed.substring(functionStart, functionEnd);
  final remappedIds = {
    for (final entry in generatedIds.entries)
      entry.value: desiredIds[entry.key]!,
  };
  function = function.replaceAllMapped(RegExp(r'case (\d+):'), (match) {
    final oldId = int.parse(match.group(1)!);
    return 'case ${remappedIds[oldId] ?? oldId}:';
  });
  return transformed.substring(0, functionStart) +
      function +
      transformed.substring(functionEnd);
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
    final transformed = transformPreservedPropertyIds(
      transformSchemaIds(source),
      entity.uri.pathSegments.last,
    );
    if (source == transformed) continue;
    entity.writeAsStringSync(transformed);
    changed++;
  }

  stdout.writeln('Rewrote wide schema IDs in $changed generated file(s).');
}
