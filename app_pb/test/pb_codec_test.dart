import 'dart:typed_data';

import 'package:tekartik_app_pb/pb.dart';
import 'package:test/test.dart';

Uint8List hex(String text) {
  var cleaned = text.replaceAll(' ', '');
  return Uint8List.fromList([
    for (var i = 0; i < cleaned.length; i += 2)
      int.parse(cleaned.substring(i, i + 2), radix: 16),
  ]);
}

String toHex(List<int> bytes) =>
    bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(' ');

/// Encodes [message], checks it is [expected], decodes it back.
void expectEncoded(PbMessage message, String expected) {
  var bytes = pbEncodeMessage(message);
  expect(toHex(bytes), expected);
  expect(pbDecodeMessage(bytes), _decodedForm(message));
}

/// What [message] decodes as: embedded messages come back as bytes.
PbMessage _decodedForm(PbMessage message) => PbMessage([
  for (var field in message.fields)
    switch (field.value) {
      PbEmbedded(:var message) => field.withValue(
        PbBytes(pbEncodeMessage(message)),
      ),
      PbGroup(:var message) => field.withValue(PbGroup(_decodedForm(message))),
      _ => field,
    },
]);

void main() {
  group('encoding guide', () {
    // https://protobuf.dev/programming-guides/encoding/
    test('varint', () {
      expectEncoded(PbMessage()..addInt(1, 150), '08 96 01');
    });

    test('string', () {
      expectEncoded(
        PbMessage()..addString(2, 'testing'),
        '12 07 74 65 73 74 69 6e 67',
      );
    });

    test('embedded message', () {
      expectEncoded(
        PbMessage()..addMessage(3, PbMessage()..addInt(1, 150)),
        '1a 03 08 96 01',
      );
    });

    test('negative int32 takes 10 bytes', () {
      expectEncoded(
        PbMessage()..addInt(1, -2),
        '08 fe ff ff ff ff ff ff ff ff 01',
      );
    });

    test('sint32', () {
      expectEncoded(PbMessage()..addSint(1, -2), '08 03');
    });

    test('fixed', () {
      expectEncoded(PbMessage()..addFixed32(1, 1), '0d 01 00 00 00');
      expectEncoded(
        PbMessage()..addFixed64(1, -1),
        '09 ff ff ff ff ff ff ff ff',
      );
      expectEncoded(PbMessage()..addFloat(1, 1.0), '0d 00 00 80 3f');
      expectEncoded(
        PbMessage()..addDouble(1, 1.0),
        '09 00 00 00 00 00 00 f0 3f',
      );
    });

    test('group', () {
      expectEncoded(
        PbMessage()..addGroup(2, PbMessage()..addInt(1, 1)),
        '13 08 01 14',
      );
    });

    test('large field number', () {
      expectEncoded(
        PbMessage()..addBool(pbMaxFieldNumber, true),
        'f8 ff ff ff 0f 01',
      );
    });
  });

  test('64-bit varints round trip', () {
    for (var value in [
      PbVarint(0, 0),
      PbVarint(0x7f, 0),
      PbVarint(0x80, 0),
      PbVarint(0xffffffff, 0),
      PbVarint(0, 1),
      PbVarint(0xffffffff, 0x7fffffff),
      PbVarint(0, 0x80000000),
      PbVarint(0xffffffff, 0xffffffff),
      PbVarint(0x12345678, 0x9abcdef0),
    ]) {
      var bytes = pbEncodeMessage(PbMessage()..add(1, value));
      expect(pbDecodeMessage(bytes).valueOf(1), value, reason: '$value');
    }
    expect(
      toHex(pbEncodeMessage(PbMessage()..add(1, PbVarint(0, 0x80000000)))),
      '08 80 80 80 80 80 80 80 80 80 01',
    );
  });

  group('decoding errors', () {
    void expectFormatError(String bytes) {
      expect(
        () => pbDecodeMessage(hex(bytes)),
        throwsA(isA<PbFormatException>()),
        reason: bytes,
      );
      expect(pbTryDecodeMessage(hex(bytes)), isNull);
    }

    test('truncated', () {
      expectFormatError('08');
      expectFormatError('08 96');
      expectFormatError('12 07 74 65');
      expectFormatError('0d 01 00 00');
      expectFormatError('09 01 00 00 00 00 00 00');
    });

    test('invalid tag', () {
      // Field 0.
      expectFormatError('00 01');
      // Wire types 6 and 7.
      expectFormatError('0e 01');
      expectFormatError('0f 01');
    });

    test('varint too long', () {
      expectFormatError('08 ff ff ff ff ff ff ff ff ff ff 01');
    });

    test('groups', () {
      // An end group with no start.
      expectFormatError('14');
      // A start group with no end.
      expectFormatError('13 08 01');
      // An end group of another field.
      expectFormatError('13 08 01 1c');
    });

    test('groups nested too deep', () {
      var bytes = [
        for (var i = 0; i <= pbMaxGroupDepth; i++) 0x13,
        for (var i = 0; i <= pbMaxGroupDepth; i++) 0x14,
      ];
      expect(() => pbDecodeMessage(bytes), throwsA(isA<PbFormatException>()));
      expect(pbDecodeMessage(bytes.sublist(1, bytes.length - 1)), isNotNull);
    });

    test('offset', () {
      try {
        pbDecodeMessage(hex('08 01 0e 01'));
        fail('should throw');
      } on PbFormatException catch (e) {
        expect(e.offset, 2);
      }
    });
  });

  test('empty', () {
    expect(pbDecodeMessage([]).isEmpty, isTrue);
    expect(pbEncodeMessage(PbMessage()), isEmpty);
  });

  test('decode a List<int>', () {
    expect(pbDecodeMessage([8, 1]).valueOf(1), PbVarint(1, 0));
  });

  group('length delimited', () {
    test('guess', () {
      expect(pbGuessBytesKind(Uint8List(0)), PbBytesKind.string);
      expect(
        pbGuessBytesKind(PbBytes.string('hello world').bytes),
        PbBytesKind.string,
      );
      // 'hi' decodes as a message (field 13, varint 105) but is text.
      expect(pbTryDecodeMessage(PbBytes.string('hi').bytes), isNotNull);
      expect(pbGuessBytesKind(PbBytes.string('hi').bytes), PbBytesKind.string);
      expect(pbGuessBytesKind(hex('08 96 01')), PbBytesKind.message);
      // A single string field 1 of 32 to 126 bytes is printable but its
      // first byte, the tag, is a line feed: a message.
      var path = '/tmp/some/path/that/is/long/enough/file.txt';
      var nested = pbEncodeMessage(PbMessage()..addString(1, path));
      expect(nested[1], path.length);
      expect(pbGuessBytesKind(nested), PbBytesKind.message);
      // Multi line text that does not decode.
      expect(
        pbGuessBytesKind(PbBytes.string('line 1\nline 2').bytes),
        PbBytesKind.string,
      );
      expect(pbGuessBytesKind(hex('ff fe 00')), PbBytesKind.bytes);
      expect(pbGuessBytesKind(hex('01 02 03')), PbBytesKind.bytes);
    });

    test('decode as', () {
      var value = PbBytes(hex('08 96 01'));
      expect(value.tryDecodeMessage()!.valueOf(1), PbVarint(150, 0));
      expect(value.tryDecodeString(), isNull);
      expect(value.rawBytes, hex('08 96 01'));
      expect(value.guessKind(), PbBytesKind.message);

      var packed = PbBytes(hex('03 8e 02 9e a7 05'));
      expect(packed.tryDecodePackedVarints()!.map((value) => value.toInt()), [
        3,
        270,
        86942,
      ]);
      expect(packed.tryDecodePackedFixed32(), isNull);
      expect(PbBytes(hex('96')).tryDecodePackedVarints(), isNull);

      var fixed = PbBytes(hex('01 00 00 00 02 00 00 00'));
      expect(fixed.tryDecodePackedFixed32()!.map((value) => value.value), [
        1,
        2,
      ]);
      expect(fixed.tryDecodePackedFixed64()!.single.toInt(), 0x200000001);

      var embedded = PbEmbedded(PbMessage()..addInt(1, 1));
      expect(embedded.tryDecodeMessage(), embedded.message);
      expect(embedded.tryDecodeString(), isNull);
      expect(embedded.rawBytes, isNull);
      expect(embedded.guessKind(), PbBytesKind.message);
      expect(embedded.tryDecodePackedVarints(), isNull);
    });
  });

  test('message getters', () {
    var message = pbDecodeMessage(
      pbEncodeMessage(
        PbMessage()
          ..addString(1, 'a')
          ..addString(1, 'b')
          ..addInt(2, -5)
          ..addBool(3, true)
          ..addDouble(4, 1.5)
          ..addFloat(5, 2.5)
          ..addBytes(6, [1, 2, 3])
          ..addMessage(7, PbMessage()..addString(1, 'x'))
          ..addMessage(7, PbMessage()..addString(1, 'y'))
          ..addGroup(8, PbMessage()..addInt(1, 8))
          ..addFixed32(9, 9)
          ..addFixed64(10, 10),
      ),
    );
    expect(message.stringValue(1), 'b');
    expect(message.stringValues(1), ['a', 'b']);
    expect(message.intValue(2), -5);
    expect(message.boolValue(3), isTrue);
    expect(message.doubleValue(4), 1.5);
    expect(message.doubleValue(5), 2.5);
    expect(message.bytesValue(6), [1, 2, 3]);
    expect(message.messageValue(7)!.stringValue(1), 'y');
    expect(message.messageValues(7).map((message) => message.stringValue(1)), [
      'x',
      'y',
    ]);
    expect(message.messageValue(8)!.intValue(1), 8);
    expect(message.messageValues(8).single.intValue(1), 8);
    expect(message.intValue(9), 9);
    expect(message.intValue(10), 10);
    // Missing or of another kind.
    expect(message.stringValue(2), isNull);
    expect(message.intValue(1), isNull);
    expect(message.boolValue(1), isNull);
    expect(message.doubleValue(1), isNull);
    expect(message.bytesValue(2), isNull);
    expect(message.messageValue(2), isNull);
    expect(message.stringValue(99), isNull);
    expect(message.messageValues(99), isEmpty);
  });

  group('PbReader', () {
    test('low level', () {
      var reader = PbReader(hex('08 96 01 12 02 68 69'));
      var tag = reader.readTag();
      expect(tag.number, 1);
      expect(tag.wireType, PbWireType.varint);
      expect(reader.readVarint().toInt(), 150);
      expect(reader.offset, 3);
      tag = reader.readTag();
      expect(tag.number, 2);
      expect(tag.wireType, PbWireType.lengthDelimited);
      expect(reader.readLengthDelimited(), [0x68, 0x69]);
      expect(reader.isAtEnd, isTrue);
    });

    test('range', () {
      var bytes = hex('ff 08 01 ff');
      expect(PbReader(bytes, 1, 3).readMessage().valueOf(1), PbVarint(1, 0));
      expect(() => PbReader(bytes, 1, 5), throwsRangeError);
    });
  });

  test('PbWriter low level', () {
    var writer = PbWriter()
      ..writeTag(1, PbWireType.varint)
      ..writeVarint(PbVarint.fromInt(150))
      ..writeTag(2, PbWireType.lengthDelimited)
      ..writeLengthDelimited([0x68, 0x69])
      ..writeRawBytes([0x18, 0x01]);
    expect(writer.length, 9);
    expect(toHex(writer.toBytes()), '08 96 01 12 02 68 69 18 01');
    expect(() => writer.writeTag(0, PbWireType.varint), throwsArgumentError);
  });

  test('writer grows', () {
    var big = Uint8List(100000);
    for (var i = 0; i < big.length; i++) {
      big[i] = i & 0xff;
    }
    var message = PbMessage()
      ..addBytes(1, big)
      ..addString(2, 'end');
    var decoded = pbDecodeMessage(message.toBytes());
    expect(decoded.bytesValue(1), big);
    expect(decoded.stringValue(2), 'end');
  });

  test('decode, change, encode', () {
    var bytes = pbEncodeMessage(
      PbMessage()
        ..addString(1, 'name')
        ..addMessage(2, PbMessage()..addInt(1, 1)),
    );
    var message = pbDecodeMessage(bytes);
    var nested = message.messageValue(2)!..addInt(2, 2);
    message.fields[1] = message.fields[1].withValue(PbEmbedded(nested));
    message.fields[0] = message.fields[0].withValue(PbBytes.string('other'));
    var decoded = pbDecodeMessage(pbEncodeMessage(message));
    expect(decoded.stringValue(1), 'other');
    expect(decoded.messageValue(2)!.intValue(1), 1);
    expect(decoded.messageValue(2)!.intValue(2), 2);
  });
}
