import 'dart:async';

import 'package:process_run/shell_run.dart';

Future main() async {
  print('Serving `web_dev` on http://localhost:8060');
  await run('webdev serve example:8060 --live-reload --hostname 0.0.0.0');
}
