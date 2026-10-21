/// Reading the protobuf wire format (`.pb` files) without any schema, on
/// every platform (VM, Flutter, dart2js, dart2wasm).
///
/// [pbDecodeMessage] gives the fields as they come on the wire; the
/// [PbMessageReaderExt] getters read them as what the schema would say,
/// [pbMessageToText] prints them like `protoc --decode_raw`.
///
/// This library does not link the writer: see `pb_writer.dart` to encode, or
/// `pb.dart` for both.
///
/// ```dart
/// var message = pbDecodeMessage(bytes);
/// print(message.stringValue(1));
/// print(pbMessageToText(message));
/// ```
library;

export 'src/pb_model.dart';
export 'src/pb_reader.dart'
    show
        PbBytesKind,
        PbFormatException,
        PbLengthDelimitedReaderExt,
        PbMessageReaderExt,
        PbReader,
        pbDecodeMessage,
        pbGuessBytesKind,
        pbMaxGroupDepth,
        pbTryDecodeMessage;
export 'src/pb_text.dart' show pbEscapeBytes, pbEscapeString, pbMessageToText;
