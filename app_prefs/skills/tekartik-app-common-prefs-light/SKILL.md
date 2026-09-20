---
name: tekartik-app-common-prefs-light
description: >-
  Use when an app needs a couple of persisted values without opening/closing a
  prefs database, with tekartik_app_common_prefs: the global prefsLight
  (PrefsLight) from package:tekartik_app_common_prefs/app_prefs_light.dart,
  its getString/getInt/getBool/getDouble/setString/setInt/setBool/setDouble/
  remove API, the PrefsLightExt helpers (setIntOrNull, setBoolOrNull,
  setDoubleOrNull, getMap, setMap, getList, setList, setMapOrNull), the
  KvStore / KvStoreRead / KvStoreWrite interfaces, PrefsMemory for tests and
  PrefsLightAsync to wrap an existing PrefsAsync.
---

# Lightweight key/value prefs (tekartik_app_common_prefs)

`app_prefs_light.dart` exposes a single ready-to-use global, `prefsLight`: an
always-open, lazily initialized `PrefsLight` store backed by sembast (a local
file on the Dart VM, IndexedDB on the web). Everything is async but there is no
factory, no `openPreferences` and no `close`.

## Guidelines

* Same git dependency as the rest of the package (not on pub.dev):
  ```yaml
  dependencies:
    tekartik_app_common_prefs:
      git:
        url: https://github.com/tekartik/app_common_utils.dart
        path: app_prefs
      version: '>=0.1.0'
  ```
* `import 'package:tekartik_app_common_prefs/app_prefs_light.dart';` gives
  `prefsLight` plus the `tekartik_prefs` light API: `PrefsLight`,
  `PrefsLightExt`, `PrefsLightAsync`, `PrefsMemory`, `KvStore`, `KvStoreRead`,
  `KvStoreWrite`, `KvStoreExt` and the `KvStoreGetStringFunction` /
  `KvStoreSetStringFunction` / `KvStoreRemoveFunction` typedefs.
* `prefsLight` is a top-level mutable variable of type `PrefsLight`. Use it
  directly: `await prefsLight.setInt('value', 1)`. Reads return null when the
  key is missing **or** when the stored value has another type (the light
  implementation swallows conversion errors instead of throwing).
* Storage location is fixed: `.local/prefs_light` relative to the current
  directory on io (so it depends on where the process is started), and the
  `prefs_light` database in IndexedDB on the web. When you need a chosen
  location, a name or a version, use the full API instead - see
  [tekartik-app-common-prefs-setup](../tekartik-app-common-prefs-setup/SKILL.md).
* Values are `String`, `int`, `bool` and `double`. `PrefsLightExt` adds
  `setIntOrNull`, `setBoolOrNull`, `setDoubleOrNull`, `setMap`, `setMapOrNull`,
  `getMap`, `setList`, `setListOrNull` and `getList` (json encoded through the
  string value). `KvStoreExt` adds `setStringOrNull`.
* There is no `clear()`, no key listing and no `close()`: remove keys one by
  one with `remove(key)`. Writes are persisted as they complete, awaiting a
  `setX` is enough.
* Tests: assign a `PrefsMemory()` to the global (`prefsLight = PrefsMemory();`)
  in `setUp` so nothing touches the disk, or take a `PrefsLight` parameter in
  your own classes and default it to `prefsLight`.
* To reuse an already opened `PrefsAsync` (same storage as the rest of the
  app) behind the light API, wrap it: `PrefsLightAsync(delegate: prefsAsync)`
  or `PrefsLightAsync.lazy(initDelegate: () async => ...)` which opens on first
  use.
* Depend on `KvStore` (or `KvStoreRead`) in code that only reads/writes
  strings - `PrefsLight` implements it, and `KvStore(getString: ...,
  setString: ..., remove: ...)` builds one from three functions for any other
  backend.
* Anti-patterns: using `prefsLight` for large or structured data (use sembast);
  calling `setX` without awaiting in a `main()` that exits immediately;
  assuming a missing value and a wrong-typed value can be told apart;
  hard-coding `prefsLight` deep in the code instead of injecting a
  `PrefsLight`.

## Examples

### Read and update a counter

```dart
import 'package:tekartik_app_common_prefs/app_prefs_light.dart';

Future<void> main() async {
  var value = (await prefsLight.getInt('value')) ?? 0;
  await prefsLight.setInt('value', ++value);
  print('launch count: $value');

  await prefsLight.setString('lastUser', 'alex');
  await prefsLight.setBoolOrNull('darkMode', null); // removes the key
  print(await prefsLight.getBool('darkMode')); // null

  await prefsLight.setMap('window', {'width': 800, 'height': 600});
  print(await prefsLight.getMap('window'));

  await prefsLight.remove('lastUser');
}
```

### Inject a PrefsLight and test it in memory

```dart
import 'package:tekartik_app_common_prefs/app_prefs_light.dart';
import 'package:test/test.dart';

/// Takes the store as a parameter: the global is only the default.
class SessionStore {
  final PrefsLight prefs;

  SessionStore({PrefsLight? prefs}) : prefs = prefs ?? prefsLight;

  Future<String?> get token => prefs.getString('token');

  Future<void> setToken(String? token) =>
      prefs.setStringOrNull('token', token);
}

void main() {
  test('session', () async {
    // In memory implementation, nothing is persisted.
    var store = SessionStore(prefs: PrefsMemory());
    expect(await store.token, isNull);
    await store.setToken('abc');
    expect(await store.token, 'abc');
    await store.setToken(null);
    expect(await store.token, isNull);
  });
}
```

### Share the storage of the full prefs API

```dart
import 'package:tekartik_app_common_prefs/app_prefs_async.dart';
import 'package:tekartik_app_common_prefs/app_prefs_light.dart';

Future<void> main() async {
  // Opened lazily on the first get/set, same database as the app settings.
  var light = PrefsLightAsync.lazy(
    initDelegate: () => prefsAsyncFactory.openPreferences('app_settings'),
  );

  await light.setInt('fontSize', 14);
  print(await light.getInt('fontSize'));

  // Or wrap an already opened one.
  var prefs = await prefsAsyncFactory.openPreferences('app_settings');
  var other = PrefsLightAsync(delegate: prefs);
  print(await other.getInt('fontSize'));
  await prefs.close();
}
```

### A KvStore over any backend

```dart
import 'package:tekartik_app_common_prefs/app_prefs_light.dart';

/// Anything that can read/write/remove a string can be a KvStore.
KvStore memoryKvStore() {
  var map = <String, String>{};
  return KvStore(
    getString: (key) async => map[key],
    setString: (key, value) async => map[key] = value,
    remove: (key) async => map.remove(key),
  );
}

Future<void> useStore(KvStore store) async {
  await store.setString('key', 'value');
  await store.setStringOrNull('other', null); // removes
  print(await store.getString('key'));
}

Future<void> main() async {
  await useStore(memoryKvStore());
  // prefsLight is a KvStore too.
  await useStore(prefsLight);
}
```
