import 'package:dev_build/shell.dart';

Future<void> main(List<String> args) async {
  await run('dart pub global deactivate process_run');
}
