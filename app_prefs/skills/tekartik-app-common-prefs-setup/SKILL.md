---
name: tekartik-app-common-prefs-setup
description: >-
  Use when a Dart VM/web app needs persistent shared preferences with
  tekartik_app_common_prefs: prefsAsyncFactory / getPrefsAsyncFactory(packageName)
  and PrefsAsync (getString, getInt, getBool, getDouble, getMap, getList,
  setString, setInt, setStringOrNull, getAll, getKeys, containsKey, clear,
  close), the legacy synchronous prefsFactory / getPrefsFactory and Prefs
  (getInt/setInt + save), openPreferences(name, version, onVersionChanged),
  the in memory prefsAsyncFactoryMemory / newPrefsAsyncFactoryMemory /
  prefsFactoryMemory for tests and factory.sandbox(path:), from
  package:tekartik_app_common_prefs/app_prefs_async.dart and app_prefs.dart.
---

# Persistent preferences (tekartik_app_common_prefs)

`tekartik_app_common_prefs` picks the right `tekartik_prefs` implementation for
the current platform: sembast over sqflite/files on the Dart VM (io, desktop,
mobile) and sembast over IndexedDB in the browser, behind the same
`PrefsAsyncFactory` / `PrefsFactory` API.

## Guidelines

* Not on pub.dev, depend on it through git:
  ```yaml
  dependencies:
    tekartik_app_common_prefs:
      git:
        url: https://github.com/tekartik/app_common_utils.dart
        path: app_prefs
      version: '>=0.1.0'
  ```
* Prefer the async API: `import
  'package:tekartik_app_common_prefs/app_prefs_async.dart';` gives
  `prefsAsyncFactory`, `getPrefsAsyncFactory({String? packageName})` and
  re-exports everything of `package:tekartik_prefs/prefs_async.dart`
  (`PrefsAsync`, `PrefsAsyncFactory`, `PrefsAsyncFactoryOptions`, the memory
  factories, the `sandbox` extension...). Do not also depend on
  `tekartik_prefs` just for the types.
* `import 'package:tekartik_app_common_prefs/app_prefs.dart';` is the legacy
  synchronous variant (`prefsFactory`, `getPrefsFactory({String? packageName})`,
  `Prefs`, `PrefsFactory`). Its setters return `void` and write in the
  background: call `await prefs.save()` to flush, or `await prefs.close()`.
  New code should use the async API; the two can coexist in one file.
* `packageName` only matters on desktop (Linux/Windows), where it selects a
  shared per-application folder: `getPrefsAsyncFactory(packageName:
  'com.example.myapp')`. Factories are cached per `packageName`, so call the
  getter freely - it always returns the same instance. On the web the argument
  is ignored.
* Open with `await factory.openPreferences('name')`. The name behaves like a
  path below the factory root, so `'sub/my_prefs'` is valid. Keep the returned
  object around (it is a cache-backed object, not a file handle) and
  `await prefs.close()` when done; `factory.deletePreferences(name)` removes it.
* Schema migration: `openPreferences(name, version: 2, onVersionChanged:
  (prefs, oldVersion, newVersion) async {...})`. The callback receives the
  `PrefsAsync` (or `Prefs`) being opened and may read/write during the upgrade.
  `prefs.version` and `prefs.name` are available afterwards.
* `PrefsAsync` reads: `getString`, `getInt`, `getBool`, `getDouble`,
  `getStringList`, `containsKey`, `getKeys()`, `getAll()`. Writes: `setString`,
  `setInt`, `setBool`, `setDouble`, `setStringList`, `remove`, `clear`.
  Extensions add `getMap`/`getList` (json decoded) and the null friendly
  `setStringOrNull`, `setIntOrNull`, `setBoolOrNull`, `setDoubleOrNull`,
  `setMap`, `setMapOrNull`, `setList`, `setListOrNull`. The synchronous `Prefs`
  has the same key names with `void` setters plus `keys`.
* By default values are converted between types (an int read as a double, a
  double read as an int...). Call `factory.init(options:
  PrefsAsyncFactoryOptions(strictType: true))` once at startup for the
  shared_preferences-like behaviour where a type mismatch returns null.
* Tests: use `newPrefsAsyncFactoryMemory()` (or the shared
  `prefsAsyncFactoryMemory`, `prefsFactoryMemory`, `newPrefsFactoryMemory()`)
  so nothing is written to disk. `prefsFactory.hasStorage` is false for memory.
  To keep a persistent factory but isolate a test, use
  `factory.sandbox(path: 'test')`: every prefs opened through the returned
  factory lives below that path.
