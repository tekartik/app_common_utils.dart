import 'dart:convert';
import 'dart:typed_data';

/// 2^32, the weight of the high half of a 64-bit value.
const _two32 = 0x100000000;

/// The highest field number the wire format allows (2^29 - 1).
const pbMaxFieldNumber = 0x1fffffff;

/// How a field value is laid out on the wire, the low 3 bits of its tag.
enum PbWireType {
  /// A base 128 varint: int32, int64, uint32, uint64, sint32, sint64, bool,
  /// enum.
  varint(0),

  /// 8 bytes, little endian: fixed64, sfixed64, double.
  fixed64(1),

  /// A varint length then that many bytes: string, bytes, embedded message,
  /// packed repeated field.
  lengthDelimited(2),

  /// The start of a group (deprecated proto2 feature).
  startGroup(3),

  /// The end of a group (deprecated proto2 feature).
  endGroup(4),

  /// 4 bytes, little endian: fixed32, sfixed32, float.
  fixed32(5);

  /// The value in the tag.
  final int id;

  const PbWireType(this.id);

  /// The wire type of [id], null for the unused 6 and 7.
  static PbWireType? fromId(int id) => switch (id) {
    0 => varint,
    1 => fixed64,
    2 => lengthDelimited,
    3 => startGroup,
    4 => endGroup,
    5 => fixed32,
    _ => null,
  };
}

/// Throws when [number] is not a valid field number.
void pbCheckFieldNumber(int number) {
  if (number < 1 || number > pbMaxFieldNumber) {
    throw ArgumentError.value(
      number,
      'number',
      'field number must be between 1 and $pbMaxFieldNumber',
    );
  }
}

/// Splits [value], a signed 64-bit int, into its unsigned 32-bit halves.
///
/// Platform safe: no bit operation is applied beyond 32 bits, so it is exact
/// with dart2js too (for ints that are exact there, within ±2^53).
(int lo, int hi) _splitInt(int value) {
  var lo = value & 0xffffffff;
  var hi = ((value - lo) ~/ _two32) & 0xffffffff;
  return (lo, hi);
}

final _minInt64 = -(BigInt.one << 63);
final _maxUint64 = (BigInt.one << 64) - BigInt.one;
final _mask32 = BigInt.from(0xffffffff);

/// Splits [value], from -2^63 to 2^64 - 1, into its unsigned 32-bit halves.
(int lo, int hi) _splitBigInt(BigInt value) {
  if (value < _minInt64 || value > _maxUint64) {
    throw ArgumentError.value(value, 'value', 'not a 64-bit value');
  }
  var bits = value.toUnsigned(64);
  return ((bits & _mask32).toInt(), (bits >> 32).toInt());
}

void _checkUint32(int value, String name) {
  if (value < 0 || value > 0xffffffff) {
    throw ArgumentError.value(value, name, 'not an unsigned 32-bit value');
  }
}

/// 64 bits held as two unsigned 32-bit halves, so that they are exact on
/// every platform, dart2js included.
///
/// The `to...` conversions follow the protobuf scalar types reading them.
mixin PbBits64 {
  /// The low 32 bits, unsigned.
  int get lo;

  /// The high 32 bits, unsigned.
  int get hi;

  /// The bits as an unsigned 64-bit integer (uint64, fixed64), exact
  /// everywhere.
  BigInt toUnsignedBigInt() => (BigInt.from(hi) << 32) | BigInt.from(lo);

  /// The bits as a two's complement signed 64-bit integer (int64, sfixed64),
  /// exact everywhere.
  BigInt toSignedBigInt() => toUnsignedBigInt().toSigned(64);

  /// The bits as a two's complement signed 64-bit int (int64, sfixed64).
  ///
  /// Exact on the VM and with dart2wasm; with dart2js a value beyond ±2^53 is
  /// rounded, use [toSignedBigInt] there.
  int toInt() {
    if (hi < 0x80000000) {
      return hi * _two32 + lo;
    }
    // -(~bits + 1), without any 64-bit bit operation.
    return -((0xffffffff - hi) * _two32 + (0xffffffff - lo) + 1);
  }

  /// The low 32 bits as a signed int (int32, sfixed32, enum).
  int toInt32() => lo >= 0x80000000 ? lo - _two32 : lo;

  /// The low 32 bits as an unsigned int (uint32, fixed32).
  int toUint32() => lo;

  /// The low 32 bits zigzag decoded (sint32).
  int toSint32() => lo.isEven ? lo ~/ 2 : -(lo ~/ 2) - 1;

  /// The bits zigzag decoded (sint64).
  ///
  /// Exact on the VM and with dart2wasm, see [toInt] for dart2js.
  int toSint64() {
    // The 64-bit value shifted right once.
    var half = hi * 0x80000000 + lo ~/ 2;
    return lo.isEven ? half : -half - 1;
  }

  /// True when any bit is set (bool).
  bool toBool() => lo != 0 || hi != 0;

  /// The unsigned decimal value, exact everywhere: what protoc
  /// `--decode_raw` prints.
  String toUnsignedString() =>
      hi == 0 ? lo.toString() : toUnsignedBigInt().toString();

  /// The 16 hex digits of the bits, most significant first.
  String toHex() =>
      '${hi.toRadixString(16).padLeft(8, '0')}'
      '${lo.toRadixString(16).padLeft(8, '0')}';

  /// True when the value is below 2^32, so [lo] holds all of it.
  bool get isUint32 => hi == 0;
}

