---
name: tekartik-app-pb-codec
description: >-
  Use when reading, inspecting, changing or writing protobuf wire format data
  (.pb files, android test-result.pb, device-info.pb, any binary protobuf)
  without the .proto schema or generated code, with package:tekartik_app_pb:
  pbDecodeMessage, pbTryDecodeMessage, PbMessage, PbField, PbVarint,
  PbFixed32, PbFixed64, PbBytes, PbEmbedded, PbGroup, stringValue, intValue,
  messageValue(s), tryDecodeString, tryDecodeMessage,
  tryDecodePackedVarints, pbGuessBytesKind, pbMessageToText (protoc
  --decode_raw text), pbEncodeMessage, PbReader, PbWriter, from
  pb_reader.dart (no writer linked), pb_writer.dart or pb.dart.
---

# tekartik_app_pb codec

Schema-less protobuf in pure Dart (VM, Flutter, dart2js, dart2wasm): a
message is the list of its wire fields (number + value), read as what the
schema would say through typed getters, printed like `protoc --decode_raw`,
encoded back to the same bytes.

```dart
import 'package:tekartik_app_pb/pb_reader.dart';

void main() {
  var message = pbDecodeMessage([0x08, 0x96, 0x01, 0x12, 0x02, 0x68, 0x69]);
  print(message.intValue(1)); // 150
  print(message.stringValue(2)); // hi
  print(pbMessageToText(message)); // 1: 150 / 2: "hi"
}
```

## Guidelines

### Libraries

* Not on pub.dev, depend on it through git (`path: app_pb` of
  `https://github.com/tekartik/app_common_utils.dart`).
* Import `pb_reader.dart` in code that only reads: it never links the
  encoder. `pb_writer.dart` gives the encoder (and the model) without the
  decoder. `pb.dart` exports both, use it when the code does both.
* No dependency, no io: read the bytes yourself (`File.readAsBytes`, a
  download, an asset) and pass them. `bin/pb_dump.dart` is the io side
  (`dart run tekartik_app_pb:pb_dump file.pb`).

### Model

* `PbMessage.fields` is the wire order list, repeated fields included (the
  same number several times). `valueOf(n)` returns the **last** field `n`
  (what a parser keeps for a non repeated field), `valuesOf(n)` /
  `fieldsOf(n)` all of them, `numbers` the distinct numbers.
* Values are a sealed `PbValue`: `PbVarint` (int32/64, uint32/64, sint, bool,
  enum), `PbFixed64` (fixed64, sfixed64, double), `PbFixed32` (fixed32,
  sfixed32, float), `PbBytes` (any length delimited value, as read),
  `PbEmbedded` (a message built in memory, to write), `PbGroup` (deprecated
  proto2 groups). Switch on them exhaustively.
* The wire does not say the scalar type: convert with `toInt()` (int64),
  `toInt32()`, `toUint32()`, `toSint32()` / `toSint64()` (zigzag),
  `toBool()`, `toDouble()` / `toFloat()`.
* 64-bit values are two unsigned 32-bit halves (`lo`, `hi`): exact on every
  platform. `toInt()` is exact on the VM and wasm only; with dart2js use
  `toSignedBigInt()` / `toUnsignedBigInt()` beyond ±2^53.
  `toUnsignedString()` is what `--decode_raw` prints.
* Decoded `PbBytes.bytes` are views on the input buffer: copy before
  changing either.

### Reading

* `pbDecodeMessage(bytes)` throws a `PbFormatException` (a
  `FormatException` with an `offset`) on invalid input;
  `pbTryDecodeMessage` returns null instead.
* The `PbMessageReaderExt` getters (`stringValue`, `intValue`, `boolValue`,
  `doubleValue`, `bytesValue`, `messageValue`, plural `stringValues`,
  `messageValues`) return null (or skip) when the field is missing **or** not
  of that kind. `intValue` on a sfixed32 is unsigned: use
  `(valueOf(n) as PbFixed32).toInt32()`.
* A length delimited value can be a string, a message, bytes or packed
  numbers: `tryDecodeString()`, `tryDecodeMessage()`,
  `tryDecodePackedVarints()`, `tryDecodePackedFixed32/64()` each return null
  when it is not that. Use what the schema says; `guessKind()` /
  `pbGuessBytesKind` only guess (printable text first, then message, then
  text with line breaks, then bytes) - short texts also decode as messages.
* `pbMessageToText(message, indent:)` prints field numbers, varints as
  unsigned decimals, fixed values in hex, and recurses into what
  `pbGuessBytesKind` calls a message. Use it to explore an unknown file and
  find the field numbers.
