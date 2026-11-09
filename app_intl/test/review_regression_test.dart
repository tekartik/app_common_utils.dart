@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart';
import 'package:tekartik_app_intl/build_intl.dart';
import 'package:tekartik_app_intl/intl.dart';
import 'package:test/test.dart';

void main() {
  test('locales sorted, noEnUs reference is the first one by name', () async {
    var dir = await Directory.systemTemp.createTemp('app_intl_order');
    try {
      var i18nDir = Directory(join(dir.path, 'assets', 'i18n'));
      await i18nDir.create(recursive: true);
      // The directory listing order depends on the file system (tmpfs lists
      // the last created first, ext4 by hash).
      for (var name in ['de_DE', 'fr_FR', 'pt_PT']) {
        await File(
          join(i18nDir.path, '$name.json'),
        ).writeAsString('{"${name.toLowerCase()}_only": "x", "common": "y"}');
      }
      var project = LocalizationProject(dir.path);
      expect(await project.intlGetLocales(), const [
        TextLocale('de_DE'),
        TextLocale('fr_FR'),
        TextLocale('pt_PT'),
      ]);
      await project.intlGenerateFile(noEnUs: true);
      var generated = await File(
        join(dir.path, 'lib', 'src', 'text', 'localization_gen.dart'),
      ).readAsString();
      expect(generated, contains('deDeOnly'));
      expect(generated, isNot(contains('ptPtOnly')));
    } finally {
      await dir.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 1)));

  test('parameter list with spaces', () async {
    var dir = await Directory.systemTemp.createTemp('app_intl_params');
    try {
      var i18nDir = Directory(join(dir.path, 'assets', 'i18n'));
      await i18nDir.create(recursive: true);
      await File(
        join(i18nDir.path, 'en_US.json'),
      ).writeAsString('{"score{{points, total}}": "{{points}} / {{total}}"}');
      await LocalizationProject(dir.path).intlGenerateFile();
      var generated = await File(
        join(dir.path, 'lib', 'src', 'text', 'localization_gen.dart'),
      ).readAsString();
      // The data keys must match the {{total}} placeholder (it used to be
      // ' total': `{{total}}` was left as is in the rendered text).
      expect(generated, contains("'total': total"));
      expect(generated, isNot(contains("' total'")));
    } finally {
      await dir.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 1)));
}
