# tekartik_app_intl

A tiny localization runtime and its code generator, without Flutter
dependency. Each locale is a flat JSON map in `assets/i18n/<lang>_<COUNTRY>.json`
(`en_US.json`, `fr_FR.json`...). A key with parameters declares them in a
`{{...}}` suffix, its text uses them as `{{name}}` placeholders:

```json
{
  "hello": "Hello",
  "welcome{{name}}": "Welcome {{name}}",
  "score{{points,total}}": "{{points}} out of {{total}}"
}
```

The generator writes a Dart mixin with one getter or method per key
(`hello`, `welcome(name: ...)`, `score(points: ..., total: ...)`), so a
missing key is a compile error.

## Getting started

Not on pub.dev, add it as a git dependency (Dart SDK `^3.12.0`):

```yaml
dependencies:
  tekartik_app_intl:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_intl
```

```dart
import 'package:tekartik_app_intl/intl.dart';

void main() {
  var enUs = intlDecodeLocalizationMap(
    '{"hello": "Hello", "welcome{{name}}": "Welcome {{name}}"}',
  );
  print(intlText(enUs, 'hello')); // Hello
  print(intlText(enUs, 'welcome', data: {'name': 'Alex'})); // Welcome Alex
  print(intlText(enUs, 'missing')); // [missing]
}
```

The runtime (`intl.dart`, `intl_codes.dart`) is pure Dart: Dart VM,
Flutter (mobile, desktop, web), browser. The generator (`build_intl.dart`)
uses `dart:io`: run it from a script or a test. In Flutter,
`tekartik_app_flutter_intl` (app_flutter_utils.dart) loads the JSON assets.
See [example/main.dart](example/main.dart).

## What to use

* Runtime, `package:tekartik_app_intl/intl.dart`:
  * `intlDecodeLocalizationMap(json)` (or `intlSafeLocalizationMap(map)`):
    the map with the `{{...}}` suffixes removed from the keys.
  * `intlText(map, key, data: ..., defaultLocalizationMap: ...)`: the text,
    else the default map's (pass the English one), else `[key]`.
  * `intlRender(template, data: ...)`: the `{{name}}` replacement only.
  * `TextLocale`, `enUsTextLocale`, `frFrTextLocale` and the codes (also in
    `intl_codes.dart`).
* Generator, `package:tekartik_app_intl/build_intl.dart`:
  `LocalizationProject('.')` then `intlFixAndGenerate()`: writes
  `lib/src/text/localization_gen.dart` (`mixin AppLocalizationsMixinGen`,
  from `en_US.json`) and rewrites every JSON file sorted. A 3 line
  `tool/generate_intl.dart` is enough:

```dart
import 'package:tekartik_app_intl/build_intl.dart';

Future<void> main() async {
  await LocalizationProject('.').intlFixAndGenerate();
}
```

## Common pitfalls

* Decode the JSON with `intlDecodeLocalizationMap` (or pass it to
  `intlSafeLocalizationMap`) before `intlText`: a raw map still has the
  `{{...}}` suffixes in its keys.
* The generator does nothing without `en_US.json`, unless
  `noEnUs: true`: the first locale by name is then the reference (since
  2026-11-09: it was the directory listing order, which depends on the file
  system).
* A parameter list may have spaces (`{{points, total}}`) since 2026-11-09
  (the generated map key was `' total'`, so `{{total}}` stayed in the text).
* `intlRender` throws on a null value in `data`, even for a name absent from
  the template.
* A key with an unclosed `{{` stops the generator with a `RangeError`.
* Keys become Dart names: use `snake_case` or `camelCase` keys
  (`zz_yy` gives `zzYy`), no `-`, `.` or quote.

## Agent skills

[skills/tekartik-app-intl-text](skills/tekartik-app-intl-text/SKILL.md)
(runtime) and
[skills/tekartik-app-intl-codegen](skills/tekartik-app-intl-codegen/SKILL.md)
(generator).
