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
  });
}
