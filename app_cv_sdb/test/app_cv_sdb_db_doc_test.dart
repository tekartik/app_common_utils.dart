import 'package:idb_shim/utils/sdb_import_export.dart';
import 'package:tekartik_app_cv_sdb/app_cv_sdb.dart';

import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:test/test.dart';

/// Record with an int key
class DbNote extends ScvIntRecordBase {
  final title = CvField<String>('title');
  final description = CvField<String>('description');
  final timestamp = CvField<SdbTimestamp>('timestamp');

  @override
  List<CvField> get fields => [title, description, timestamp];
}

final dbNoteStore = scvIntStoreFactory.store<DbNote>('note');
final dbTimestampIndex = dbNoteStore.index<SdbTimestamp>('timestamp_index');
var dbSchema = SdbDatabaseSchema(
  stores: [
    dbNoteStore.schema(
      indexes: [dbTimestampIndex.schema(keyPath: 'timestamp')],
    ),
  ],
);

extension DbNoteExt on SdbDatabase {
  Future<List<DbNote>> getNotes() => dbNoteStore.findRecords(this);
}

Future<void> main() async {
  cvAddConstructors([DbNote.new]);
  group('doc', () {
    late SdbDatabase db;
    setUp(() async {
      db = await newSdbFactoryMemory().openDatabase(
        'doc_test.db',
        options: SdbOpenDatabaseOptions(version: 1, schema: dbSchema),
      );
    });
    tearDown(() async {
      await db.close();
    });
    test('add 1 record', () async {
      await dbNoteStore
          .record(1)
          .put(
            db,
            DbNote()
              ..title.v = 'note 1'
              ..description.v = 'description 1'
              ..timestamp.v = SdbTimestamp.now(),
          );
      // ignore: avoid_print
      print((await sdbExportDatabaseLines(db)).join('\n'));
    });
  });
}
