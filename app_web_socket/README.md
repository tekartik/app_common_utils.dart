# tekartik_app_web_socket

One web socket client factory for code that runs on the Dart VM, in the
browser and in Flutter: `webSocketChannelClientFactory` is
`tekartik_web_socket_io` on the VM and Flutter, `tekartik_web_socket_browser`
on the web, picked at compile time. It re-exports
[tekartik_web_socket](https://github.com/tekartik/web_socket.dart) (the channel
API and the memory client and server for tests).

## Getting started

Not on pub.dev, add it as a git dependency (Dart SDK `^3.12.0`):

```yaml
dependencies:
  tekartik_app_web_socket:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_web_socket
```

```dart
import 'package:tekartik_app_web_socket/web_socket.dart';

Future<void> talk(String url) async {
  // A ws:// or wss:// url; give the message type.
  var channel = webSocketChannelClientFactory.connect<String>(url);
  try {
    // Completes once connected, throws if the connection fails.
    await channel.ready;
  } catch (e) {
    print('cannot connect: $e');
    return;
  }
  channel.stream.listen(
    (message) => print('received $message'),
    onError: (Object error) => print('error $error'),
    onDone: () => print('closed'),
  );
  channel.sink.add('hello');
  await Future<void>.delayed(const Duration(seconds: 1));
  await channel.sink.close();
}
```

[example/main.dart](example/main.dart) runs it against a local echo server
(Dart VM).

## Platforms

* Dart VM and Flutter (Android, iOS, desktop): `webSocketChannelClientFactoryIo`.
* Browser and Flutter web (dart2js, dart2wasm):
  `webSocketChannelClientFactoryBrowser` (a `wss://` url from an https page).
* Tests on any platform: `webSocketChannelServerFactoryMemory` and
  `webSocketChannelClientFactoryMemory` (no network).

The server side is not here: `webSocketChannelServerFactoryIo` of
`tekartik_web_socket_io` on the VM.

## Common pitfalls

* `connect` returns at once: errors come on `ready` and on the stream. A url
  without a scheme throws right away on the VM, not in a browser.
* `channel.stream` is a single subscription stream: listen once.
* No automatic reconnect: after the stream is done, connect a new channel.
* Take a `WebSocketChannelClientFactory` parameter in your code instead of
  the global: tests pass the memory factory.

## Agent skills

[skills/tekartik-app-web-socket-client](skills/tekartik-app-web-socket-client/SKILL.md).
