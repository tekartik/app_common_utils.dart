// ignore_for_file: depend_on_referenced_packages

import 'build_wasm.dart';
import 'run_wasm.dart';

// See https://dart.dev/web/wasm
Future<void> main() async {
  await buildWasm();
  await runWasm();
}
