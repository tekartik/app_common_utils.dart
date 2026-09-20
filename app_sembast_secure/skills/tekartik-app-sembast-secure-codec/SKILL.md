---
name: tekartik-app-sembast-secure-codec
description: >-
  Use when opening a sembast database whose content must be encrypted on disk
  with tekartik_app_sembast_secure: getEncryptSembastCodec(password:) returning
  a SembastCodec passed to openDatabase(codec:), EncryptedDatabaseFactory(
  databaseFactory:, password:) which wraps any DatabaseFactory and always
  applies the codec, and the Salsa20 helper (encrypt/decrypt with an 8 bytes
  iv), from package:tekartik_app_sembast_secure/sembast_secure.dart. Also
  covers the demonstration-grade security caveats and the migration/password
  change limits.
---

# Encrypted sembast database (tekartik_app_sembast_secure)

`tekartik_app_sembast_secure` provides a `SembastCodec` that encrypts every
record line of a sembast database with Salsa20, keyed by an md5 hash of a user
password, plus a `DatabaseFactory` wrapper so the codec can never be forgotten.

## Guidelines

* Not on pub.dev, depend on it through git (the package lives in the
  `app_sembast_secure/` directory of the repo):
  ```yaml
  dependencies:
    tekartik_app_sembast_secure:
      git:
        url: https://github.com/tekartik/app_common_utils.dart
        path: app_sembast_secure
      version: '>=0.1.0'
  ```
* One import gives the whole public API:
  `package:tekartik_app_sembast_secure/sembast_secure.dart` exports
  `getEncryptSembastCodec`, `EncryptedDatabaseFactory` and `Salsa20`. It does
  **not** re-export sembast, so add `package:sembast/sembast.dart` (or
  `package:tekartik_app_sembast/sembast.dart`, which re-exports sembast and
  provides the cross platform `getDatabaseFactory()`) for `Database`,
  `DatabaseFactory`, `SembastCodec`, `StoreRef`, `stringMapStoreFactory`...
* Two equivalent ways to use it:
  * explicit codec: `var codec = getEncryptSembastCodec(password: userPassword);
    var db = await factory.openDatabase(path, codec: codec);` - use it when the
    same factory also opens plain databases, or when a version/
    `onVersionChanged` callback is needed.
  * wrapped factory:
    `EncryptedDatabaseFactory(databaseFactory: getDatabaseFactory(), password:
    userPassword)` - it implements `DatabaseFactory` and forwards
    `openDatabase`, `deleteDatabase`, `databaseExists` and `hasStorage`, always
    injecting its own `codec`. Prefer it when *every* database of the app is
    encrypted, so no call site can forget the codec.
* `EncryptedDatabaseFactory.openDatabase` asserts that the caller passes no
  `codec` (it is set internally); pass `version:`/`onVersionChanged:`/`mode:`
  normally. Its `codec` field is public (a `SembastCodec` with signature
  `'encrypt'`), which is handy in tests to decode the raw file lines.
* `EncryptedDatabaseFactory.pathContext` throws `UnimplementedError`. Do not
  use it, and do not pass an `EncryptedDatabaseFactory` to code that joins
  paths through the factory (some sembast helpers do): build the absolute file
  path yourself with `package:path` before calling `openDatabase`.
* The password is never stored; the key is `md5(utf8(password))` (16 bytes,
  the Salsa20 key size). A wrong password makes decoding fail (garbage JSON /
  a `FormatException`) rather than returning empty data - catch it and treat it
  as "wrong password". There is no way to change the password in place: export
  the records, delete the database and re-import with a new factory/codec.
* Security caveat, repeated from the source: this is a demonstration-grade
  implementation. The encryption is unauthenticated (no MAC), the password to
  key derivation is a bare md5 instead of a real KDF (pbkdf2, scrypt,
  argon2id), and the storage format may change. Use it to keep data opaque on a
  shared device, not as a compliance-grade encryption of secrets.
* `Salsa20(key)` (a 16 bytes `Uint8List` key) with `encrypt(input, iv)` /
  `decrypt(input, iv)` and an 8 bytes nonce is exported too, for encrypting
  something else with the same primitive. Each encoded value embeds its own
  random iv as a 12 chars base64 prefix.
