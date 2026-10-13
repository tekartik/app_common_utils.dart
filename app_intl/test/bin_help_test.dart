@TestOn('vm')
library;

import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  for (var name in ['generate_intl', 'fix_i18n_text_order']) {
    test('$name -h only prints its usage', () async {
      // Run from an empty directory, that must not be processed.
      var dir = await Directory.systemTemp.createTemp('app_intl_help');
      try {
        var result = await Process.run(Platform.resolvedExecutable, [
          '--packages=${(await Isolate.packageConfig)!.toFilePath()}',
          absolute(join('lib', 'bin', '$name.dart')),
          '-h',
        ], workingDirectory: dir.path);
        var out = result.stdout.toString();
        expect(result.exitCode, 0);
        expect(out, contains('$name [<dir>...]'));
        expect(out, isNot(contains('create_project')));
        expect(out, isNot(contains('no locale found')));
        expect(result.stderr.toString(), isEmpty);
        expect(await dir.list().toList(), isEmpty);
      } finally {
        await dir.delete(recursive: true);
      }
    });
  }
}
