import 'dart:convert';
import 'dart:typed_data';

import 'pb_model.dart';

/// How deep groups may nest before the input is refused (protobuf's own
/// default recursion limit).
const pbMaxGroupDepth = 100;

/// Bytes that are not valid protobuf wire format.
class PbFormatException extends FormatException {
  /// [message] about the input, at [offset] when known.
  PbFormatException(super.message, [super.source, super.offset]);
}

/// Reads the protobuf wire format, without any schema.
///
/// Platform safe: 64-bit values are read as two 32-bit halves, so they are
/// exact with dart2js too.
class PbReader {
  final Uint8List _bytes;
  final int _end;
  int _offset;

  /// Reader of [bytes] from [start] to [end] (the end of [bytes] by default).
  PbReader(Uint8List bytes, [int start = 0, int? end])
    : _bytes = bytes,
      _offset = start,
      _end = end ?? bytes.length {
    RangeError.checkValidRange(start, _end, bytes.length);
  }

  /// Where the next read starts.
  int get offset => _offset;

  /// True when everything was read.
  bool get isAtEnd => _offset >= _end;

  Never _fail(String message, [int? offset]) =>
      throw PbFormatException(message, null, offset ?? _offset);

  int _readByte() {
    if (_offset >= _end) {
      _fail('unexpected end of input');
    }
    return _bytes[_offset++];
  }

  /// Reads a varint of at most 32 bits (a tag, a length).
  int _readVarint32() {
    var start = _offset;
    var value = _readVarint();
    if (value.hi != 0) {
      _fail('varint too large', start);
    }
    return value.lo;
  }

  /// Reads a varint.
  PbVarint readVarint() => _readVarint();

  PbVarint _readVarint() {
    var start = _offset;
    var lo = 0;
    // The first 4 bytes fill bits 0 to 27.
    for (var factor = 1; factor < 0x10000000; factor *= 0x80) {
      var byte = _readByte();
      lo += (byte & 0x7f) * factor;
      if (byte < 0x80) {
        return PbVarint(lo, 0);
      }
    }
    // The 5th one fills bits 28 to 31, and 0 to 2 of the high half.
    var byte = _readByte();
    lo += (byte & 0x0f) * 0x10000000;
    var hi = (byte & 0x7f) >> 4;
    if (byte < 0x80) {
      return PbVarint(lo, hi);
    }
    // The 5 next ones fill bits 3 to 31 of the high half (the 10th one has
    // only bit 63 to give, extra bits are dropped like protobuf does).
    for (var factor = 0x8; factor <= 0x80000000; factor *= 0x80) {
      byte = _readByte();
      var bits = factor == 0x80000000 ? byte & 0x01 : byte & 0x7f;
      hi += bits * factor;
      if (byte < 0x80) {
        return PbVarint(lo, hi);
      }
    }
    _fail('varint longer than 10 bytes', start);
  }

  /// Reads 4 little endian bytes as an unsigned int.
  int _readUint32() {
    if (_end - _offset < 4) {
      _fail('unexpected end of input');
    }
    var bytes = _bytes;
    var offset = _offset;
    _offset += 4;
    return bytes[offset] +
        bytes[offset + 1] * 0x100 +
        bytes[offset + 2] * 0x10000 +
        bytes[offset + 3] * 0x1000000;
  }

  /// Reads a fixed32 value.
  PbFixed32 readFixed32() => PbFixed32(_readUint32());

  /// Reads a fixed64 value.
  PbFixed64 readFixed64() {
    var lo = _readUint32();
    return PbFixed64(lo, _readUint32());
  }

  /// Reads a length delimited value: its length, then that many bytes,
  /// returned as a view on the input.
  Uint8List readLengthDelimited() {
    var start = _offset;
    var length = _readVarint32();
    if (length > _end - _offset) {
      _fail('length $length beyond the end of input', start);
    }
    var bytes = Uint8List.sublistView(_bytes, _offset, _offset + length);
    _offset += length;
    return bytes;
  }

  /// Reads a tag: the field number and the wire type of the value that
  /// follows.
  ({int number, PbWireType wireType}) readTag() {
    var start = _offset;
    var tag = _readVarint32();
    var number = tag ~/ 8;
    var wireType = PbWireType.fromId(tag & 7);
    if (wireType == null) {
      _fail('invalid wire type ${tag & 7}', start);
    }
    if (number == 0) {
      _fail('invalid field number 0', start);
    }
    return (number: number, wireType: wireType);
  }

