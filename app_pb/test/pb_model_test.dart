import 'package:tekartik_app_pb/pb_writer.dart';
import 'package:test/test.dart';

void main() {
  group('PbVarint', () {
    test('fromInt', () {
      expect(PbVarint.fromInt(0), PbVarint(0, 0));
      expect(PbVarint.fromInt(150), PbVarint(150, 0));
      expect(PbVarint.fromInt(-1), PbVarint(0xffffffff, 0xffffffff));
      expect(PbVarint.fromInt(-2), PbVarint(0xfffffffe, 0xffffffff));
      expect(PbVarint.fromInt(0x100000000), PbVarint(0, 1));
      expect(PbVarint.fromInt(0x7fffffff), PbVarint(0x7fffffff, 0));
      expect(PbVarint.fromInt(-0x80000000), PbVarint(0x80000000, 0xffffffff));
      // Within 2^53, exact on every platform.
      expect(
        PbVarint.fromInt(0x1fffffffffffff),
        PbVarint(0xffffffff, 0x1fffff),
      );
      expect(
        PbVarint.fromInt(-0x1fffffffffffff),
        PbVarint(0x00000001, 0xffe00000),
      );
    });

    test('fromBigInt', () {
      expect(
        PbVarint.fromBigInt(BigInt.parse('18446744073709551615')),
        PbVarint(0xffffffff, 0xffffffff),
      );
      expect(
        PbVarint.fromBigInt(BigInt.parse('-9223372036854775808')),
        PbVarint(0, 0x80000000),
      );
      expect(
        PbVarint.fromBigInt(BigInt.parse('9223372036854775807')),
        PbVarint(0xffffffff, 0x7fffffff),
      );
      expect(
        () => PbVarint.fromBigInt(BigInt.parse('18446744073709551616')),
        throwsArgumentError,
      );
      expect(
        () => PbVarint.fromBigInt(BigInt.parse('-9223372036854775809')),
        throwsArgumentError,
      );
    });

    test('halves are checked', () {
      expect(() => PbVarint(-1, 0), throwsArgumentError);
      expect(() => PbVarint(0, 0x100000000), throwsArgumentError);
    });

    test('conversions', () {
      var minusOne = PbVarint.fromInt(-1);
      expect(minusOne.toInt(), -1);
      expect(minusOne.toInt32(), -1);
      expect(minusOne.toUint32(), 0xffffffff);
      expect(minusOne.toSignedBigInt(), BigInt.from(-1));
      expect(minusOne.toUnsignedBigInt(), BigInt.parse('18446744073709551615'));
      expect(minusOne.toUnsignedString(), '18446744073709551615');
      expect(minusOne.toHex(), 'ffffffffffffffff');
      expect(minusOne.toBool(), isTrue);
      expect(minusOne.isUint32, isFalse);

      var value = PbVarint.fromInt(150);
      expect(value.toInt(), 150);
      expect(value.toInt32(), 150);
      expect(value.toUnsignedString(), '150');
      expect(value.toString(), '150');
      expect(value.isUint32, isTrue);

      expect(PbVarint.fromInt(-0x80000000).toInt32(), -0x80000000);
      expect(PbVarint.fromInt(0x7fffffff).toInt32(), 0x7fffffff);
      expect(PbVarint(0x80000000, 0).toInt32(), -0x80000000);
      expect(PbVarint(0, 0).toBool(), isFalse);
      expect(PbVarint(0, 1).toBool(), isTrue);

      expect(
        PbVarint.fromBigInt(
          BigInt.parse('-9223372036854775808'),
        ).toSignedBigInt(),
        BigInt.parse('-9223372036854775808'),
      );
      expect(PbVarint.fromInt(-0x1fffffffffffff).toInt(), -0x1fffffffffffff);
      expect(PbVarint.fromInt(0x1fffffffffffff).toInt(), 0x1fffffffffffff);
    });

    test('zigzag', () {
      // The protobuf documentation table.
      for (var (value, encoded) in [
        (0, 0),
        (-1, 1),
        (1, 2),
        (-2, 3),
        (0x7fffffff, 0xfffffffe),
        (-0x80000000, 0xffffffff),
      ]) {
        var varint = PbVarint.fromSint(value);
        expect(varint, PbVarint(encoded, 0), reason: '$value');
        expect(varint.toSint32(), value);
        expect(varint.toSint64(), value);
      }
      expect(
        PbVarint.fromSint(-0x1fffffffffffff).toSint64(),
        -0x1fffffffffffff,
      );
      expect(PbVarint.fromSint(0x1fffffffffffff).toSint64(), 0x1fffffffffffff);
    });

    test('bool', () {
      expect(PbVarint.fromBool(true), PbVarint(1, 0));
      expect(PbVarint.fromBool(false), PbVarint(0, 0));
    });
  });

  group('PbFixed64', () {
    test('double', () {
      for (var value in [0.0, 1.5, -2.25, 1e300, double.infinity]) {
        expect(PbFixed64.fromDouble(value).toDouble(), value);
      }
      expect(PbFixed64.fromDouble(1.0), PbFixed64(0, 0x3ff00000));
      expect(PbFixed64.fromDouble(double.nan).toDouble(), isNaN);
    });

    test('int', () {
      expect(PbFixed64.fromInt(-1), PbFixed64(0xffffffff, 0xffffffff));
      expect(PbFixed64.fromInt(-1).toInt(), -1);
      expect(PbFixed64.fromInt(42).toString(), '0x000000000000002a');
      expect(
        PbFixed64.fromBigInt(BigInt.parse('18446744073709551615')),
        PbFixed64(0xffffffff, 0xffffffff),
      );
      expect(PbFixed64(1, 2), isNot(PbVarint(1, 2)));
    });
  });

  group('PbFixed32', () {
    test('int', () {
      expect(PbFixed32.fromInt(-1).value, 0xffffffff);
      expect(PbFixed32.fromInt(-1).toInt32(), -1);
      expect(PbFixed32.fromInt(-1).toUint32(), 0xffffffff);
      expect(PbFixed32.fromInt(42).toString(), '0x0000002a');
      expect(() => PbFixed32.fromInt(0x100000000), throwsArgumentError);
      expect(() => PbFixed32.fromInt(-0x80000001), throwsArgumentError);
      expect(() => PbFixed32(-1), throwsArgumentError);
    });

    test('float', () {
      expect(PbFixed32.fromFloat(1.5).toFloat(), 1.5);
      expect(PbFixed32.fromFloat(1.0), PbFixed32(0x3f800000));
      // Rounded to single precision.
      expect(PbFixed32.fromFloat(0.1).toFloat(), closeTo(0.1, 1e-7));
    });
  });

  group('PbMessage', () {
    test('add and read', () {
      var message = PbMessage()
        ..addInt(1, 150)
        ..addString(2, 'testing')
        ..addInt(1, 151)
        ..addMessage(3, PbMessage()..addBool(1, true))
        ..addBytes(4, [1, 2])
        ..addGroup(5, PbMessage()..addSint(1, -1))
        ..addFixed32(6, 7)
        ..addFixed64(7, 8)
        ..addFloat(8, 1.5)
        ..addDouble(9, 2.5);
      expect(message.numbers, [1, 2, 3, 4, 5, 6, 7, 8, 9]);
      expect(message.fieldsOf(1).length, 2);
      expect(message.valueOf(1), PbVarint(151, 0));
      expect(message.valuesOf(1), [PbVarint(150, 0), PbVarint(151, 0)]);
      expect(message.valueOf(10), isNull);
      expect(message.has(9), isTrue);
      expect(message.has(10), isFalse);
      expect(message.valueOf(2), PbBytes.string('testing'));
      expect(message.valueOf(5)!.wireType, PbWireType.startGroup);
      expect(message.valueOf(3)!.wireType, PbWireType.lengthDelimited);
      expect(message.isNotEmpty, isTrue);
      expect(PbMessage().isEmpty, isTrue);
    });

    test('equality', () {
      PbMessage build() => PbMessage()
        ..addInt(1, 1)
        ..addMessage(2, PbMessage()..addString(1, 'a'));
      expect(build(), build());
      expect(build().hashCode, build().hashCode);
      expect(build(), isNot(PbMessage()..addInt(1, 1)));
      expect(PbBytes.fromList([1, 2]), PbBytes.fromList([1, 2]));
      expect(PbBytes.fromList([1, 2]), isNot(PbBytes.fromList([1, 3])));
    });

    test('field numbers', () {
      expect(() => PbField(0, PbVarint(0, 0)), throwsArgumentError);
      expect(
        () => PbField(pbMaxFieldNumber + 1, PbVarint(0, 0)),
        throwsArgumentError,
      );
      expect(PbField(pbMaxFieldNumber, PbVarint(0, 0)).number, 0x1fffffff);
      expect(
        PbField(1, PbVarint(1, 0)).withValue(PbVarint(2, 0)).value,
        PbVarint(2, 0),
      );
    });
  });

  test('wire types', () {
    for (var wireType in PbWireType.values) {
      expect(PbWireType.fromId(wireType.id), wireType);
    }
    expect(PbWireType.fromId(6), isNull);
    expect(PbWireType.fromId(7), isNull);
  });
}
