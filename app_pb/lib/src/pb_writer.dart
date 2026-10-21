import 'dart:typed_data';

import 'pb_model.dart';

/// Writes the protobuf wire format, without any schema.
///
/// Platform safe: 64-bit values are written from their two 32-bit halves, so
/// they are exact with dart2js too.
class PbWriter {
  var _buffer = Uint8List(256);
  var _length = 0;

  /// How many bytes were written.
  int get length => _length;

  void _ensure(int count) {
    var needed = _length + count;
    if (needed > _buffer.length) {
      var size = _buffer.length * 2;
      while (size < needed) {
        size *= 2;
      }
      _buffer = Uint8List(size)..setRange(0, _length, _buffer);
    }
  }

  /// Writes a non negative [value] below 2^32 (a tag, a length) as a varint.
  void _writeVarint32(int value) {
    _ensure(5);
    while (value >= 0x80) {
      _buffer[_length++] = (value & 0x7f) | 0x80;
      value = value ~/ 0x80;
    }
    _buffer[_length++] = value;
  }

  /// Writes [value] as a varint.
  void writeVarint(PbVarint value) {
    var lo = value.lo;
    var hi = value.hi;
    if (hi == 0) {
      _writeVarint32(lo);
      return;
    }
    _ensure(10);
    while (hi > 0 || lo >= 0x80) {
      _buffer[_length++] = (lo & 0x7f) | 0x80;
      // Shifts the 64 bits right by 7, the low 7 bits of the high half going
      // to the top of the low half.
      lo = lo ~/ 0x80 + (hi & 0x7f) * 0x2000000;
      hi = hi ~/ 0x80;
    }
    _buffer[_length++] = lo;
  }

  void _writeUint32(int value) {
    _ensure(4);
    _buffer[_length++] = value & 0xff;
    _buffer[_length++] = (value ~/ 0x100) & 0xff;
    _buffer[_length++] = (value ~/ 0x10000) & 0xff;
    _buffer[_length++] = (value ~/ 0x1000000) & 0xff;
  }

  /// Writes [value] as 4 little endian bytes.
  void writeFixed32(PbFixed32 value) => _writeUint32(value.value);

  /// Writes [value] as 8 little endian bytes.
  void writeFixed64(PbFixed64 value) {
    _writeUint32(value.lo);
    _writeUint32(value.hi);
  }

  /// Writes [bytes] as they are.
  void writeRawBytes(List<int> bytes) {
    _ensure(bytes.length);
    _buffer.setRange(_length, _length + bytes.length, bytes);
    _length += bytes.length;
  }

  /// Writes the length of [bytes] then [bytes].
  void writeLengthDelimited(List<int> bytes) {
    _writeVarint32(bytes.length);
    writeRawBytes(bytes);
  }

  /// Writes the tag of field [number] with a value of [wireType].
  void writeTag(int number, PbWireType wireType) {
    pbCheckFieldNumber(number);
    // number << 3 | wireType, without a 32-bit overflow on the web.
    _writeVarint32(number * 8 + wireType.id);
  }

  /// Writes [field]: its tag then its value.
  void writeField(PbField field) {
    var number = field.number;
    var value = field.value;
    if (value is PbGroup) {
      writeTag(number, PbWireType.startGroup);
      writeMessage(value.message);
      writeTag(number, PbWireType.endGroup);
      return;
    }
    writeTag(number, value.wireType);
    switch (value) {
      case PbVarint value:
        writeVarint(value);
      case PbFixed64 value:
        writeFixed64(value);
      case PbFixed32 value:
        writeFixed32(value);
      case PbBytes(:var bytes):
        writeLengthDelimited(bytes);
      case PbEmbedded(:var message):
        writeLengthDelimited(pbEncodeMessage(message));
      case PbGroup():
      // Written above.
    }
  }

  /// Writes the fields of [message], with no length before them.
  void writeMessage(PbMessage message) {
    for (var field in message.fields) {
      writeField(field);
    }
  }

  /// A copy of what was written.
  Uint8List toBytes() => _buffer.sublist(0, _length);
}

/// [message] in the protobuf wire format.
///
/// A read message encodes back to the bytes it was decoded from, as long as
/// these were canonical (no over long varint, as every protobuf encoder
/// writes them).
Uint8List pbEncodeMessage(PbMessage message) =>
    (PbWriter()..writeMessage(message)).toBytes();

/// Encoding a message.
extension PbMessageWriterExt on PbMessage {
  /// This message in the protobuf wire format.
  Uint8List toBytes() => pbEncodeMessage(this);
}
