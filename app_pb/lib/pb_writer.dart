/// Writing the protobuf wire format without any schema, on every platform
/// (VM, Flutter, dart2js, dart2wasm).
///
/// Build a [PbMessage] (`addInt`, `addString`, `addMessage`...) or change a
/// decoded one, then [pbEncodeMessage] it.
///
/// This library does not link the reader: see `pb_reader.dart` to decode, or
/// `pb.dart` for both.
///
/// ```dart
/// var message = PbMessage()
///   ..addString(1, 'hello')
///   ..addInt(2, 150)
///   ..addMessage(3, PbMessage()..addBool(1, true));
/// var bytes = pbEncodeMessage(message);
/// ```
library;

export 'src/pb_model.dart';
export 'src/pb_writer.dart' show PbMessageWriterExt, PbWriter, pbEncodeMessage;
