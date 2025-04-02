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
      'Create or recreate a project in the command line for a given platform',
    );
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
    if (localeList.isEmpty) {
      stderr.writeln('Path $path does not have assets/i18n/xx_XX.json content');
    }
    await project.intlFixJson(localeList: localeList);
  }
}
