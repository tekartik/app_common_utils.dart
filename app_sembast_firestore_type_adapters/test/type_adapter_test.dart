import 'dart:typed_data';

import 'package:tekartik_app_sembast_firestore_type_adapters/type_adapters.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:test/test.dart';

void main() {
  group('type_adapters', () {
    test('Timestamp', () {
      expect(
          sembastFirestoreTimestampAdapter
              .encode(Timestamp.fromMillisecondsSinceEpoch(1)),
          {'seconds': 0, 'nanoseconds': 1000000});

      expect(sembastFirestoreTimestampAdapter.encode(Timestamp(1234, 5678)),
          {'seconds': 1234, 'nanoseconds': 5678});

      expect(
          sembastFirestoreTimestampAdapter
              .decode({'seconds': 0, 'nanoseconds': 1000000}),
          Timestamp.fromMillisecondsSinceEpoch(1));
      expect(
          sembastFirestoreTimestampAdapter
              .decode({'seconds': 1234, 'nanoseconds': 5678}),
          Timestamp(1234, 5678));
    });

    test('Blob', () {
      expect(
          sembastFirestoreBlobAdapter
              .encode(Blob(Uint8List.fromList([1, 2, 3]))),
          'AQID');

      expect(sembastFirestoreBlobAdapter.decode('AQID'),
          Blob(Uint8List.fromList([1, 2, 3])));
    });
    test('GeoPoint', () {
      expect(sembastFirestoreGeoPointAdapter.encode(const GeoPoint(1, 2)),
          {'latitude': 1.0, 'longitude': 2.0});

      expect(sembastFirestoreGeoPointAdapter.encode(const GeoPoint(1.1, 2.2)),
          {'latitude': 1.1, 'longitude': 2.2});

      expect(
          sembastFirestoreGeoPointAdapter
              .decode({'latitude': 1, 'longitude': 2}),
          const GeoPoint(1, 2));
      expect(
          sembastFirestoreGeoPointAdapter
              .decode({'latitude': 1.1, 'longitude': 2.2}),
          const GeoPoint(1.1, 2.2));
    });
  });
}
