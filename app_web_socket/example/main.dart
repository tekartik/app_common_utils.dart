import 'package:tekartik_app_web_socket/web_socket.dart';

Future main() async {
  var channel = webSocketChannelClientFactory.connect<Object?>(
    'wss://my.web.socket.url',
  );
  await channel.stream.first;
}
