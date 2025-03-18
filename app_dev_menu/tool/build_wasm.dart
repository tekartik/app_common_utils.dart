// ignore_for_file: depend_on_referenced_packages

import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';

// See https://dart.dev/web/wasm
Future<void> main() async {
  await buildWasm();
}

Future<void> buildWasm() async {
  await run('dart compile wasm web/main.dart -o build/wasm/main.wasm');
  for (var file in ['index.html']) {
    await File(join('web', file)).copy(join('build', 'wasm', file));
  }

  await File(join('web', 'wasm_main.dart.js'))
      .copy(join('build', 'wasm', 'main.dart.js'));
}