/// A field value, its class telling how it is laid out on the wire.
sealed class PbValue {
  const PbValue();

  /// How the value is laid out on the wire.
  PbWireType get wireType;
}

/// A varint value (int32, int64, uint32, uint64, sint32, sint64, bool, enum).
///
/// The wire does not say which type it is: the [PbBits64] conversions
/// interpret it.
final class PbVarint extends PbValue with PbBits64 {
  @override
  final int lo;

  @override
  final int hi;

  /// Varint of the 64 bits [hi]:[lo], both unsigned 32-bit.
  PbVarint(this.lo, this.hi) {
    _checkUint32(lo, 'lo');
    _checkUint32(hi, 'hi');
  }

  /// Varint of [value] (int32, int64, uint32, enum): a negative value takes
  /// the 10 bytes of its 64-bit two's complement, as protobuf encodes it.
  factory PbVarint.fromInt(int value) {
    var (lo, hi) = _splitInt(value);
    return PbVarint(lo, hi);
  }

  /// Varint of [value], from -2^63 (int64) to 2^64 - 1 (uint64).
  factory PbVarint.fromBigInt(BigInt value) {
    var (lo, hi) = _splitBigInt(value);
    return PbVarint(lo, hi);
  }

  /// Varint of [value] zigzag encoded (sint32, sint64).
  factory PbVarint.fromSint(int value) {
    var big = BigInt.from(value);
    return PbVarint.fromBigInt(
      value >= 0 ? big * BigInt.two : -big * BigInt.two - BigInt.one,
    );
  }

  /// Varint of [value] (bool).
  factory PbVarint.fromBool(bool value) => PbVarint(value ? 1 : 0, 0);

  @override
  PbWireType get wireType => PbWireType.varint;

  @override
  bool operator ==(Object other) =>
      other is PbVarint && other.lo == lo && other.hi == hi;

  @override
  int get hashCode => Object.hash(lo, hi);

  @override
  String toString() => toUnsignedString();
}

/// A 64-bit fixed value (fixed64, sfixed64, double).
final class PbFixed64 extends PbValue with PbBits64 {
  @override
  final int lo;

  @override
  final int hi;

  /// Fixed64 of the 64 bits [hi]:[lo], both unsigned 32-bit.
  PbFixed64(this.lo, this.hi) {
    _checkUint32(lo, 'lo');
    _checkUint32(hi, 'hi');
  }

  /// Fixed64 of [value] (fixed64, sfixed64).
  factory PbFixed64.fromInt(int value) {
    var (lo, hi) = _splitInt(value);
    return PbFixed64(lo, hi);
  }

  /// Fixed64 of [value], from -2^63 (sfixed64) to 2^64 - 1 (fixed64).
  factory PbFixed64.fromBigInt(BigInt value) {
    var (lo, hi) = _splitBigInt(value);
    return PbFixed64(lo, hi);
  }

  /// Fixed64 of [value] (double).
  factory PbFixed64.fromDouble(double value) {
    var data = ByteData(8)..setFloat64(0, value, Endian.little);
    return PbFixed64(
      data.getUint32(0, Endian.little),
      data.getUint32(4, Endian.little),
    );
  }

