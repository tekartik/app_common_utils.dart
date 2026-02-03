import 'dart:convert';

import 'package:cv/cv.dart';
import 'package:sembast/blob.dart';
import 'package:sembast/timestamp.dart';
import 'package:tekartik_common_utils/byte_utils.dart';

class _TimestampToDateTimeConverter with Converter<Timestamp, DateTime> {
  const _TimestampToDateTimeConverter();
  @override
  DateTime convert(Timestamp input) => input.toDateTime(isUtc: true);
}

class _DateTimeToTimestampConverter with Converter<DateTime, Timestamp> {
  const _DateTimeToTimestampConverter();
  @override
  Timestamp convert(DateTime input) => Timestamp.fromDateTime(input);
}

/// Codec to convert timestamp to/from DateTime using the timestamp name.
class TimestampToDateTimeCodec with Codec<Timestamp, DateTime> {
  /// Create a codec for the given timestamp values.
  const TimestampToDateTimeCodec();
  @override
  Converter<DateTime, Timestamp> get decoder =>
      const _DateTimeToTimestampConverter();

  @override
  Converter<Timestamp, DateTime> get encoder =>
      const _TimestampToDateTimeConverter();
}

class _BlobToUint8ListConverter with Converter<Blob, List<int>> {
  const _BlobToUint8ListConverter();
  @override
  List<int> convert(Blob input) => input.bytes;
}

class _Uint8ListToBlobConverter with Converter<List<int>, Blob> {
  const _Uint8ListToBlobConverter();
  @override
  Blob convert(List<int> input) => Blob(asUint8List(input));
}

/// Codec to convert Blob to/from Uint8List using the blob name.
class BlobToUint8ListCodec with Codec<Blob, List<int>> {
  /// Create a codec for the given blob values.
  const BlobToUint8ListCodec();
  @override
  Converter<List<int>, Blob> get decoder => const _Uint8ListToBlobConverter();

  @override
  Converter<Blob, List<int>> get encoder => const _BlobToUint8ListConverter();
}

/// SCV Timestamp type alias for Sembast Timestamp (not coupled to Firebase nor Sembast)
typedef ScvTimestamp = Timestamp;

/// SCV Blob type alias for Sembast Blob (not coupled to Firebase nor Sembast)
typedef ScvBlob = Blob;

/// Timestamp field (as utc DateTime encoded)
CvField<ScvTimestamp> cvEncodedTimestampField(String name) =>
    CvField.encoded<ScvTimestamp, DateTime>(
      name,
      codec: const TimestampToDateTimeCodec(),
    );

/// Blob field (as uint8List encoded)
CvField<ScvBlob> cvEncodedBlobField(String name) =>
    CvField.encoded<ScvBlob, List<int>>(
      name,
      codec: const BlobToUint8ListCodec(),
    );