  /// Reads the fields up to the end of the input.
  PbMessage readMessage() => _readFields(null, 0);

  /// Reads fields up to the end of the input, or up to the end tag of
  /// [groupNumber] when reading a group.
  PbMessage _readFields(int? groupNumber, int depth) {
    var fields = <PbField>[];
    while (true) {
      if (isAtEnd) {
        if (groupNumber != null) {
          _fail('group $groupNumber not ended');
        }
        return PbMessage(fields);
      }
      var tagOffset = _offset;
      var (:number, :wireType) = readTag();
      PbValue value;
      switch (wireType) {
        case PbWireType.varint:
          value = _readVarint();
        case PbWireType.fixed64:
          value = readFixed64();
        case PbWireType.lengthDelimited:
          value = PbBytes(readLengthDelimited());
        case PbWireType.fixed32:
          value = readFixed32();
        case PbWireType.startGroup:
          if (depth >= pbMaxGroupDepth) {
            _fail('groups nested too deep', tagOffset);
          }
          value = PbGroup(_readFields(number, depth + 1));
        case PbWireType.endGroup:
          if (number != groupNumber) {
            _fail('unexpected end of group $number', tagOffset);
          }
          return PbMessage(fields);
      }
      fields.add(PbField(number, value));
    }
  }
}

Uint8List _asUint8List(List<int> bytes) =>
    bytes is Uint8List ? bytes : Uint8List.fromList(bytes);

/// Decodes [bytes] as a message, without any schema.
///
/// Length delimited values are kept as [PbBytes]: see
/// [PbLengthDelimitedReaderExt] to read them as strings, embedded messages or
/// packed values. Throws a [PbFormatException] when [bytes] is not valid wire
/// format.
PbMessage pbDecodeMessage(List<int> bytes) =>
    PbReader(_asUint8List(bytes)).readMessage();

/// Decodes [bytes] as a message, null when it is not valid wire format.
PbMessage? pbTryDecodeMessage(List<int> bytes) {
  try {
    return pbDecodeMessage(bytes);
  } on FormatException {
    return null;
  }
}

/// What a length delimited value most likely holds.
enum PbBytesKind {
  /// Utf8 text.
  string,

  /// An embedded message.
  message,

  /// Anything else: raw bytes, packed values...
  bytes,
}

/// [bytes] decoded as strict utf8, null when it is not.
String? _tryUtf8(Uint8List bytes) {
  try {
    return const Utf8Decoder().convert(bytes);
  } on FormatException {
    return null;
  }
}

/// True when [text] has no control character, but the [tab, newline and
/// carriage return] ones when [allowWhitespace] is true.
bool _isPlainText(String text, {required bool allowWhitespace}) {
  for (var unit in text.codeUnits) {
    if (unit < 0x20 || unit == 0x7f) {
      if (allowWhitespace && (unit == 0x09 || unit == 0x0a || unit == 0x0d)) {
        continue;
      }
      return false;
    }
  }
  return true;
}

/// Guesses what the length delimited [bytes] hold, the wire not saying.
///
/// Text without control characters is a string (an embedded message almost
/// always has one in its tags or lengths); then anything that decodes is a
/// message; then utf8 text with line breaks or tabs is a string; anything else
/// is bytes. Short texts can decode as messages and some messages read as
/// text: when it matters, decode the way the schema says.
PbBytesKind pbGuessBytesKind(Uint8List bytes) {
  if (bytes.isEmpty) {
    return PbBytesKind.string;
  }
  var text = _tryUtf8(bytes);
  if (text != null && _isPlainText(text, allowWhitespace: false)) {
    return PbBytesKind.string;
  }
  var message = pbTryDecodeMessage(bytes);
  if (message != null) {
    return PbBytesKind.message;
  }
  if (text != null && _isPlainText(text, allowWhitespace: true)) {
    return PbBytesKind.string;
  }
  return PbBytesKind.bytes;
}

/// Reading a length delimited value as what the schema would say it is.
extension PbLengthDelimitedReaderExt on PbLengthDelimited {
  /// The bytes of a read value, null for a message built in memory.
  Uint8List? get rawBytes => switch (this) {
    PbBytes(:var bytes) => bytes,
    PbEmbedded() => null,
  };