  /// The bits as a double.
  double toDouble() =>
      (ByteData(8)
            ..setUint32(0, lo, Endian.little)
            ..setUint32(4, hi, Endian.little))
          .getFloat64(0, Endian.little);

  @override
  PbWireType get wireType => PbWireType.fixed64;

  @override
  bool operator ==(Object other) =>
      other is PbFixed64 && other.lo == lo && other.hi == hi;

  @override
  int get hashCode => Object.hash(lo, hi, 64);

  @override
  String toString() => '0x${toHex()}';
}

/// A 32-bit fixed value (fixed32, sfixed32, float).
final class PbFixed32 extends PbValue {
  /// The bits, unsigned.
  final int value;

  /// Fixed32 of the unsigned 32-bit [value].
  PbFixed32(this.value) {
    _checkUint32(value, 'value');
  }

  /// Fixed32 of [value], from -2^31 (sfixed32) to 2^32 - 1 (fixed32).
  factory PbFixed32.fromInt(int value) {
    if (value < -0x80000000 || value > 0xffffffff) {
      throw ArgumentError.value(value, 'value', 'not a 32-bit value');
    }
    return PbFixed32(value & 0xffffffff);
  }

  /// Fixed32 of [value] (float), rounded to single precision.
  factory PbFixed32.fromFloat(double value) => PbFixed32(
    (ByteData(
      4,
    )..setFloat32(0, value, Endian.little)).getUint32(0, Endian.little),
  );

  /// The bits as an unsigned int (fixed32).
  int toUint32() => value;

  /// The bits as a signed int (sfixed32).
  int toInt32() => value >= 0x80000000 ? value - _two32 : value;

  /// The bits as a float.
  double toFloat() => (ByteData(
    4,
  )..setUint32(0, value, Endian.little)).getFloat32(0, Endian.little);

  /// The 8 hex digits of the bits.
  String toHex() => value.toRadixString(16).padLeft(8, '0');

  @override
  PbWireType get wireType => PbWireType.fixed32;

  @override
  bool operator ==(Object other) => other is PbFixed32 && other.value == value;

  @override
  int get hashCode => Object.hash(value, 32);

  @override
  String toString() => '0x${toHex()}';
}

/// A length delimited value: a string, bytes, an embedded message or a packed
/// repeated field — the wire does not say which.
///
/// Read values are always [PbBytes]; a [PbEmbedded] is built in memory, to be
/// written.
sealed class PbLengthDelimited extends PbValue {
  const PbLengthDelimited();

  @override
  PbWireType get wireType => PbWireType.lengthDelimited;
}

/// The raw bytes of a length delimited value, as read.
final class PbBytes extends PbLengthDelimited {
  /// The bytes, without the length prefix.
  ///
  /// Once read, a view on the decoded buffer: copy it before changing either.
  final Uint8List bytes;

  /// Raw [bytes].
  const PbBytes(this.bytes);

  /// Raw [bytes] (copied).
  PbBytes.fromList(List<int> bytes) : bytes = Uint8List.fromList(bytes);

  /// The utf8 bytes of [text] (string).
  PbBytes.string(String text) : bytes = utf8.encode(text);

  @override
  bool operator ==(Object other) =>
      other is PbBytes && _bytesEquals(other.bytes, bytes);

  @override
  int get hashCode => Object.hashAll(bytes.take(32));

  @override
  String toString() => 'PbBytes(${bytes.length})';
}

/// An embedded message built in memory, written length delimited.
final class PbEmbedded extends PbLengthDelimited {
  /// The message.
  final PbMessage message;

  /// Embedded [message].
  const PbEmbedded(this.message);

  @override
  bool operator ==(Object other) =>
      other is PbEmbedded && other.message == message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'PbEmbedded($message)';
}

/// A group, the deprecated proto2 way to embed a message between a start and
/// an end tag.
final class PbGroup extends PbValue {
  /// The fields between the start and the end tag.
  final PbMessage message;

  /// Group of [message].
  const PbGroup(this.message);

  @override
  PbWireType get wireType => PbWireType.startGroup;

  @override
  bool operator ==(Object other) =>
      other is PbGroup && other.message == message;

