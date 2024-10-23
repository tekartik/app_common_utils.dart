import 'package:tekartik_app_media/mime_type.dart';
import 'package:test/test.dart';

void main() {
  group('mime_type', () {
    test('constants', () {
      // Ensure it is a const
      const types = [mimeTypeApplicationJson];
      expect(types, ['application/json']);
    });
  });
}
