import 'dart:io';

import 'package:args/args.dart';
import 'package:tekartik_app_intl/build_intl.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';

Future<void> main(List<String> arguments) async {
  var parser = ArgParser();
  parser.addFlag('help', abbr: 'h', help: 'Usage');

  var result = parser.parse(arguments);
  if (result['help'] as bool) {
    stdout.writeln(
      'Generate localization_gen.dart and re-order the assets/i18n json files',
    );
    stdout.writeln('generate_intl [<dir>...]');
    stdout.writeln(parser.usage);
    return;
  }
  var rest = result.rest;
  if (rest.isEmpty) {
    rest = [Directory.current.path];
  }
  for (var path in rest) {
    var project = LocalizationProject(path);
    var localeList = await project.intlGetLocales();
    if (localeList.isNotEmpty) {
      await project.intlGenerateFile();

      // Also re-order files
      await project.intlFixJson(localeList: localeList);
    } else {
      stdout.writeln('no locale found');
    }
  }
}
