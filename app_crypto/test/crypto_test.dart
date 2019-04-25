import 'package:tekartik_app_crypto/encrypt.dart';
import 'package:test/test.dart';

void main() {
  void _roundTrip(String decoded, String password) {
    expect(decrypt(encrypt(decoded, password), password), decoded);
  }

  test('test', () {
    var password = r'E4x*$TwbkJC-xK4KGC4zJF9j*Rh&WLgR';
    expect(encrypt('test', password), 'amGhyRRLUIoE59IiEys5Vw==');
    expect(decrypt('amGhyRRLUIoE59IiEys5Vw==', password), 'test');

    _roundTrip('a', password);
    _roundTrip(
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
        password);

    // Use accent
    password = r'éx*$TwbkJC-xK4KGC4zJF9j*Rh&WLgR';
    _roundTrip('é', password);
  });
}
