// ignore_for_file: avoid_print

import 'package:tekartik_app_web_socket/web_socket.dart';
import 'package:tekartik_web_socket_io/web_socket_io.dart'
    show webSocketChannelServerFactoryIo;

/// A local echo server (Dart VM) and the platform client.
Future<void> main() async {
  var server = await webSocketChannelServerFactoryIo.serve<String>(port: 0);
  server.stream.listen((channel) {
    channel.stream.listen((message) => channel.sink.add('echo $message'));
  });

  // The client code is the same on the VM, in the browser and in Flutter.
  var channel = webSocketChannelClientFactory.connect<String>(server.url);
  try {
    await channel.ready;
  } catch (e) {
    print('cannot connect: $e');
    await server.close();
    return;
  }
  channel.sink.add('hello');
  print(await channel.stream.first); // echo hello

  await channel.sink.close();
  await server.close();
}