* Only string/int/bool/double are stored natively. For structured data use
  `setMap`/`getMap` or `setList`/`getList`, which json encode through the
  string value.
* Anti-patterns: opening the same prefs name repeatedly instead of keeping the
  instance; using the synchronous `Prefs` setters and exiting without `save()`
  or `close()`; importing `package:tekartik_prefs_sembast/...` or
  `package:tekartik_prefs_browser/...` directly (that defeats the platform
  selection); writing a whole model as one big prefs entry instead of using a
  database (sembast) for real data.
* Lightweight alternative without open/close, see
  [tekartik-app-common-prefs-light](../tekartik-app-common-prefs-light/SKILL.md).

## Examples

### Async prefs with a version upgrade

```dart
import 'package:tekartik_app_common_prefs/app_prefs_async.dart';

Future<void> main() async {
  // Desktop: packageName gives a shared application folder.
  var factory = getPrefsAsyncFactory(packageName: 'com.example.myapp');

  var prefs = await factory.openPreferences(
    'settings',
    version: 2,
    onVersionChanged: (prefs, oldVersion, newVersion) async {
      if (oldVersion < 1) {
        await prefs.setString('theme', 'light');
      }
      if (oldVersion < 2) {
        // Renamed key.
        var user = await prefs.getString('user');
        await prefs.setStringOrNull('userId', user);
        await prefs.remove('user');
      }
    },
  );

  await prefs.setInt('launchCount', (await prefs.getInt('launchCount') ?? 0) + 1);
  await prefs.setMap('window', {'width': 800, 'height': 600});

  print(await prefs.getString('theme'));
  print(await prefs.getMap('window'));
  print(await prefs.getKeys());
  print(await prefs.getAll());

  await prefs.close();
}
```

### In memory factory and sandbox for tests

```dart
import 'package:tekartik_app_common_prefs/app_prefs_async.dart';
import 'package:test/test.dart';

void main() {
  test('counter', () async {
    // Nothing is written to disk.
    var factory = newPrefsAsyncFactoryMemory();
    var prefs = await factory.openPreferences('test_prefs');
    expect(await prefs.getInt('value'), isNull);
    await prefs.setInt('value', 1);
    expect(await prefs.getInt('value'), 1);
    await prefs.clear();
    expect(await prefs.containsKey('value'), isFalse);
    await prefs.close();
  });

  test('sandboxed persistent prefs', () async {
    // Real storage, but isolated below 'test/counter'.
    var factory = prefsAsyncFactory.sandbox(path: 'test/counter');
    await factory.deletePreferences('prefs');
    var prefs = await factory.openPreferences('prefs');
    await prefs.setBool('done', true);
    expect(await prefs.getBool('done'), isTrue);
    await prefs.close();
  });
}
```

### Legacy synchronous prefs

```dart
import 'package:tekartik_app_common_prefs/app_prefs.dart';

Future<void> main() async {
  // Default persistent factory for the current platform.
  var factory = getPrefsFactory();
  var prefs = await factory.openPreferences('my_shared_prefs');

  var value = prefs.getInt('value') ?? 0;
  // Setters are synchronous, the write happens in the background.
  prefs.setInt('value', ++value);
  prefs.setString('title', 'hello');
  prefs.setList('tags', ['a', 'b']);

  print(prefs.getString('title'));
  print(prefs.keys);
  print(prefs.containsKey('value'));

  // Mandatory before the app exits (close also saves).
  await prefs.save();
  await prefs.close();
}
```

### A typed settings holder

```dart
import 'package:tekartik_app_common_prefs/app_prefs_async.dart';

/// Wrap the prefs so that keys and defaults live in one place.
class AppSettings {
  final PrefsAsync prefs;

  AppSettings(this.prefs);

  static Future<AppSettings> open({PrefsAsyncFactory? factory}) async {
    var prefsFactory = factory ?? prefsAsyncFactory;
    return AppSettings(await prefsFactory.openPreferences('app_settings'));
  }

  Future<bool> get darkMode async => await prefs.getBool('darkMode') ?? false;

  Future<void> setDarkMode(bool value) => prefs.setBool('darkMode', value);

  Future<String?> get userId => prefs.getString('userId');

  Future<void> setUserId(String? value) => prefs.setStringOrNull('userId', value);

  Future<void> close() => prefs.close();
}

Future<void> main() async {
  // In a test: AppSettings.open(factory: newPrefsAsyncFactoryMemory())
  var settings = await AppSettings.open();
  await settings.setDarkMode(true);
  print(await settings.darkMode);
  await settings.close();
}
```
