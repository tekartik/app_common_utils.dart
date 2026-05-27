// ignore_for_file: avoid_print

import 'dart:async';

import 'package:process_run/shell.dart';

Future main() async {
  final port = 8080;
  print('Serving `web_dev` on http://localhost:$port');
  await run(
    'dart pub global run webdev serve web:$port --hot-reload --hostname 0.0.0.0',
  );
}
