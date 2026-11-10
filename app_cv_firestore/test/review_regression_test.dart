import 'dart:async';

import 'package:tekartik_app_cv_firestore/app_cv_firestore_v2.dart';
import 'package:tekartik_firebase_firestore/utils/track_changes_support.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:test/test.dart';

class _CvText extends CvFirestoreDocumentBase {
  final text = CvField<String>('text');

  @override
  List<CvField> get fields => [text];
}

void main() {
  cvFirestoreAddBuilder<_CvText>((_) => _CvText());
  late Firestore firestore;
  final collection = CvCollectionReference<_CvText>('review');

  setUp(() async {
    firestore = newFirestoreMemory();
    await firestore.cvSet(collection.doc('a').cv()..text.v = 'a');
  });

  /// A query refused by the backend (inequality on a field not ordered,
  /// checked in debug mode by the in memory implementations).
  CvQueryReference<_CvText> invalidQuery() =>
      collection.query().where('text', isGreaterThan: 'a').orderBy('other');

  group('CvQueryReference.onSnapshots', () {
    test('query error reaches the listener', () async {
      await expectLater(
        invalidQuery()
            .onSnapshots(firestore)
            .first
            .timeout(const Duration(seconds: 5)),
        throwsA(isNot(isA<TimeoutException>())),
      );
    });

    test('query error reaches the listener, polling', () async {
      firestore.service.sembastSupportsTrackChanges = false;
      await expectLater(
        invalidQuery()
            .onSnapshots(firestore)
            .first
            .timeout(const Duration(seconds: 5)),
        throwsA(isNot(isA<TimeoutException>())),
      );
    });

    test('first() closes the stream, polling', () async {
      firestore.service.sembastSupportsTrackChanges = false;
      var list = await collection
          .query()
          .onSnapshotsSupport(
            firestore,
            options: TrackChangesSupportOptions.first(),
          )
          .toList()
          .timeout(const Duration(seconds: 5));
      expect(list, hasLength(1));
      expect(list.first.map((doc) => doc.id), ['a']);
    });

    test('cancel stops the events', () async {
      var events = <List<_CvText>>[];
      var first = Completer<void>();
      var subscription = collection.query().onSnapshots(firestore).listen((
        list,
      ) {
        events.add(list);
        if (!first.isCompleted) {
          first.complete();
        }
      });
      await first.future.timeout(const Duration(seconds: 5));
      await subscription.cancel();
      await firestore.cvSet(collection.doc('b').cv()..text.v = 'b');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(events, hasLength(1));
    });
  }, timeout: const Timeout(Duration(seconds: 20)));
}
