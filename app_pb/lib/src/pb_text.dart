import 'pb_model.dart';
import 'pb_reader.dart';

/// [text] escaped for a double quoted text format string.
String pbEscapeString(String text) {
  var buffer = StringBuffer();
  for (var rune in text.runes) {
    switch (rune) {
      case 0x0a:
        buffer.write(r'\n');
      case 0x0d:
        buffer.write(r'\r');
      case 0x09:
        buffer.write(r'\t');
      case 0x22:
        buffer.write(r'\"');
      case 0x5c:
        buffer.write(r'\\');
      default:
        if (rune < 0x20 || rune == 0x7f) {
          buffer.write('\\${rune.toRadixString(8).padLeft(3, '0')}');
        } else {
          buffer.writeCharCode(rune);
        }
    }
  }
  return buffer.toString();
}

/// [bytes] escaped for a double quoted text format string: printable ascii
/// as itself, the rest as octal escapes.
String pbEscapeBytes(List<int> bytes) {
  var buffer = StringBuffer();
  for (var byte in bytes) {
    switch (byte) {
      case 0x0a:
        buffer.write(r'\n');
      case 0x0d:
        buffer.write(r'\r');
      case 0x09:
        buffer.write(r'\t');
      case 0x22:
        buffer.write(r'\"');
      case 0x5c:
        buffer.write(r'\\');
      default:
        if (byte < 0x20 || byte >= 0x7f) {
          buffer.write('\\${byte.toRadixString(8).padLeft(3, '0')}');
        } else {
          buffer.writeCharCode(byte);
        }
    }
  }
  return buffer.toString();
}

/// [message] in the text format `protoc --decode_raw` prints: field numbers
/// instead of names, varints as unsigned decimals, fixed values in hex,
/// embedded messages as blocks.
///
/// Length delimited values are shown as [pbGuessBytesKind] guesses them,
/// which differs from protoc on purpose for short texts that also decode as
/// messages (protoc tries the message first).
String pbMessageToText(PbMessage message, {String indent = '  '}) {
  var buffer = StringBuffer();
  _writeFields(buffer, message, '', indent);
  return buffer.toString();
}

void _writeFields(
  StringBuffer buffer,
  PbMessage message,
  String prefix,
  String indent,
) {
  for (var field in message.fields) {
    var number = field.number;
    switch (field.value) {
      case PbVarint value:
        buffer.writeln('$prefix$number: ${value.toUnsignedString()}');
      case PbFixed64 value:
        buffer.writeln('$prefix$number: 0x${value.toHex()}');
      case PbFixed32 value:
        buffer.writeln('$prefix$number: 0x${value.toHex()}');
      case PbGroup(:var message):
        _writeBlock(buffer, number, message, prefix, indent);
      case PbEmbedded(:var message):
        _writeBlock(buffer, number, message, prefix, indent);
      case PbBytes(:var bytes):
        switch (pbGuessBytesKind(bytes)) {
          case PbBytesKind.message:
            _writeBlock(buffer, number, pbDecodeMessage(bytes), prefix, indent);
          case PbBytesKind.string:
            var text = PbBytes(bytes).tryDecodeString()!;
            buffer.writeln('$prefix$number: "${pbEscapeString(text)}"');
          case PbBytesKind.bytes:
            buffer.writeln('$prefix$number: "${pbEscapeBytes(bytes)}"');
        }
    }
  }
}

void _writeBlock(
  StringBuffer buffer,
  int number,
  PbMessage message,
  String prefix,
  String indent,
) {
  buffer.writeln('$prefix$number {');
  _writeFields(buffer, message, '$prefix$indent', indent);
  buffer.writeln('$prefix}');
}
