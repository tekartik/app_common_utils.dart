import 'package:tekartik_app_cv/app_cv.dart';
import 'package:tekartik_app_cv_firestore/app_cv_firestore.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:test/test.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';

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

    test('single string', () async {
      void _check(CvFsSingleString doc) {
        expect(doc.exists, isTrue);
        expect(doc.path, 'test/single_string');
        expect(doc.toModel(), {'text': 'value'});
      }

      var doc = CvFsSingleString()
        ..path = 'test/single_string'
        ..text.v = 'value';
      try {
        doc.exists;
        fail('shoud fail');
      } catch (e) {
        expect(e, isNot(const TypeMatcher<TestFailure>()));
      }
      expect(doc.path, 'test/single_string');
      expect(doc.toModel(), {'text': 'value'});
      await firestore.cvSet(doc);
      var readDoc = await firestore.cvGet<CvFsSingleString>(doc.path);
      _check(readDoc);

      readDoc = await firestore.doc(doc.path).cvGet<CvFsSingleString>();
      _check(readDoc);

      var snapshots =
          await firestore.collection('test').cvGet<CvFsSingleString>();
      expect(snapshots, [doc]);
      _check(snapshots.first);

      snapshots =
          await firestore.collection('test').limit(1).cvGet<CvFsSingleString>();
      expect(snapshots, [doc]);
      _check(snapshots.first);

      await firestore.cvRunTransaction((transaction) async {
        readDoc = await transaction.cvGet(doc.path);
        _check(readDoc);

        transaction.cvDelete(doc.path);
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
  });
}
