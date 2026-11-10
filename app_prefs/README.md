# tekartik_app_common_prefs

Persistent preferences for a Dart VM or web program, behind the
[tekartik_prefs](https://github.com/tekartik/prefs.dart) API: a sembast
database file per prefs on io, localStorage on the web. For a Flutter app,
use `tekartik_app_prefs` of
[app_flutter_utils](https://github.com/tekartik/app_flutter_utils.dart).

## Getting started

Not on pub.dev, add it as a git dependency (Dart SDK `^3.12.0`):

```yaml
dependencies:
  tekartik_app_common_prefs:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_prefs
```

```dart
import 'package:tekartik_app_common_prefs/app_prefs_async.dart';

Future<void> main() async {
  // Cached: the same factory for the same package name.
  var factory = getPrefsAsyncFactory(packageName: 'com.example.my_tool');
  var prefs = await factory.openPreferences('settings');
  var count = (await prefs.getInt('launchCount') ?? 0) + 1;
  await prefs.setInt('launchCount', count);
  print('launch #$count');
  await prefs.close();
}
```

See [example/main.dart](example/main.dart).

## Platforms

| Platform | `openPreferences('settings')` |
|---|---|
| io (Linux, macOS, Windows) with `packageName` | sembast_sqflite file `<userAppDataPath>/<packageName>/databases/settings` (`~/.config`, `%APPDATA%`) |
| io without `packageName` | `.dart_tool/sqflite_common_ffi/databases/settings`, relative to the current directory (tests, tools run in a project) |
| web (dart2js, dart2wasm) | localStorage keys `settings/<key>`, `packageName` ignored |
| tests | `newPrefsAsyncFactoryMemory()`, `newPrefsFactoryMemory()` |

`prefsLight` (`app_prefs_light.dart`) is a sembast file
`.local/prefs_light/prefs.db` relative to the current directory on io, the
`prefs_light/prefs.db` sembast_web (IndexedDB) database on the web.

## What to use

* `app_prefs_async.dart`: `getPrefsAsyncFactory({packageName})`,
  `prefsAsyncFactory` (no package name) and the `PrefsAsync` API (every
  read and write awaited).
* `app_prefs.dart`: the legacy synchronous `Prefs` (`getPrefsFactory`,
  `prefsFactory`): reads from memory, writes saved in the background.
* `app_prefs_light.dart`: `prefsLight`, an always open key/value store, no
  open or close.

## Common pitfalls

* Pass a `packageName` in a program: without it the prefs follow the current
  directory.
* The prefs share `<userAppDataPath>/<packageName>/databases/` with the
  databases of `tekartik_app_sembast` and `tekartik_app_sqflite` for the same
  package name: a prefs `settings` and a database `settings` are one file,
  use distinct names.
* Synchronous `Prefs`: `await prefs.save()` or `await prefs.close()` before
  the program exits, the setters only start the write.
* Open each prefs once and keep it (the factories are cached per package
  name, opening the same name again gives the same prefs).
* Web: a prefs named `a` sees and clears the keys of a prefs named `a/b`
  (localStorage keys `a/b/<key>` start with `a/`): avoid nested names there.

## Agent skills

[skills/tekartik-app-common-prefs-setup](skills/tekartik-app-common-prefs-setup/SKILL.md),
[skills/tekartik-app-common-prefs-light](skills/tekartik-app-common-prefs-light/SKILL.md).