  /// What the value most likely holds, see [pbGuessBytesKind].
  PbBytesKind guessKind() => switch (this) {
    PbBytes(:var bytes) => pbGuessBytesKind(bytes),
    PbEmbedded() => PbBytesKind.message,
  };

  /// The value as an embedded message, null when it is not one.
  PbMessage? tryDecodeMessage() => switch (this) {
    PbBytes(:var bytes) => pbTryDecodeMessage(bytes),
    PbEmbedded(:var message) => message,
  };

  /// The value as a string (strict utf8), null when it is not one.
  String? tryDecodeString() => switch (this) {
    PbBytes(:var bytes) => _tryUtf8(bytes),
    PbEmbedded() => null,
  };

  /// The value as packed varints (repeated scalar numbers, enums, bools),
  /// null when it is not.
  List<PbVarint>? tryDecodePackedVarints() =>
      _tryPacked((reader) => reader.readVarint());

  /// The value as packed fixed32 values (repeated fixed32, sfixed32, float),
  /// null when it is not.
  List<PbFixed32>? tryDecodePackedFixed32() {
    var bytes = rawBytes;
    if (bytes == null || bytes.length % 4 != 0) {
      return null;
    }
    return _tryPacked((reader) => reader.readFixed32());
  }

  /// The value as packed fixed64 values (repeated fixed64, sfixed64,
  /// double), null when it is not.
  List<PbFixed64>? tryDecodePackedFixed64() {
    var bytes = rawBytes;
    if (bytes == null || bytes.length % 8 != 0) {
      return null;
    }
    return _tryPacked((reader) => reader.readFixed64());
  }

  List<T>? _tryPacked<T>(T Function(PbReader reader) read) {
    var bytes = rawBytes;
    if (bytes == null) {
      return null;
    }
    var reader = PbReader(bytes);
    var values = <T>[];
    try {
      while (!reader.isAtEnd) {
        values.add(read(reader));
      }
    } on FormatException {
      return null;
    }
    return values;
  }
}

/// Reading the fields of a message as what the schema would say they are.
///
/// Each getter reads the last field of the number (the one a parser keeps for
/// a non repeated field) and returns null when it is missing or not of the
/// expected kind; the plural ones read every field of the number.
extension PbMessageReaderExt on PbMessage {
  /// Field [number] as a string.
  String? stringValue(int number) => switch (valueOf(number)) {
    PbLengthDelimited value => value.tryDecodeString(),
    _ => null,
  };

  /// The fields [number] as strings, the ones that are not left out.
  List<String> stringValues(int number) => [
    for (var value in valuesOf(number).whereType<PbLengthDelimited>())
      ?value.tryDecodeString(),
  ];

  /// Field [number] as an int (int32, int64, uint32, enum, fixed32, fixed64,
  /// sfixed64; sfixed32 needs `PbFixed32.toInt32`).
  int? intValue(int number) => switch (valueOf(number)) {
    PbVarint value => value.toInt(),
    PbFixed64 value => value.toInt(),
    PbFixed32 value => value.toUint32(),
    _ => null,
  };

  /// Field [number] as a bool.
  bool? boolValue(int number) => switch (valueOf(number)) {
    PbVarint value => value.toBool(),
    _ => null,
  };

  /// Field [number] as a double (double, float).
  double? doubleValue(int number) => switch (valueOf(number)) {
    PbFixed64 value => value.toDouble(),
    PbFixed32 value => value.toFloat(),
    _ => null,
  };

  /// Field [number] as raw bytes.
  Uint8List? bytesValue(int number) => switch (valueOf(number)) {
    PbLengthDelimited value => value.rawBytes,
    _ => null,
  };

  /// Field [number] as an embedded message (or a group).
  PbMessage? messageValue(int number) => switch (valueOf(number)) {
    PbLengthDelimited value => value.tryDecodeMessage(),
    PbGroup(:var message) => message,
    _ => null,
  };

  /// The fields [number] as embedded messages (or groups), the ones that are
  /// not left out.
  List<PbMessage> messageValues(int number) => [
    for (var value in valuesOf(number))
      ?switch (value) {
        PbLengthDelimited value => value.tryDecodeMessage(),
        PbGroup(:var message) => message,
        _ => null,
      },
  ];
}
