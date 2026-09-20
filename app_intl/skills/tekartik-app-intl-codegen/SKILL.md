---
name: tekartik-app-intl-codegen
description: >-
  Use when generating or maintaining the typed localization accessors of an app
  from its assets/i18n/<locale>.json files with tekartik_app_intl:
  LocalizationProject, intlGetLocales, intlGenerateFile, intlFixJson,
  intlFixAndGenerate, intlLoadLocaleMap, intlGetAssetFilePath, the generated
  AppLocalizationsMixinGen mixin and its t() method, and the
  lib/bin/generate_intl.dart and lib/bin/fix_i18n_text_order.dart scripts, from
  package:tekartik_app_intl/build_intl.dart.
---

# Generate localization accessors (tekartik_app_intl)

`package:tekartik_app_intl/build_intl.dart` is a VM-only build helper: it reads
an app's `assets/i18n/<locale>.json` files, sorts them canonically and
generates `lib/src/text/localization_gen.dart`, a `AppLocalizationsMixinGen`
mixin with one getter or method per key.

## Guidelines

* Dependency (git, not on pub.dev - the package lives in the `app_intl/`
  directory of the repo). It is a build tool, so put it in `dev_dependencies`
  unless the app also uses the runtime library:
  ```yaml
  dev_dependencies:
    tekartik_app_intl:
      git:
        url: https://github.com/tekartik/app_common_utils.dart
        path: app_intl
      version: '>=0.1.0'
  ```
* Import `package:tekartik_app_intl/build_intl.dart`; it exports exactly one
  name, `LocalizationProject`. It uses `dart:io`, so call it from a script or
  a test, never from web or Flutter app code.
* Layout expected by the tool: `<project>/assets/i18n/en_US.json`,
  `fr_FR.json`, ... Each file name must be `<lang>_<COUNTRY>.json` (exactly
  two `_`-separated parts) or it is ignored. Pass a different folder with
  `LocalizationProject(path, i18nPath: 'assets/l10n')`.
* `LocalizationProject(String path, {String? i18nPath})` - `path` is the
  package directory (posix separators are fine, they are converted).
  Useful members: `intlGetLocales()` (the `TextLocale`s found on disk, empty
  and a message on stderr if the folder is missing), `intlLoadLocaleMap(
  locale)`, `intlGetAssetFilePath(locale)` / `intlGetAbsoluteAssetFilePath(
  locale)`, `getAbsolutePath()`.
* `intlFixJson({List<TextLocale>? localeList})` rewrites each JSON file with
  keys sorted and pretty printed, with a trailing newline - run it to keep
  git diffs minimal after adding a key.
* `intlGenerateFile({String? file, bool noEnUs = false})` writes the mixin
  (default `lib/src/text/localization_gen.dart`) from the `en_US` map and then
  runs `dart format` on it through `process_run`. It silently does nothing
  when `en_US.json` is missing unless `noEnUs: true`, in which case the first
  locale found is used as the reference.
* `intlFixAndGenerate({bool noEnUs = false})` is the usual entry point: it is
  `intlGenerateFile` + `intlFixJson` in one call. The normal integration is a
  4 line `tool/generate_intl.dart` in the app that calls it (first example
  below).
* The package also ships two ready made scripts, `lib/bin/generate_intl.dart`
  (generate + fix) and `lib/bin/fix_i18n_text_order.dart` (sort only). They
  are not declared executables, so they are run by path from a checkout, e.g.
  `dart run <checkout>/app_intl/lib/bin/generate_intl.dart [<dir>...]`; both
  default to the current directory and accept several project dirs.
* Generated shape: a key `zz_yy` becomes `String get zzYy => t('zz_yy');`
  (lower camel case, `_` separated words), a key `count{{n}}` becomes
  `String count({required String n}) => t('count', {'n': n});`, and the mixin
  ends with the abstract `String t(String key, [Map<String, String>? data]);`.
  Implement `t` in your own `AppLocalizations` class using `intlText` /
  `intlRender` - see
  [tekartik-app-intl-text](../tekartik-app-intl-text/SKILL.md).
* The generated file is checked in: regenerate it whenever a key is added or
  removed, and never edit it by hand. Only the reference locale drives the
  API, so a key must exist in `en_US.json` to be generated.
* Anti-patterns: importing `build_intl.dart` from Flutter/web code; declaring
  keys only in `fr_FR.json`; hand-editing `localization_gen.dart`; forgetting
  `intlFixJson` and getting noisy reordering diffs.

## Examples

### A `tool/generate_intl.dart` script for the app

```dart
import 'package:tekartik_app_intl/build_intl.dart';

Future<void> main() async {
  // Run from the app package root.
  var project = LocalizationProject('.');
  // Generates lib/src/text/localization_gen.dart from assets/i18n/en_US.json
  // and rewrites every assets/i18n/*.json sorted.
  await project.intlFixAndGenerate();
}
```

### Inspect locales, generate to a custom path, sort only

```dart
import 'package:tekartik_app_intl/build_intl.dart';

Future<void> main() async {
  var project = LocalizationProject(
    'packages/my_app',
    i18nPath: 'assets/i18n',
  );

  var locales = await project.intlGetLocales();
  print(locales); // [TL(en_US), TL(fr_FR)]
  for (var locale in locales) {
    var map = await project.intlLoadLocaleMap(locale);
    print('${locale.name}: ${map.length} keys '
        '(${project.intlGetAssetFilePath(locale)})');
  }

  // Only rewrite the json files, sorted, no dart generation.
  await project.intlFixJson(localeList: locales);

  // Generate elsewhere than lib/src/text/localization_gen.dart.
  await project.intlGenerateFile(file: 'lib/src/l10n/localization_gen.dart');
}
```

### Project without an `en_US` reference locale

```dart
import 'package:tekartik_app_intl/build_intl.dart';

Future<void> main() async {
  var project = LocalizationProject('test/project_no_en_us');
  // Without noEnUs, generation is skipped when en_US.json is missing;
  // with it, the first locale found is used as the reference.
  await project.intlFixAndGenerate(noEnUs: true);
}
```

### Implementing the generated mixin

```dart
// Assumes `lib/src/text/localization_gen.dart` was generated and declares
// `mixin AppLocalizationsMixinGen { ... String t(String key, [Map<String,
// String>? data]); }`.
import 'package:tekartik_app_intl/intl.dart';

mixin AppLocalizationsMixinGen {
  String get zzYy => t('zz_yy');
  String zzTestCount({required String count}) =>
      t('zzTestCount', {'count': count});
  String t(String key, [Map<String, String>? data]);
}

class AppLocalizations with AppLocalizationsMixinGen {
  final TextLocale locale;
  final Map<String, String> localizationMap;
  final Map<String, String> defaultLocalizationMap;

  AppLocalizations({
    required this.locale,
    required this.localizationMap,
    required this.defaultLocalizationMap,
  });

  @override
  String t(String key, [Map<String, String>? data]) => intlText(
    localizationMap,
    key,
    data: data,
    defaultLocalizationMap: defaultLocalizationMap,
  );
}

void main() {
  var enUs = intlDecodeLocalizationMap(
    '{"zz_yy": "zz yy", "zzTestCount{{count}}": "TestCount {{count}}"}',
  );
  var intl = AppLocalizations(
    locale: enUsTextLocale,
    localizationMap: enUs,
    defaultLocalizationMap: enUs,
  );
  print(intl.zzYy); // zz yy
  print(intl.zzTestCount(count: '3')); // TestCount 3
}
```
