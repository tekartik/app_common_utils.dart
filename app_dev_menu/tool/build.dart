import 'dart:async';

import 'package:dev_build/build_support.dart';
import 'package:process_run/shell.dart';

Future main() async {
  await checkAndActivateWebdev();
  await run('dart pub global run webdev build');
}
