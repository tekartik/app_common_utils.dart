// ignore_for_file: avoid_print

import 'package:tekartik_app_pb/pb.dart';

void main() {
  // Build a message without any schema: field numbers and values.
  var message = PbMessage()
    ..addString(1, 'Pixel')
    ..addInt(2, 36)
    ..addInt(3, -1)
    ..addMessage(4, PbMessage()..addBool(1, true))
    ..addString(5, 'x86_64')
    ..addString(5, 'arm64-v8a');
  var bytes = pbEncodeMessage(message);

  // Read it back.
  var decoded = pbDecodeMessage(bytes);
  print(decoded.stringValue(1)); // Pixel
  print(decoded.intValue(2)); // 36
  print(decoded.intValue(3)); // -1
  print(decoded.messageValue(4)!.boolValue(1)); // true
  print(decoded.stringValues(5)); // [x86_64, arm64-v8a]

  // Print it like protoc --decode_raw.
  print(pbMessageToText(decoded));
}
