import 'package:tekartik_app_web_socket/web_socket.dart';
import 'package:test/test.dart';

void main() {
  group('web_socket', () {
    test('factory', () {
      expect(webSocketChannelClientFactory, isNotNull);
    });
  });
}
