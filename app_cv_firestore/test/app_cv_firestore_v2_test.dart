import 'package:path/path.dart';
import 'package:tekartik_app_cv/app_cv_v2.dart';
import 'package:tekartik_app_cv_firestore/app_cv_firestore_v2.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:test/test.dart';

class CvFsEmpty extends CvFirestoreDocumentBase {
  @override
  List<CvField> get fields => [];
}

class CvFsSingleString extends CvFirestoreDocumentBase {
  final text = CvField<String>('text');

  @override
  List<CvField> get fields => [text];
}

class CvFsAllFields extends CvFirestoreDocumentBase {
  final intValue = CvField<int>('intValue');

  @override
  List<CvField> get fields => [intValue];
}

void initBuilders() {
  cvFirestoreAddBuilder<CvFsEmpty>((_) => CvFsEmpty());
  cvFirestoreAddBuilder<CvFsSingleString>((_) => CvFsSingleString());
  cvFirestoreAddBuilder<CvFirestoreMapDocument>(
      (_) => CvFirestoreMapDocument());
}

void main() {
  group('builder', () {
    late Firestore firestore;
    setUpAll(() {
      initBuilders();
    });
    setUp(() {
      firestore = newFirestoreMemory();
    });
    test('get/set empty', () async {
      try {
        // ignore: unnecessary_statements
        CvFsEmpty().exists;
        fail('shoud fail');
      } catch (e) {
        expect(e, isNot(const TypeMatcher<TestFailure>()));
      }
      var snapshot = await firestore.doc('test/1').get();
      expect(snapshot.cv<CvFsEmpty>(), CvFsEmpty()..path = 'test/1');
      expect(snapshot.ref.path, 'test/1');
      expect(snapshot.cv<CvFsEmpty>().exists, false);

      var cvFsEmpty = await firestore.cvGet<CvFsEmpty>('test/1');
      expect(cvFsEmpty, CvFsEmpty()..path = 'test/1');
      expect(cvFsEmpty.path, 'test/1');
      expect(cvFsEmpty.exists, false);
      expect(cvFsEmpty.toModel(), {});

      await firestore.cvSet(cvFsEmpty);
      cvFsEmpty = await firestore.cvGet<CvFsEmpty>('test/1');
      expect(cvFsEmpty, CvFsEmpty()..path = 'test/1');
      expect(cvFsEmpty.path, 'test/1');
      expect(cvFsEmpty.exists, true);
      expect(cvFsEmpty.toModel(), {});

      await firestore.cvSet(cvFsEmpty);
    });

    test('delete', () async {
      var cvFsEmpty = CvFsEmpty()..path = 'test/1';
      await firestore.cvSet(cvFsEmpty);
      cvFsEmpty = await firestore.cvGet<CvFsEmpty>('test/1');
      expect(cvFsEmpty.exists, true);
      expect(cvFsEmpty.toModel(), {});

      await firestore.docDelete(cvFsEmpty);
      cvFsEmpty = await firestore.cvGet<CvFsEmpty>('test/1');
      expect(cvFsEmpty.exists, false);
    });

    test('missing path', () async {
      // No path set
      var cvFsEmpty = CvFsEmpty();
      try {
        await firestore.cvSet(cvFsEmpty);
        fail('should fail');
      } on ArgumentError catch (_) {}
      try {
        await firestore.cvUpdate(cvFsEmpty);
        fail('should fail');
      } on ArgumentError catch (_) {}

      await firestore.cvRunTransaction((transaction) {
        try {
          transaction.cvSet(cvFsEmpty);
          fail('should fail');
        } on ArgumentError catch (_) {}
        try {
          transaction.cvUpdate(cvFsEmpty);
          fail('should fail');
        } on ArgumentError catch (_) {}
      });

      var batch = firestore.cvBatch();
      try {
        batch.cvSet(cvFsEmpty);
        fail('should fail');
      } on ArgumentError catch (_) {}
      try {
        batch.cvUpdate(cvFsEmpty);
        fail('should fail');
      } on ArgumentError catch (_) {}
    });

    test('model', () async {
      var doc = CvFsSingleString();
      expect(doc.idOrNull, null);
      expect(doc.pathOrNull, null);
      try {
        doc.id;
        fail('should fail');
      } catch (e) {
        expect(e, isNot(const TypeMatcher<TestFailure>()));
      }
      try {
        doc.path;
        fail('should fail');
      } catch (e) {
        expect(e, isNot(const TypeMatcher<TestFailure>()));
      }

      doc.path = 'test/id';
      expect(doc.pathOrNull, 'test/id');
      expect(doc.idOrNull, 'id');
      expect(doc.path, 'test/id');
      expect(doc.id, 'id');
    });

    test('single string', () async {
      void check(CvFsSingleString doc) {
        expect(doc.exists, isTrue);
        expect(doc.path, 'test/single_string');
        expect(doc.toModel(), {'text': 'value'});
      }

      var doc = CvFsSingleString()
        ..path = 'test/single_string'
        ..text.v = 'value';
      try {
        // ignore: unnecessary_statements
        doc.exists;
        fail('shoud fail');
      } catch (e) {
        expect(e, isNot(const TypeMatcher<TestFailure>()));
      }
      expect(doc.path, 'test/single_string');
      expect(doc.toModel(), {'text': 'value'});
      await firestore.cvSet(doc);
      var readDoc = await firestore.cvGet<CvFsSingleString>(doc.path);
      check(readDoc);

      readDoc = await firestore.doc(doc.path).cvGet<CvFsSingleString>();
      check(readDoc);

      var snapshots =
          await firestore.collection('test').cvGet<CvFsSingleString>();
      expect(snapshots, [doc]);
      check(snapshots.first);

      snapshots =
          await firestore.collection('test').limit(1).cvGet<CvFsSingleString>();
      expect(snapshots, [doc]);
      check(snapshots.first);

      await firestore.cvRunTransaction((transaction) async {
        readDoc = await transaction.cvGet(doc.path);
        check(readDoc);

        //transaction.pathDelete(doc.path);
        transaction.docDelete(readDoc);
      });
      doc = CvFsSingleString()
        ..path = 'test/single_string'
        ..text.v = 'value2';

      await firestore.cvRunTransaction((transaction) async {
        readDoc = await transaction.cvGet(doc.path);
        expect(readDoc.exists, isFalse);

        transaction.cvSet(doc);
      });
      doc = CvFsSingleString()
        ..path = 'test/single_string'
        ..text.v = 'value3';
      await firestore.cvRunTransaction((transaction) async {
        var doc = CvFsSingleString()
          ..path = 'test/single_string'
          ..text.v = 'value3';
        readDoc = await transaction.cvGet(doc.path);
        expect(readDoc.exists, isTrue);
        transaction.cvUpdate(doc);
      });

      readDoc = await firestore.cvGet<CvFsSingleString>(doc.path);
      expect(readDoc, CvFsSingleString()..text.v = 'value3');
    });
    test('add update string', () async {
      var doc = CvFsSingleString()..text.v = 'value';
      doc = await firestore.cvAdd('test', doc);
      var readDoc = await firestore.cvGet<CvFsSingleString>(doc.path);
      expect(readDoc, doc);
      expect(readDoc.path, doc.path);
      doc.text.v = 'value2';
      await firestore.cvUpdate(doc);
      readDoc = await firestore.cvGet<CvFsSingleString>(doc.path);
      expect(readDoc, doc);
      expect(readDoc.path, doc.path);
    });

    test('batch', () async {
      var doc = CvFsSingleString()
        ..path = 'batch/single_string'
        ..text.v = 'value';
      var batch = firestore.cvBatch();
      batch.cvSet(doc);
      await batch.commit();

      var readDoc = await firestore.cvGet<CvFsSingleString>(doc.path);
      expect(readDoc, doc);

      batch = firestore.cvBatch();
      batch.cvUpdate(doc..text.v = 'new value');
      await batch.commit();

      readDoc = await firestore.cvGet<CvFsSingleString>(doc.path);
      expect(readDoc, doc);

      batch = firestore.cvBatch();
      batch.cvDelete(doc.path);
      await batch.commit();

      readDoc = await firestore.cvGet<CvFsSingleString>(doc.path);
      expect(readDoc.exists, isFalse);
    });

    test('api', () {
      // ignore: unnecessary_statements
      CvFirestoreWriteBatch;
      // ignore: unnecessary_statements
      CvFirestoreTransaction;
    });

    test('onSnapshot', () async {
      var doc = CvFsSingleString()
        ..path = 'test/single_string'
        ..text.v = 'value';

      await firestore.cvSet(doc);
      expect(
          await firestore.doc(doc.path).cvOnSnapshot<CvFsSingleString>().first,
          doc);
      expect(
          await firestore
              .collection(url.dirname(doc.path))
              .cvOnSnapshots<CvFsSingleString>()
              .first,
          [doc]);
    });

    test('collection', () async {
      var collection = CvCollectionReference<CvFsSingleString>('test');
      var docRef = collection.doc('1');
      expect(docRef.path, 'test/1');
      expect(await collection.get(firestore), []);
      var doc = docRef.cv()..text.v = 'value';
      await firestore.cvSet(doc);
      expect(await collection.get(firestore), [doc]);
      //var doc = docRef.cv();
      expect(doc.id, '1');
      // Create a new record
      doc = await collection.add(firestore, doc);
      expect(doc.id, isNot('1'));
    });

    test('document', () async {
      var docRef = CvDocumentReference<CvFsSingleString>('test/1');
      expect(docRef.path, 'test/1');
      var doc = docRef.cv();
      doc.text.v = 'value';
      await firestore.cvSet(doc);
      expect(await docRef.get(firestore), doc);

      await firestore.cvRunTransaction((transaction) async {
        expect(await transaction.refGet(docRef), doc);
      });

      expect(docRef.collection('sub').path, 'test/1/sub');
    });

    test('document.set', () async {
      var docRef = CvDocumentReference<CvFsSingleString>('test/set');

      var doc = docRef.cv();
      doc.text.v = 'value';
      await docRef.set(firestore, doc);
      expect(await docRef.get(firestore), doc);
    });

    test('query', () async {
      var collection = CvCollectionReference<CvFsSingleString>('test');
      var query = collection.query().where('text', isEqualTo: 'value');
      var docRef = collection.doc('1');
      expect(docRef.path, 'test/1');
      expect((await query.onSnapshots(firestore).first), isEmpty);
      expect(await collection.get(firestore), []);
      expect(await collection.count(firestore), 0);
      var doc = docRef.cv()..text.v = 'value';
      await firestore.cvSet(doc);
      expect((await query.onSnapshots(firestore).first), [doc]);
      expect(await query.count(firestore), 1);
      doc = docRef.cv()..text.v = 'value2';
      await firestore.cvSet(doc);
      expect((await query.onSnapshots(firestore).first), isEmpty);
      expect(await query.count(firestore), 0);
    });

    test('extension', () {
      expect(
          asModel({'test': 1, 'value': 2})..withDelete(CvField<String>('test')),
          {'value': 2, 'test': FieldValue.delete});
      expect(
          asModel({'test': 1, 'value': 2})
            ..withServerTimestamp(CvField<Timestamp>('test')),
          {'value': 2, 'test': FieldValue.serverTimestamp});
      expect((FsTestWithTimestamp()..value.v = 1).toMapWithServerTimestamp(),
          {'value': 1, 'timestamp': FieldValue.serverTimestamp});
    });
  });
}

class FsTestWithTimestamp extends CvFirestoreDocumentBase
    with WithServerTimestampMixin {
  final value = CvField<int>('value');

  @override
  List<CvField> get fields => [...timedMixinFields, value];
}