* `PbReader` is the low level reader (`readTag`, `readVarint`,
  `readFixed32/64`, `readLengthDelimited`, `readMessage`) for streaming or
  partial reads.

### Writing

* Build with `PbMessage()..addString(n, s)..addInt(n, i)..addSint(...)
  ..addBool ..addFixed32 ..addFixed64 ..addFloat ..addDouble ..addBytes
  ..addMessage(n, PbMessage(...)) ..addGroup`, then `pbEncodeMessage` or
  `message.toBytes()`.
* `addInt` with a negative value writes 10 bytes (int32/int64 semantic);
  use `addSint` for a sint32/sint64 field.
* Field numbers must be 1 to `pbMaxFieldNumber` (2^29 - 1), else
  `ArgumentError`.
* To change a decoded message, replace fields in `message.fields` with
  `field.withValue(...)`; to change a nested one, decode it
  (`messageValue`), change it and store it back as `PbEmbedded`.
* A decoded message encodes back to the exact same bytes (canonical
  varints, as every encoder writes them).

## Examples

### Read an android test result without its schema

```dart
import 'package:tekartik_app_pb/pb_reader.dart';

/// `test-result.pb` is a TestSuiteResult: field 3 holds the test results,
/// each with its test case (1) and status (2, 3 is PASSED).
void printTestResults(List<int> bytes) {
  var suite = pbDecodeMessage(bytes);
  for (var result in suite.messageValues(3)) {
    var testCase = result.messageValue(1)!;
    var name = '${testCase.stringValue(1)}.${testCase.stringValue(3)}';
    print('$name: ${result.intValue(2) == 3 ? 'passed' : 'failed'}');
  }
}

void main() {
  printTestResults([0x1a, 0x07, 0x0a, 0x03, 0x0a, 0x01, 0x41, 0x10, 0x03]);
}
```

### Explore an unknown file

```dart
import 'dart:io';

import 'package:tekartik_app_pb/pb_reader.dart';

Future<void> main(List<String> arguments) async {
  var bytes = await File(arguments.first).readAsBytes();
  var message = pbTryDecodeMessage(bytes);
  if (message == null) {
    print('not a protobuf message');
    return;
  }
  print(pbMessageToText(message));
  for (var field in message.fields) {
    switch (field.value) {
      case PbVarint value:
        print('${field.number}: int ${value.toInt()} sint ${value.toSint64()}');
      case PbBytes value:
        print('${field.number}: ${value.guessKind().name}');
      case PbFixed32 value:
        print('${field.number}: float ${value.toFloat()}');
      case PbFixed64 value:
        print('${field.number}: double ${value.toDouble()}');
      case PbEmbedded() || PbGroup():
        print('${field.number}: message');
    }
  }
}
```

### Change a nested value and write the file back

```dart
import 'dart:io';

import 'package:tekartik_app_pb/pb.dart';

Future<void> renameDevice(File file, String name) async {
  var message = pbDecodeMessage(await file.readAsBytes());
  var index = message.fields.indexWhere((field) => field.number == 1);
  var meta = message.messageValue(1);
  if (index < 0 || meta == null) {
    return;
  }
  // Nested message 3 of field 1 (the device), its field 2 replaced.
  var device = meta.messageValue(3) ?? PbMessage();
  device.fields.removeWhere((field) => field.number == 2);
  device.addString(2, name);
  meta.fields.removeWhere((field) => field.number == 3);
  meta.addMessage(3, device);
  message.fields[index] = message.fields[index].withValue(PbEmbedded(meta));
  await file.writeAsBytes(pbEncodeMessage(message));
}
```

### Write a message from scratch

```dart
import 'package:tekartik_app_pb/pb_writer.dart';

void main() {
  var message = PbMessage()
    ..addString(1, 'hello')
    ..addInt(2, 150)
    ..addSint(3, -2)
    ..addDouble(4, 1.5)
    ..addMessage(5, PbMessage()..addBool(1, true));
  print(pbEncodeMessage(message).length); // 25
}
```

## Common mistakes

* `intValue` returns null on a string field and vice versa: the getters are
  typed, check the field kind with `pbMessageToText` first.
* A nested message changed after `messageValue(n)` is a decoded copy: store
  it back as a `PbEmbedded`, the original field still holds the old bytes.
* Expecting `toInt()` to be exact for large 64-bit values on the web: use the
  `BigInt` conversions.
