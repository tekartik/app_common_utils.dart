---
name: tekartik-app-intl-text
description: >-
  Use when translating and rendering localized text at runtime from JSON
  localization maps with tekartik_app_intl: intlText, intlRender,
  intlDecodeLocalizationMap, intlSafeKey, intlSafeLocalizationMap, the
  TextLocale class, enUsTextLocale, frFrTextLocale, enUsLocaleName,
  frFrLocaleName, englishLanguageCode, frenchLanguageCode, usaCountryCode,
  franceCountryCode, and the {{param}} placeholder convention, from
  package:tekartik_app_intl/intl.dart and package:tekartik_app_intl/intl_codes.dart.
---

# Localized text at runtime (tekartik_app_intl)

`tekartik_app_intl` is a tiny, framework-free localization runtime: each locale
is a flat `Map<String, String>` (loaded from `assets/i18n/<locale>.json`), keys
may declare parameters with a `{{p1,p2}}` suffix, and values interpolate them
with `{{p1}}` placeholders.

## Guidelines

* Dependency (git, not on pub.dev - the package lives in the `app_intl/`
  directory of the repo):
  ```yaml
  dependencies:
    tekartik_app_intl:
      git:
        url: https://github.com/tekartik/app_common_utils.dart
        path: app_intl
      version: '>=0.1.0'
  ```
* Imports: `package:tekartik_app_intl/intl.dart` for everything (render
  helpers + locale codes); `package:tekartik_app_intl/intl_codes.dart` when a
  package only needs the locale constants (`TextLocale`, `enUsTextLocale`,
  `frFrTextLocale`, `enUsLocaleName`, `frFrLocaleName`, `englishLanguageCode`,
  `frenchLanguageCode`, `usaCountryCode`, `franceCountryCode`).
* Key convention: a key that takes parameters is written with the parameter
  list appended, e.g. `"zzTestCount{{count}}"` or
  `"zzTest2Params{{p1,p2}}"`, and the value uses `{{count}}` placeholders.
  `intlSafeKey('zzTestCount{{count}}')` strips the suffix and returns
  `zzTestCount`, which is the key used at lookup time.
* Always normalize a decoded map with `intlSafeLocalizationMap(map)` (or
  `intlDecodeLocalizationMap(jsonString)`, which does `jsonDecode` +
  normalization) before passing it to `intlText`: `intlText` looks up plain
  keys only.
* `String intlText(Map<String, String> localizationMap, String key, {Map<String,
  String?>? data, Map<String, String>? defaultLocalizationMap})` returns the
  value from the map, falling back to `defaultLocalizationMap` and finally to
  `'[$key]'` (a visible marker for a missing translation - never an
  exception). Pass the English map as `defaultLocalizationMap` so a missing
  translation degrades to English.
* `String intlRender(String template, {Map<String, String?>? data})` only does
  the `{{key}}` substitution; use it when you already hold the template
  (typical when a generated mixin's `t()` walks a list of maps). Values in
  `data` must not be null for keys present in the template: `intlRender` does
  `value!` and throws on a null.
* `TextLocale` is a simple value class around a name such as `en_US`; it has
  `==`/`hashCode`, so it works as a map key. Build one from a Flutter `Locale`
  with `TextLocale(locale.toString())`. Prefer the `enUsTextLocale` /
  `frFrTextLocale` constants.
* Deprecated aliases still exported for compatibility: `enLanguageName`,
  `frLanguageName`, `usCountryCode`, `frCountryCode`. Use
  `englishLanguageCode`, `frenchLanguageCode`, `usaCountryCode`,
  `franceCountryCode` in new code.
* This package is pure Dart and has no asset loader: read the JSON yourself
  (`File`, `http`, ...). In Flutter use `tekartik_app_flutter_intl`
  (`app_flutter_utils.dart/app_intl`), which re-exports this library and adds
  `loadLocalizationMap(TextLocale locale, {String? package})` on top of
  `rootBundle`.
* Typed accessors are generated from the JSON rather than hand written: see
  [tekartik-app-intl-codegen](../tekartik-app-intl-codegen/SKILL.md) for
  `LocalizationProject` and the `AppLocalizationsMixinGen` mixin whose
  abstract `String t(String key, [Map<String, String>? data])` you implement
  with `intlText` / `intlRender`.
* Anti-patterns: calling `intlText` with a raw decoded map (keys still carry
  `{{...}}`); hard-coding `'en_US'` instead of `enUsLocaleName`; expecting a
  throw on a missing key.

## Examples

### Decode a localization map and render text

```dart
import 'package:tekartik_app_intl/intl.dart';

void main() {
  var enUs = intlDecodeLocalizationMap('''
{
  "helloWorld": "Hello world",
  "greeting{{name}}": "Hello {{name}}!",
  "score{{points,total}}": "{{points}} out of {{total}}"
}
''');

  print(intlText(enUs, 'helloWorld')); // Hello world
  print(intlText(enUs, 'greeting', data: {'name': 'Alex'})); // Hello Alex!
  print(
    intlText(enUs, 'score', data: {'points': '3', 'total': '10'}),
  ); // 3 out of 10
  print(intlText(enUs, 'missing')); // [missing]
}
```

### Per locale maps with an English fallback

```dart
import 'package:tekartik_app_intl/intl.dart';

class AppText {
  final TextLocale locale;
  final Map<String, String> localizationMap;
  final Map<String, String> defaultLocalizationMap;

  AppText({
    required this.locale,
    required this.localizationMap,
    required this.defaultLocalizationMap,
  });

  String t(String key, [Map<String, String>? data]) => intlText(
    localizationMap,
    key,
    data: data,
    defaultLocalizationMap: defaultLocalizationMap,
  );
}

void main() {
  var enUs = intlSafeLocalizationMap({
    'cancel': 'Cancel',
    'welcome{{name}}': 'Welcome {{name}}',
  });
  // 'cancel' is not translated yet: falls back to English.
  var frFr = intlSafeLocalizationMap({'welcome{{name}}': 'Bienvenue {{name}}'});

  var text = AppText(
    locale: frFrTextLocale,
    localizationMap: frFr,
    defaultLocalizationMap: enUs,
  );
  print(text.t('welcome', {'name': 'Alex'})); // Bienvenue Alex
  print(text.t('cancel')); // Cancel
}
```

### Locale codes and a template rendered directly

```dart
import 'package:tekartik_app_intl/intl_codes.dart';
import 'package:tekartik_app_intl/intl.dart' show intlRender;

TextLocale textLocaleFromLanguageCode(String languageCode) {
  switch (languageCode) {
    case frenchLanguageCode:
      return frFrTextLocale;
    case englishLanguageCode:
    default:
      return enUsTextLocale;
  }
}

void main() {
  print(enUsLocaleName); // en_US
  print(frFrLocaleName); // fr_FR
  print(textLocaleFromLanguageCode('fr')); // TL(fr_FR)
  print(TextLocale('fr_FR') == frFrTextLocale); // true

  // Rendering a template that was resolved elsewhere.
  print(intlRender('Hello {{name}}', data: {'name': 'Alex'})); // Hello Alex
}
```
