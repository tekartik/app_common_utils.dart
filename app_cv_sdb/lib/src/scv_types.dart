import 'dart:convert';

import 'package:cv/cv.dart';
import 'package:sembast/timestamp.dart';

class _TimestampToStringConverter with Converter<Timestamp, String> {
  const _TimestampToStringConverter();
  @override
  String convert(Timestamp input) => input.toIso8601String();
}

class _StringToTimestampConverter with Converter<String, Timestamp> {
  const _StringToTimestampConverter();
  @override
  Timestamp convert(String input) => Timestamp.parse(input);
}

/// Codec to convert timestamp to/from string using the timestamp name.
class TimestampToStringCodec with Codec<Timestamp, String> {
  /// Create a codec for the given timestamp values.
  const TimestampToStringCodec();
  @override
  Converter<String, Timestamp> get decoder =>
      const _StringToTimestampConverter();

  @override
  Converter<Timestamp, String> get encoder =>
      const _TimestampToStringConverter();
}

/// SCV Timestamp type alias for Sembast Timestamp (not coupled to Firebase nor Sembast)
typedef ScvTimestamp = Timestamp;

/// Enum field, give a name and a list of possible values (such as `MyEnum.values`)
CvField<ScvTimestamp> cvEncodedTimestampField(String name) =>
    CvField.encoded<ScvTimestamp, String>(
      name,
      codec: const TimestampToStringCodec(),
    );
