@TestOn('vm')
library;

import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:test/test.dart';

/// Regression tests of the 2026-11-09 review.
void main() {
  test('a program importing mirrors.dart compiles ahead of time', () async {
    var dir = await Directory.systemTemp.createTemp('app_mirrors_aot');
    try {
      var result = await Shell(verbose: false, throwOnError: false)
          .runExecutableArguments('dart', [
            'compile',
            'aot-snapshot',
            'test/data/aot_import_main.dart',
            '-o',
            '${dir.path}/aot_import_main.aot',
          ]);
      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    } finally {
      await dir.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
