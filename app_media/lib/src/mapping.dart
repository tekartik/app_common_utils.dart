import 'package:path/path.dart';
import 'package:tekartik_app_media/mime_type.dart';

const _mimeTypeExtensions = {
  mimeTypeApplicationJson: extensionApplicationJson,
  mimeTypeImageJpg: extensionImageJpg,
  mimeTypeImagePng: extensionImagePng,
  mimeTypeImageWebp: extensionImageWebp,
  mimeTypeApplicationZip: extensionApplicationZip,
};

/// Get the extension from a mime type
String? extensionFromMimeType(String mimeType) {
  return _mimeTypeExtensions[mimeType];
}

var _mimeTypeMap = {
  '.css': 'text/css',
  '.dart': 'application/dart',
  '.gif': 'image/gif',
  '.html': 'text/html',
  '.ico': 'image/x-icon',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.js': 'application/javascript',
  '.json': 'application/json',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.txt': 'text/plain',
  '.webp': 'image/webp',
  '.woff': 'application/font-woff',
  '.woff2': 'application/font-woff2',
  '.wasm': 'application/wasm',
  '.pdf': 'application/pdf',
  '.yaml': 'application/yaml',
  '.mp4': 'video/mp4',
  '.ics': 'text/calendar',
};

const _mimeTypeDefault = 'application/octet-stream';
String filenameMimeType(String filename) {
  var ext = extension(basename(filename)).toLowerCase();
  return _mimeTypeMap[ext] ?? _mimeTypeDefault;
}
