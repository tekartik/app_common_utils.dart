import 'package:mime/mime.dart' as mime;
import 'package:tekartik_app_media/mime_type.dart';

/// Get the extension from a mime type
String? extensionFromMimeType(String mimeType) {
  // native implementation does not have leading .
  var ext = mime.extensionFromMime(mimeType) ?? _mimeTypeExtMap[mimeType];
  if (ext != null) {
    return '.$ext';
  }
  return null;
}

var _extMimeTypeExtraMap = {'yaml': 'application/yaml'};

var _mimeTypeExtMap = Map.fromEntries(
  _extMimeTypeExtraMap.entries.map((entry) => MapEntry(entry.value, entry.key)),
);

String _ext(String path) {
  final index = path.lastIndexOf('.');
  if (index < 0 || index + 1 >= path.length) return path;
  return path.substring(index + 1).toLowerCase();
}

/// Get the mime type from a filename, default to octet-stream
String filenameMimeType(String filename) {
  return extensionMimeType(filename) ?? mimeTypeOctetStream;
}

/// Get the mime type from an extension (without or without leading .)
String? extensionMimeType(String extension) {
  var fixedExtension = _ext(extension);
  return mime.lookupMimeType(fixedExtension) ??
      _extMimeTypeExtraMap[fixedExtension];
}
