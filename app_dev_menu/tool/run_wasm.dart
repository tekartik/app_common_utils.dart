// ignore_for_file: depend_on_referenced_packages
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:tekartik_app_web_build/dhttpd.dart';

Future<void> main() async {
  await runWasm();
}

Future<void> runWasm() async {
  await dhttpdReady(verbose: true);
  var shell = Shell().cd(join('build', 'wasm'));
  print('http://localhost:8040/index.html');
  await shell.run('dhttpd . --port 8040');
}
