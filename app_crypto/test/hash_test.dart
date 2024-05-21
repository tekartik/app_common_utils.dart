import 'package:tekartik_app_crypto/hash.dart';
import 'package:test/test.dart';

void main() {
  test('md5', () {
    expect(md5Hash('test'), '098f6bcd4621d373cade4e832627b4f6');
    expect(md5Hash('test1'), '5a105e8b9d40e1329780d62ea2265d8a');
    expect(md5Hash(''), 'd41d8cd98f00b204e9800998ecf8427e');
  });
}
