// ignore_for_file: depend_on_referenced_packages

import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';

var bootstrapJs = r'''
(async function () {
    let dart2wasm_runtime;
    let moduleInstance;
    try {
        const dartModulePromise = WebAssembly.compileStreaming(fetch('main.wasm'));
        const imports = {};
        dart2wasm_runtime = await import('./main.mjs');
        moduleInstance = await dart2wasm_runtime.instantiate(dartModulePromise, imports);
    } catch (exception) {
        console.error(`Failed to fetch and instantiate wasm module: ${exception}`);
        console.error('See https://dart.dev/web/wasm for more information.');
    }

    if (moduleInstance) {
        try {
            await dart2wasm_runtime.invoke(moduleInstance);
        } catch (exception) {
            console.error(`Exception while invoking test: ${exception}`);
        }
    }
})();
''';
// See https://dart.dev/web/wasm
Future<void> main() async {
  await buildWasm();
}

Future<void> buildWasm() async {
  await run('dart compile wasm web/main.dart -o build/wasm/main.wasm');
  for (var file in ['index.html']) {
    await File(join('web', file)).copy(join('build', 'wasm', file));
  }

  /// Rename main.mjs to main.dart.js to keep same entry point
  await File(join('build', 'wasm', 'main.dart.js')).writeAsString(bootstrapJs);
}
