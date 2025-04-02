import 'dart:convert';

import 'package:sembast/utils/type_adapter.dart';
import 'package:tekartik_app_sembast_firestore_type_adapters/src/mixin.dart';
import 'package:tekartik_firebase_firestore/firestore.dart' show Blob;

class _FirestoreBlobAdapter extends SembastTypeAdapter<Blob, String>
    with TypeAdapterCodecMixin<Blob, String> {
  _FirestoreBlobAdapter() {
    // Encode to string
    encoder = TypeAdapterConverter<Blob, String>(
      (blob) => base64Encode(blob.data),
    );
    // Decode from string
    decoder = TypeAdapterConverter<String, Blob>(
      (text) => Blob(base64Decode(text)),
    );
  }

  @override
  String get name => 'FirestoreBlob';
}

/// Firestore blob adapter.
///
/// Convert a blob to a Base64 encoded string.
final SembastTypeAdapter<Blob, String> sembastFirestoreBlobAdapter =
    _FirestoreBlobAdapter();
