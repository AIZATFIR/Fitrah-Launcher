import 'dart:convert';
import 'dart:js_interop';

import 'package:focus_clock_web_storage_spike/browser_store.dart';
import 'package:web/web.dart' as web;

@JS('spikeCommand')
external set spikeCommand(JSFunction callback);

Future<void> main() async {
  try {
    final name = Uri.base.queryParameters['db']!;
    final opened = await openStore(name);
    final db = opened.db;
    Future<String> command(String action) async {
      try {
        switch (action) {
          case 'seed':
            await db.seed();
          case final value when value.startsWith('start-'):
            await db.start(value);
          case 'complete':
            await db.complete();
          case 'rollback':
            await db.complete(injectFailure: true);
          case 'read':
            break;
          default:
            throw ArgumentError('Unknown probe action');
        }
        return jsonEncode({
          'mode': opened.mode.name,
          ...await db.snapshot(),
          'goal': (await db.select(db.settings).getSingleOrNull())?.goal,
          'seconds': (await db.select(db.entries).get())
              .map((entry) => entry.actualSeconds)
              .toList(),
          'timer': (await db.select(db.sessions).getSingleOrNull())?.toJson(),
        });
      } catch (error) {
        return jsonEncode({'error': error.toString()});
      }
    }

    spikeCommand = ((JSString action) => command(
      action.toDart,
    ).then((result) => result.toJS).toJS).toJS;
    web.document.body!.textContent = 'Storage probe ready: ${opened.mode.name}';
  } catch (error) {
    web.document.body!.textContent = 'Storage probe failed: $error';
  }
}
