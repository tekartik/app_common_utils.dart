import 'dart:io';

import 'package:tekartik_app_pb/pb_reader.dart';

/// Prints `.pb` files in the protobuf text format, like
/// `protoc --decode_raw` (no schema needed).
Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty ||
      arguments.contains('-h') ||
      arguments.contains('--help')) {
    stdout.writeln('Usage: pb_dump <file.pb>...');
    stdout.writeln('Prints protobuf files as text, field numbers for names.');
    if (arguments.isEmpty) {
      exitCode = 64;
    }
    return;
  }
  for (var path in arguments) {
    if (arguments.length > 1) {
      stdout.writeln('# $path');
    }
    try {
      var message = pbDecodeMessage(await File(path).readAsBytes());
      stdout.write(pbMessageToText(message));
    } on PbFormatException catch (e) {
      stderr.writeln(
        '$path: not a protobuf message: ${e.message} '
        'at offset ${e.offset}',
      );
      exitCode = 1;
    } on FileSystemException catch (e) {
      stderr.writeln('$path: ${e.message}');
      exitCode = 1;
    }
  }
}
