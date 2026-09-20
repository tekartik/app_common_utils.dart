---
name: tekartik-app-cv-sdb-schema-upgrade
description: >-
  Use when adding a test that freezes an sdb database schema
  (SdbOpenDatabaseOptions version, SdbDatabaseSchema stores and indexes) and
  verifies the upgrade from every previous version with
  ScvSchemaUpgradeValidator from
  package:tekartik_app_cv_sdb/test/scv_schema_upgrade_validator.dart:
  ScvSchemaUpgradeValidator(name:, path:), run(options:), the
  test/data/<name>_<version>.db golden files, kSdbDartIsWeb or @TestOn('vm'),
  bumping the version when the schema changes.
---

# Schema upgrade validation (tekartik_app_cv_sdb)

`ScvSchemaUpgradeValidator` records, in one sembast file per database
version, what an sdb database looks like right after being created with
your `SdbOpenDatabaseOptions`, then checks on every test run that the
current version has not changed since its file was committed and that
opening the file of every older version with the current options gives
exactly the same content. Any drift fails the test with a printed
`expected` / `new` dump.

## Guidelines

* Import `package:tekartik_app_cv_sdb/test/scv_schema_upgrade_validator.dart`
  from a test file. It uses `dart:io` and `sdbFactoryIo` (sembast files):
  VM only, so mark the file `@TestOn('vm')` or skip the test with
  `skip: kSdbDartIsWeb` (exported by `app_cv_sdb.dart`) as the package's
  own tests do.
* `ScvSchemaUpgradeValidator(name: 'app', path: 'test/data')`: `name` is
  the base name of the golden files, `path` defaults to `test/data`
  (relative to the package, where `dart test` runs). Files are named
  `<name>_<version>.db`.
* `await validator.run(options: options)` with the very
  `SdbOpenDatabaseOptions` (non null `version`) the app opens its database
  with; its `schema` (or `onVersionChange`) drives what gets created. For
  version `N`:
  * no `test/data/<name>_N.db` yet: a fresh database is opened and closed
    with `options` at that path, creating the golden file; commit it;
  * the file exists: its content is exported, the database is recreated
    from scratch and both exports must match, otherwise the old file is
    restored and a `StateError` is thrown. A committed version is frozen:
    to change the schema, bump `version` (a new golden file appears);
  * then for every older `<name>_M.db` found in `path`, a copy is opened
    with `options` under `.dart_tool/tekartik/` (migrating `M` to `N`) and
    its export must equal the fresh `N` export: a store or index the
    upgrade forgets to create, or a leftover it forgets to drop, fails
    here.
* Keep every `<name>_<version>.db` under version control (small sembast
  json line files); never edit them by hand, delete the current version's
  file only to regenerate it deliberately.
* Golden files hold the schema of an empty database: seed data inserted by
  `onVersionChange` is compared too, so keep such code deterministic (no
  timestamps, no random ids) or out of the validated options.
* Declare the options once (`appDbOptions`) in the library the app opens
  its database with, so the app and the test share them; the validator
  only needs the latest options plus the committed files of the older
  versions.
* The stores and indexes in the schema are the same `ScvStoreRef` /
  `ScvIndexRef` declarations used at runtime (see
  `tekartik-app-cv-sdb-records` and `tekartik-app-cv-sdb-index`).

## Examples

### VM only test of the latest schema

```dart
@TestOn('vm')
library;

import 'package:tekartik_app_cv_sdb/app_cv_sdb.dart';
import 'package:tekartik_app_cv_sdb/test/scv_schema_upgrade_validator.dart';
import 'package:test/test.dart';

class DbNote extends ScvIntRecordBase {
  final title = CvField<String>('title');
  final tag = CvField<String>('tag');

  @override
  List<CvField> get fields => [title, tag];
}

final noteStore = scvIntStoreFactory.store<DbNote>('note');
final noteByTag = noteStore.index<String>('tag');

/// Version 1 shipped a plain store, version 2 added the tag index.
final notesOptionsLatest = SdbOpenDatabaseOptions(
  version: 2,
  schema: SdbDatabaseSchema(
    stores: [
      noteStore.schema(
        autoIncrement: true,
        indexes: [noteByTag.schema(keyPath: DbNote().tag.name)],
      ),
    ],
  ),
);

void main() {
  test('notes schema upgrade', () async {
    // Creates test/data/notes_2.db on the first run, then validates it and
    // the upgrade from test/data/notes_1.db committed when version 1 shipped.
    await ScvSchemaUpgradeValidator(
      name: 'notes',
    ).run(options: notesOptionsLatest);
  });
}
```

### Shared options, multi platform test file

```dart
import 'package:tekartik_app_cv_sdb/app_cv_sdb.dart';
import 'package:tekartik_app_cv_sdb/test/scv_schema_upgrade_validator.dart';
import 'package:test/test.dart';

class DbUser extends ScvStringRecordBase {
  final email = CvField<String>('email');

  @override
  List<CvField> get fields => [email];
}

class DbSession extends ScvIntRecordBase {
  final userId = CvField<String>('user_id');

  @override
  List<CvField> get fields => [userId];
}

final userStore = scvStringStoreFactory.store<DbUser>('user');
final sessionStore = scvIntStoreFactory.store<DbSession>('session');
final sessionByUser = sessionStore.index<String>('user');

/// What the app opens; bump the version whenever the schema changes.
final appDbOptions = SdbOpenDatabaseOptions(
  version: 3,
  schema: SdbDatabaseSchema(
    stores: [
      userStore.schema(),
      sessionStore.schema(
        autoIncrement: true,
        indexes: [sessionByUser.schema(keyPath: DbSession().userId.name)],
      ),
    ],
  ),
);

Future<SdbDatabase> openAppDb(SdbFactory factory) =>
    factory.openDatabase('app.db', options: appDbOptions);

void main() {
  test('open', () async {
    var db = await openAppDb(newSdbFactoryMemory());
    await db.close();
  });

  // Golden files in test/data: app_1.db, app_2.db and app_3.db.
  test('schema upgrade', () async {
    await ScvSchemaUpgradeValidator(name: 'app').run(options: appDbOptions);
  }, skip: kSdbDartIsWeb);
}
```
