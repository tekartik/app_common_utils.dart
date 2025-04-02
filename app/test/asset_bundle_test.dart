import 'dart:typed_data';

import 'package:tekartik_app_common_utils/asset/asset_bundle.dart';
import 'package:test/test.dart';

void main() {
  test('asset_bundle', () {
    var assetBundle = TkAssetBundleMemory();
    assetBundle.setBytes('bytes', Uint8List.fromList([1, 2, 3]));
    expect(
      assetBundle.loadBytes('bytes'),
      completion(Uint8List.fromList([1, 2, 3])),
    );
    assetBundle.setString('string', 'test');
    expect(assetBundle.loadString('string'), completion('test'));
  });
}