* The codec is pure Dart (pointycastle + crypto), so it works on the VM,
  Flutter and the web, on top of any sembast factory
  (`databaseFactoryMemory`, sembast_sqflite, sembast_web...). Encoding costs a
  `json.encode` + Salsa20 pass per record, so keep records small.
* Testing: run against an in-memory factory (`databaseFactoryMemory` from
  `package:tekartik_app_sembast/sembast.dart`, or sembast's own
  `databaseFactoryMemoryFs`) - the memory *fs* factory keeps real file
  content, so the test can read the lines back and check they are not plain
  text.
* Anti-patterns: opening the same database sometimes with and sometimes
  without the codec (the file becomes unreadable); passing `codec:` to
  `EncryptedDatabaseFactory.openDatabase`; hard-coding the password in the
  source; assuming a wrong password throws a dedicated exception.

## Examples

### Open an encrypted database on the file system

```dart
import 'dart:io';

import 'package:path/path.dart';
import 'package:tekartik_app_sembast/sembast.dart';
import 'package:tekartik_app_sembast_secure/sembast_secure.dart';

Future<void> main() async {
  var factory = EncryptedDatabaseFactory(
    databaseFactory: getDatabaseFactory(),
    password: 'user_password',
  );
  // pathContext is not implemented: build the path yourself.
  var path = normalize(absolute(join('.dart_tool', 'example', 'secure.db')));
  await Directory(dirname(path)).create(recursive: true);

  var db = await factory.openDatabase(path);
  var store = stringMapStoreFactory.store('settings');
  await store.record('token').put(db, {'value': 'secret'});
  print(await store.record('token').get(db)); // {value: secret}
  await db.close();
}
```

### Explicit codec on an existing factory

```dart
import 'package:sembast/sembast.dart';
import 'package:tekartik_app_sembast/sembast.dart' show getDatabaseFactory;
import 'package:tekartik_app_sembast_secure/sembast_secure.dart';

/// Open an encrypted database, with a version callback.
Future<Database> openSecureDatabase(String path, String password) async {
  var codec = getEncryptSembastCodec(password: password);
  return getDatabaseFactory().openDatabase(
    path,
    codec: codec,
    version: 1,
    onVersionChanged: (db, oldVersion, newVersion) async {
      if (oldVersion == 0) {
        await StoreRef<String, Object?>.main().record('created').put(
          db,
          DateTime.now().toIso8601String(),
        );
      }
    },
  );
}
```

### Test: the content on disk is not readable in plain text

```dart
import 'dart:convert';

import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_app_sembast_secure/sembast_secure.dart';
import 'package:test/test.dart';

void main() {
  test('encrypted content', () async {
    var factory = EncryptedDatabaseFactory(
      databaseFactory: databaseFactoryMemoryFs,
      password: 'user_password',
    );
    var store = StoreRef<int, String>.main();
    var db = await factory.openDatabase('test.db');
    await store.add(db, 'clear_text');
    await db.close();

    // Same password: the data is readable again.
    db = await factory.openDatabase('test.db');
    expect(await store.record(1).get(db), 'clear_text');

    // The factory codec decodes a raw line of the file.
    var codec = factory.codec.codec!;
    expect(codec.decode(codec.encode({'key': 1, 'value': 'clear_text'})), {
      'key': 1,
      'value': 'clear_text',
    });
    expect(json.encode({'key': 1}).contains('clear_text'), isFalse);
    await db.close();
  });
}
```

### Wrong password

```dart
import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_app_sembast_secure/sembast_secure.dart';

/// Returns null when the password does not decode the database.
Future<bool> checkPassword(String path, String password) async {
  var factory = EncryptedDatabaseFactory(
    databaseFactory: databaseFactoryMemoryFs,
    password: password,
  );
  try {
    var db = await factory.openDatabase(path);
    await db.close();
    return true;
  } catch (_) {
    // Decoding garbage: FormatException, TypeError... treat all as a failure.
    return false;
  }
}
```
