/// Sembast type adapters for the tekartik_firebase_firestore `Timestamp`,
/// `Blob` and `GeoPoint`, and [sembastFirestoreCodec] to open a sembast
/// database storing them:
///
/// ```dart
/// var db = await factory.openDatabase('cache.db', codec: sembastFirestoreCodec);
/// ```
///
/// The codec replaces sembast's default adapters: sembast's own `Timestamp`
/// and `Blob` cannot be stored in such a database.
library;

import 'dart:convert';

import 'package:sembast/sembast.dart';
import 'package:sembast/utils/type_adapter.dart';
import 'package:tekartik_app_sembast_firestore_type_adapters/src/blob.dart';
import 'package:tekartik_app_sembast_firestore_type_adapters/src/geo_point.dart';
import 'package:tekartik_app_sembast_firestore_type_adapters/src/timestamp.dart';

export 'src/blob.dart' show sembastFirestoreBlobAdapter;
export 'src/geo_point.dart' show sembastFirestoreGeoPointAdapter;
export 'src/timestamp.dart' show sembastFirestoreTimestampAdapter;

/// Support Timestamp, Blob and GeoPoint
final sembastFirestoreDefaultTypeAdapters = [
  sembastFirestoreTimestampAdapter,
  sembastFirestoreBlobAdapter,
  sembastFirestoreGeoPointAdapter,
];

/// Default Firestore types jsonEncodableCodec
final sembastFirestoreDefaultJsonEncodableCodec = JsonEncodableCodec(
  adapters: sembastFirestoreDefaultTypeAdapters,
);

/// Firestore types support codec for sembast to use when opening the database
/// (at every open: its signature is `firestore`).
final sembastFirestoreCodec = SembastCodec(
  signature: 'firestore',
  codec: json,
  jsonEncodableCodec: sembastFirestoreDefaultJsonEncodableCodec,
);
