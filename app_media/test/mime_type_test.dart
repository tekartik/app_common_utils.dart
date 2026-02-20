import 'package:tekartik_app_media/mime_type.dart';
import 'package:test/test.dart';

void main() {
  group('mime_type', () {
    test('constants', () {
      // Ensure it is a const
      const types = [
        mimeTypeApplicationJson,
        mimeTypeImagePng,
        mimeTypeImageJpg,
        mimeTypeImageWebp,
      ];
      expect(types, [
        'application/json',
        'image/png',
        'image/jpeg',
        'image/webp',
      ]);
      const extensions = [
        extensionApplicationJson,
        extensionImagePng,
        extensionImageJpg,
        extensionImageWebp,
      ];
      expect(extensions, ['.json', '.png', '.jpg', '.webp']);
    });
    test('extensionFromMimeType', () {
      expect(
        extensionFromMimeType(mimeTypeApplicationJson),
        extensionApplicationJson,
      );
      expect(extensionFromMimeType(mimeTypeImagePng), extensionImagePng);
      expect(extensionFromMimeType(mimeTypeImageJpg), extensionImageJpg);
      expect(extensionFromMimeType(mimeTypeImageWebp), extensionImageWebp);
      expect(
        extensionFromMimeType(mimeTypeApplicationZip),
        extensionApplicationZip,
      );
    });
    test('mimeType', () {
      expect(filenameMimeType('test.txt'), 'text/plain');
      expect(filenameMimeType('test2.gif'), 'image/gif');
    });
    test('compat', () {
      for (var entry in _mimeTypeMap.entries) {
        var ext = entry.key;
        var mime = entry.value;
        expect(extensionMimeType(ext), mime);
        if (mime != 'image/jpeg') {
          expect(extensionFromMimeType(mime), ext);
        }
      }
      for (var entry in _mimeTypeExtensions.entries) {
        var mime = entry.key;
        var ext = entry.value;

        expect(extensionMimeType(ext), mime);
        expect(extensionFromMimeType(mime), ext);
      }
    });
  });
}

var _mimeTypeMap = {
  '.css': 'text/css',
  '.dart': 'text/x-dart',
  '.gif': 'image/gif',
  '.html': 'text/html',
  '.ico': 'image/x-icon',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.js': 'text/javascript',
  '.json': 'application/json',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.txt': 'text/plain',
  '.webp': 'image/webp',
  '.woff': 'application/x-font-woff',
  '.woff2': 'font/woff2',
  '.wasm': 'application/wasm',
  '.pdf': 'application/pdf',
  '.yaml': 'application/yaml',
  '.mp4': 'video/mp4',
  '.ics': 'text/calendar',
};
const _mimeTypeExtensions = {
  mimeTypeApplicationJson: extensionApplicationJson,
  mimeTypeImageJpg: extensionImageJpg,
  mimeTypeImagePng: extensionImagePng,
  mimeTypeImageWebp: extensionImageWebp,
  mimeTypeApplicationZip: extensionApplicationZip,
};
