import 'dart:io';

import 'package:fs_shim/utils/path.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';

import 'text_locale.dart';

final _i18nPath = join('assets', 'i18n');

String _fixLinesStringForIoGit(String json) {
  var lines = LineSplitter.split(json);
  var separator = Platform.isWindows ? '\r\n' : '\n';
  return '${lines.join(separator)}$separator';
}

/// Sort it
Map<String, String?> intlFixMap(Map<String, String> map) {
  var newMap = <String, String?>{};
  var keys = map.keys.toList()..sort();
  for (var key in keys) {
    newMap[key] = map[key];
  }
  return newMap;
}

class LocalizationProject {
  /// The path
  late final String path;

  /// Can be relative (to path) or absolute
  late final String i18nPath;
  late final shell = Shell(workingDirectory: getAbsolutePath());

  /// [u18nPath] default to assets/i18n
  /// posix [path] ok
  LocalizationProject(String path, {String? i18nPath}) {
    this.path = toNativePath(path);
    this.i18nPath = i18nPath ?? _i18nPath;
  }

  String getAbsolutePath() => normalize(absolute((path)));

  String intlGetAssetFilePath(TextLocale locale) {
    return join(i18nPath, '${locale.name}.json');
  }

  String getAbsolutePathFromRelative(String relative) {
    return join(getAbsolutePath(), relative);
  }

  String intlGetAbsoluteAssetFilePath(TextLocale locale) =>
      getAbsolutePathFromRelative(intlGetAssetFilePath(locale));

  Future<Map<String, String>> intlLoadLocaleMap(TextLocale locale) async {
    return (jsonDecode(
              await File(intlGetAbsoluteAssetFilePath(locale)).readAsString(),
            )
            as Map)
        .cast<String, String>();
  }

  // Read local from json files
  Future<List<TextLocale>> intlGetLocales() async {
    try {
      var jsonFilenames =
          (await Directory(
                getAbsolutePathFromRelative(i18nPath),
              ).list().toList())
              .map((e) => basename(e.path))
              .where(
                (element) =>
                    withoutExtension(element).split('_').length == 2 &&
                    extension(element) == '.json',
              )
              .map((e) => basenameWithoutExtension(e));
      return jsonFilenames.map((e) => TextLocale(e)).toList();
    } catch (e) {
      stderr.writeln('intlGetLocales error $e');
      return <TextLocale>[];
    }
  }

  Future<void> intlFixJson({List<TextLocale>? localeList}) async {
    localeList ??= await intlGetLocales();
    for (var locale in localeList) {
      var map = await (intlLoadLocaleMap(locale));

      await writeJson(locale, map);
    }
  }

  Future<void> writeJson(TextLocale locale, Map<String, String> map) async {
    await File(
      intlGetAbsoluteAssetFilePath(locale),
    ).writeAsString(_fixLinesStringForIoGit(jsonPretty(intlFixMap(map))!));
  }

  // Default to
  Future intlFixAndGenerate({bool noEnUs = false}) async {
    var localeList = await intlGetLocales();
    if (!noEnUs) {
      if (!localeList.contains(enUsTextLocale)) {
        return;
      }
    }
    await intlGenerateFile(noEnUs: noEnUs);
    await intlFixJson(localeList: localeList);
  }

  // Default to
  Future intlGenerateFile({String? file, bool noEnUs = false}) async {
    var localeList = await intlGetLocales();
    if (!noEnUs && !localeList.contains(enUsTextLocale)) {
      return;
    }

    var textLocale = noEnUs ? localeList.first : enUsTextLocale;
    var map = intlFixMap(await intlLoadLocaleMap(textLocale));

    var sb = StringBuffer();
    sb.writeln('mixin AppLocalizationsMixinGen {');
    for (var key in map.keys) {
      var paramIndex = key.indexOf('{{');
      List<String>? params;
      if (paramIndex != -1) {
        var paramText = key.substring(paramIndex + 2);
        var endIndex = paramText.indexOf('}}');
        if (endIndex != -1) {
          // Remove _ and camel case it
          key = key.substring(0, paramIndex);
        }

        params = paramText.substring(0, endIndex).split(',');
      }
      var dartKey = fixKeyName(key);
      if (params != null) {
        sb.writeln(
          '  String $dartKey({${params.map((e) => 'required String $e').join(', ')}}) '
          '=> t(\'$key\', {${params.map((e) => '\'$e\': $e').join(', ')}});',
        );
      } else {
        sb.writeln('  String get $dartKey => t(\'$key\');');
      }
    }
    sb.writeln('  String t(String key, [Map<String, String>? data]);');
    sb.writeln('}');
    var filePath = file ?? join('lib', 'src', 'text', 'localization_gen.dart');
    await writeFile(filePath, _fixLinesStringForIoGit(sb.toString()));
    await shell.run('dart format  ${shellArgument(filePath)}');
  }

  Future<void> writeFile(String path, String content) async {
    var file = File(getAbsolutePathFromRelative(path));
    try {
      await file.writeAsString(content);
    } catch (_) {
      if (!file.parent.existsSync()) {
        await file.parent.create(recursive: true);
      }
      await file.writeAsString(content);
    }
  }
}

String _camelCaseWord(String word) {
  // Handle 1 or 0 characters
  if (word.length < 2) {
    return word.toUpperCase();
  }
  return '${word.substring(0, 1).toUpperCase()}${word.substring(1)}';
}

String _camelCaseWords(List<String> words) =>
    words.map((e) => _camelCaseWord(e)).join();

String fixKeyName(String key) => _lowerCamelCaseWords(key.split('_'));

// Start with lower case
// Must be non empty
String _lowerCamelCaseWords(List<String> words) {
  assert(words.isNotEmpty);
  if (words.length > 1) {
    return '${words.first}${_camelCaseWords(words.sublist(1))}';
  }
  return words.first;
}
