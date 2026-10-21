# tekartik_app_pb

Read and write protobuf files (`.pb`) without any schema, in pure Dart, on
every platform (VM, Flutter, dart2js, dart2wasm).

A message is decoded into the fields as they come on the wire (field number,
value) - no `.proto` file, no generated code. The typed getters then read a
field as what the schema would say it is (`stringValue`, `intValue`,
`messageValue`...), and `pbMessageToText` prints the whole message like
`protoc --decode_raw`. A decoded message encodes back to the same bytes.

- `package:tekartik_app_pb/pb_reader.dart`: the model, the decoder and the
  text dump. It does not link the writer.
- `package:tekartik_app_pb/pb_writer.dart`: the model and the encoder. It does
  not link the reader.
- `package:tekartik_app_pb/pb.dart`: both.

64-bit values (varints, fixed64) are held as two 32-bit halves, so they are
exact with dart2js too (`toUnsignedBigInt`, `toSignedBigInt`).

## Setup

```yaml
dependencies:
  tekartik_app_pb:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_pb
    version: '>=0.1.0'
```

## Read

```dart
import 'package:tekartik_app_pb/pb_reader.dart';

void printTestResults(List<int> bytes) {
  // An android `test-result.pb` (TestSuiteResult).
  var suite = pbDecodeMessage(bytes);
  for (var result in suite.messageValues(3)) {
    var testCase = result.messageValue(1)!;
    print('${testCase.stringValue(1)}.${testCase.stringValue(3)}: '
        '${result.intValue(2)}');
  }
  print(pbMessageToText(suite));
}
```

Length delimited values are kept as raw bytes (`PbBytes`) since the wire does
not say whether they hold a string, an embedded message or packed values:
`tryDecodeString()`, `tryDecodeMessage()`, `tryDecodePackedVarints()`... read
them as one or the other, `pbGuessBytesKind` guesses.

## Write

```dart
import 'package:tekartik_app_pb/pb_writer.dart';

void main() {
  var message = PbMessage()
    ..addString(1, 'hello')
    ..addInt(2, 150)
    ..addMessage(3, PbMessage()..addBool(1, true));
  print(pbEncodeMessage(message));
}
```

## Command line

```bash
dart run tekartik_app_pb:pb_dump test-result.pb
```
