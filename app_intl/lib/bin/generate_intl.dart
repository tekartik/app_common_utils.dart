import 'dart:io';

import 'package:args/args.dart';
import 'package:tekartik_app_intl/build_intl.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';

Future<void> main(List<String> arguments) async {
  var parser = ArgParser();
  parser.addFlag('help', abbr: 'h', help: 'Usage');

  var result = parser.parse(arguments);
  if (result['help'] as bool) {
    stdout.writeln('Generate localization_gen.dart');
    stdout.writeln('create_project_and_checkout_from_git [<dir>]');
    stdout.writeln(parser.usage);
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
      print('no locale found');
    }
  }
}
