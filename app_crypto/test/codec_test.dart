import 'package:tekartik_app_crypto/encrypt_codec.dart';

import 'package:test/test.dart';

void main() {
  test('test', () {
    var password = r'E4x*$TwbkJC-xK4KGC4zJF9j*Rh&WLgR';
    var encryptCodec = defaultEncryptCodec(rawPassword: password);
    expect(encryptCodec.encode('test'), 'amGhyRRLUIoE59IiEys5Vw==');
    expect(encryptCodec.decode('amGhyRRLUIoE59IiEys5Vw=='), 'test');
  });
}
