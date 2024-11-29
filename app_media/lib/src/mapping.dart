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