  @override
  int get hashCode => Object.hash(message, 3);

  @override
  String toString() => 'PbGroup($message)';
}

/// A field: its number and its value.
///
/// A repeated field is the same number appearing more than once in
/// [PbMessage.fields].
final class PbField {
  /// The field number, from 1 to [pbMaxFieldNumber].
  final int number;

  /// The value.
  final PbValue value;

  /// Field [number] holding [value].
  PbField(this.number, this.value) {
    pbCheckFieldNumber(number);
  }

  /// How [value] is laid out on the wire.
  PbWireType get wireType => value.wireType;

  /// This field with [value] instead.
  PbField withValue(PbValue value) => PbField(number, value);

  @override
  bool operator ==(Object other) =>
      other is PbField && other.number == number && other.value == value;

  @override
  int get hashCode => Object.hash(number, value);

  @override
  String toString() => '$number: $value';
}

/// A message without its schema: the fields as they come on the wire, in
/// order, repeated ones included.
class PbMessage {
  /// The fields, in wire order.
  final List<PbField> fields;

  /// Message of [fields] (an empty, growable list by default).
  PbMessage([List<PbField>? fields]) : fields = fields ?? <PbField>[];

  /// True when there is no field.
  bool get isEmpty => fields.isEmpty;

  /// True when there is a field.
  bool get isNotEmpty => fields.isNotEmpty;

  /// The distinct field numbers, in the order they first appear.
  List<int> get numbers => {for (var field in fields) field.number}.toList();

  /// The fields numbered [number], in wire order.
  Iterable<PbField> fieldsOf(int number) =>
      fields.where((field) => field.number == number);

  /// The values of the fields numbered [number], in wire order.
  Iterable<PbValue> valuesOf(int number) =>
      fieldsOf(number).map((field) => field.value);

  /// The value of the last field numbered [number] (the one a parser keeps
  /// for a non repeated field), null when there is none.
  PbValue? valueOf(int number) {
    for (var i = fields.length - 1; i >= 0; i--) {
      if (fields[i].number == number) {
        return fields[i].value;
      }
    }
    return null;
  }

  /// True when a field is numbered [number].
  bool has(int number) => fields.any((field) => field.number == number);

  /// Adds field [number] holding [value].
  void add(int number, PbValue value) => fields.add(PbField(number, value));

  /// Adds a varint field (int32, int64, uint32, enum), see
  /// [PbVarint.fromInt].
  void addInt(int number, int value) => add(number, PbVarint.fromInt(value));

  /// Adds a zigzag varint field (sint32, sint64).
  void addSint(int number, int value) => add(number, PbVarint.fromSint(value));

  /// Adds a varint field (bool).
  void addBool(int number, bool value) => add(number, PbVarint.fromBool(value));

  /// Adds a fixed32 field (fixed32, sfixed32).
  void addFixed32(int number, int value) =>
      add(number, PbFixed32.fromInt(value));

  /// Adds a fixed64 field (fixed64, sfixed64).
  void addFixed64(int number, int value) =>
      add(number, PbFixed64.fromInt(value));

  /// Adds a fixed32 field (float).
  void addFloat(int number, double value) =>
      add(number, PbFixed32.fromFloat(value));

  /// Adds a fixed64 field (double).
  void addDouble(int number, double value) =>
      add(number, PbFixed64.fromDouble(value));

  /// Adds a length delimited field (string).
  void addString(int number, String value) =>
      add(number, PbBytes.string(value));

  /// Adds a length delimited field (bytes).
  void addBytes(int number, List<int> value) =>
      add(number, PbBytes.fromList(value));

  /// Adds a length delimited field (embedded message).
  void addMessage(int number, PbMessage value) =>
      add(number, PbEmbedded(value));

  /// Adds a group field.
  void addGroup(int number, PbMessage value) => add(number, PbGroup(value));

  @override
  bool operator ==(Object other) {
    if (other is! PbMessage || other.fields.length != fields.length) {
      return false;
    }
    for (var i = 0; i < fields.length; i++) {
      if (other.fields[i] != fields[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(fields);

  @override
  String toString() => 'PbMessage(${fields.join(', ')})';
}

bool _bytesEquals(Uint8List a, Uint8List b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
