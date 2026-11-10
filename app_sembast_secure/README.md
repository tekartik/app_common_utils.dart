# tekartik_app_sembast_secure

A sembast codec that encrypts every record of a database with a password
(Salsa20, pure Dart), and `EncryptedDatabaseFactory`, a `DatabaseFactory`
wrapper that always applies it.

**Demonstration grade encryption**: the key is the md5 of the password (no
salt, no key derivation function), the records are not authenticated (no MAC)
and the storage format may change. It keeps a database opaque on a shared
device; do not rely on it to protect secrets.

## Getting started

Not on pub.dev, add it as a git dependency (Dart SDK `^3.12.0`), with sembast
or [tekartik_app_sembast](../app_sembast/README.md) for the factory:

```yaml
dependencies:
  tekartik_app_sembast_secure:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_sembast_secure
  tekartik_app_sembast:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_sembast
```

```dart
import 'package:tekartik_app_sembast/sembast.dart';
import 'package:tekartik_app_sembast_secure/sembast_secure.dart';

Future<void> main() async {
  // Every database opened through this factory is encrypted.
  var factory = EncryptedDatabaseFactory(
    databaseFactory: getDatabaseFactory(packageName: 'com.example.my_app'),
    password: 'user password',
  );
  var store = StoreRef<String, String>.main();
  var db = await factory.openDatabase('secure.db');
  await store.record('token').put(db, 'secret');
  print(await store.record('token').get(db)); // secret
  await db.close();
}
```

See [example/sembast_secure_example.dart](example/sembast_secure_example.dart).

## Platforms

Pure Dart (pointycastle, crypto): it works on top of any sembast factory, on
the Dart VM, Flutter and the web (`getDatabaseFactory()` of
tekartik_app_sembast, sembast io, sembast_sqflite, sembast_web, memory).

## What to use

* `EncryptedDatabaseFactory(databaseFactory:, password:)`: when every
  database of the factory is encrypted. `openDatabase` takes `version`,
  `onVersionChanged` and `mode` as usual, never a `codec`.
  `factory.sandbox(path:)` works on it.
* `getEncryptSembastCodec(password:)`: the `SembastCodec` itself, to pass as
  `openDatabase(path, codec: codec)` on a factory that also opens plain
  databases.

## Common pitfalls

* A wrong password fails the open with a `DatabaseException` whose `code` is
  `DatabaseException.errInvalidCodec` (sembast checks the codec signature
  stored in the database); the plain sembast in memory factory
  (`newDatabaseFactoryMemory()`) has no storage and checks nothing.
* The password cannot be changed in place: export the records, delete the
  database and import them through a factory with the new password.
* Open a database always with the codec, or never: the same file opened
  without it is refused (`errInvalidCodec`) and cannot be read.
* New local database code: prefer sdb (`package:idb_shim/sdb.dart`), this
  package is for the apps already on sembast.

## Agent skill

[skills/tekartik-app-sembast-secure-codec](skills/tekartik-app-sembast-secure-codec/SKILL.md).
