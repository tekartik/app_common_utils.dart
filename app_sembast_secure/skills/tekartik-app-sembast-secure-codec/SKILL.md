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
    same factory also opens plain databases.
  * wrapped factory:
    `EncryptedDatabaseFactory(databaseFactory: getDatabaseFactory(), password:
    userPassword)` - it implements `DatabaseFactory` and forwards
    `openDatabase` (with `version`/`onVersionChanged`/`mode`),
    `deleteDatabase`, `databaseExists`, `hasStorage` and `pathContext`, always
    injecting its own `codec`. Prefer it when *every* database of the app is
    encrypted, so no call site can forget the codec.
* `EncryptedDatabaseFactory.openDatabase` asserts that the caller passes no
  `codec` (it is set internally); pass `version:`/`onVersionChanged:`/`mode:`
  normally. Its `codec` field is public (a `SembastCodec` with signature
  `'encrypt'`), which is handy in tests to decode the raw file lines.
* `EncryptedDatabaseFactory.pathContext` is the one of the wrapped factory,
  so `factory.sandbox(path: 'user1')` works (it threw `UnimplementedError`
  before 2026-11-10).
* The password is never stored; the key is `md5(utf8(password))` (16 bytes,
  the Salsa20 key size). sembast checks the codec signature stored in the
  database at open: a wrong password (or opening an encrypted database
  without the codec) throws a `DatabaseException` with
  `code == DatabaseException.errInvalidCodec` (checked on sembast io, the
  memory file system and sembast_sqflite). The plain in memory factory
  (`newDatabaseFactoryMemory()`) has no storage and checks nothing. There is
  no way to change the password in place: export the records, delete the
  database and re-import with a new factory/codec.
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
  content and checks the codec signature like a real file.
* Anti-patterns: opening the same database sometimes with and sometimes
  without the codec (the file becomes unreadable); passing `codec:` to
  `EncryptedDatabaseFactory.openDatabase`; hard-coding the password in the
  source; catching every error as "wrong password" (check
  `DatabaseException.errInvalidCodec`).

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
  // An absolute path (the factory without packageName would use
  // .dart_tool/sqflite_common_ffi/databases).
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

    // The factory codec decodes a raw line of the file; the encoded line
    // does not hold the clear text.
    var codec = factory.codec.codec!;
    var encoded = codec.encode({'key': 1, 'value': 'clear_text'});
    expect(encoded.contains('clear_text'), isFalse);
    expect(codec.decode(encoded), {'key': 1, 'value': 'clear_text'});
    await db.close();

    // A wrong password is refused.
    var wrong = EncryptedDatabaseFactory(
      databaseFactory: databaseFactoryMemoryFs,
      password: 'wrong',
    );
    await expectLater(
      wrong.openDatabase('test.db'),
      throwsA(
        isA<DatabaseException>().having(
          (e) => e.code,
          'code',
          DatabaseException.errInvalidCodec,
        ),
      ),
    );
  });
}
```

### Wrong password

```dart
import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_app_sembast_secure/sembast_secure.dart';

/// Returns false when the password does not open the database.
Future<bool> checkPassword(String path, String password) async {
  var factory = EncryptedDatabaseFactory(
    databaseFactory: databaseFactoryMemoryFs,
    password: password,
  );
  try {
    var db = await factory.openDatabase(path);
    await db.close();
    return true;
  } on DatabaseException catch (e) {
    // The codec signature stored in the database does not decode.
    if (e.code == DatabaseException.errInvalidCodec) {
      return false;
    }
    rethrow;
  }
}
```
