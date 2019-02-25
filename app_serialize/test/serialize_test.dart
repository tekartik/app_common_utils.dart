import 'package:tekartik_app_serialize/serialize.dart';
import 'package:test/test.dart';

import 'src/extends.dart';
import 'src/simple.dart';

void main() {
  test('generate fromMap/toMap', () async {
    await genSerializer(src: 'test/src/simple.dart', type: Simple);
  });

  test('extends generate fromMap/toMap', () async {
    await genSerializer(src: 'test/src/extends.dart', type: Complex);
  });
}
