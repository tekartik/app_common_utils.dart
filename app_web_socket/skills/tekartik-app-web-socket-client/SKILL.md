---
name: tekartik-app-web-socket-client
description: >-
  Use when connecting to a web socket from a cross platform Dart or Flutter app
  with tekartik_app_web_socket: the webSocketChannelClientFactory getter and
  factory.connect<T>(url) returning a WebSocketChannel<T> (ready, stream, sink)
  from package:tekartik_app_web_socket/web_socket.dart, which picks
  tekartik_web_socket_io on the VM and tekartik_web_socket_browser on the web,
  and re-exports WebSocketChannelClientFactory, WebSocketChannelServer,
  webSocketUrlScheme and the memory factories
  (webSocketChannelClientFactoryMemory, webSocketChannelServerFactoryMemory)
  used to test without a real server.
---

# Cross platform web socket client (tekartik_app_web_socket)

`tekartik_app_web_socket` answers one question: which
`WebSocketChannelClientFactory` should this app use? It picks
`tekartik_web_socket_io` (dart:io / `web_socket_channel`) on the VM and
Flutter, `tekartik_web_socket_browser` on the web, and re-exports the
`tekartik_web_socket` API so a single import is enough.

## Guidelines

* Not on pub.dev, depend on it through git (the package lives in the
  `app_web_socket/` directory of the repo):
  ```yaml
  dependencies:
    tekartik_app_web_socket:
      git:
        url: https://github.com/tekartik/app_common_utils.dart
        path: app_web_socket
      version: '>=0.1.0'
  ```
* Import `package:tekartik_app_web_socket/web_socket.dart` only. It declares
  the single `webSocketChannelClientFactory` getter and re-exports
  `package:tekartik_web_socket/web_socket.dart`: `WebSocketChannel`,
  `WebSocketChannelClientFactory`, `WebSocketChannelServerFactory`,
  `WebSocketChannelServer`, `WebSocketChannelNative`, `webSocketUrlScheme`
  (`'ws'`), the memory factories and `smartWebSocketChannelClientFactory`.
  Never import `tekartik_web_socket_io` / `tekartik_web_socket_browser` in
  shared code - that is what this package chooses for you (a platform with
  neither `dart:io` nor `dart:js_interop` throws `UnimplementedError`).
* `webSocketChannelClientFactory.connect<T>(url)` returns a
  `WebSocketChannel<T>` immediately, before the connection is established.
  Always pass the type argument explicitly: incoming data is cast to `T`, so
  use `connect<String>(...)` for a text protocol (JSON) and
  `connect<Object?>(...)` when the peer may also send binary frames. `url` is a
  full `ws://` or `wss://` url (on the web, a `wss://` url is required from an
  https page).
* `await channel.ready` completes when the socket is open and throws on a
  failed connection - wrap it in a `try`/`catch` to report "cannot connect".
  Messages sent before `ready` are buffered by the underlying implementation,
  but do not `await channel.stream.first` without also handling the error.
* The channel is a `StreamChannelMixin<T>`: read with
  `channel.stream.listen(...)` and write with `channel.sink.add(message)`.
  `channel.stream` is a **single subscription** stream: listen once, or wrap it
  in a broadcast stream if several parts of the app need it. Close with
  `await channel.sink.close()`; the remote end closing completes the stream
  (`onDone`).
* There is no automatic reconnect, ping/pong or backoff: implement retries
  yourself (a loop around `connect` + `ready`, with a delay), and do not reuse
  a channel after its stream is done - create a new one.
* Server side: this package only exposes the **client** factory. For a Dart VM
  server, depend on `tekartik_web_socket_io` and use its
  `webSocketChannelServerFactoryIo.serve<T>(address:, port:)`, which yields a
  `WebSocketChannelServer<T>` whose `stream` emits one `WebSocketChannel<T>`
  per client, plus `port`, `url` and `close()`.
* Tests: `webSocketChannelServerFactoryMemory.serve<T>(port: 1234)` +
  `webSocketChannelClientFactoryMemory.connect<T>(server.url)` (the url looks
  like `ws:1234`) give a full in-memory client/server pair with no network and
  no platform dependency, so the test runs on the VM and in the browser. Inject
  the factory into your code (a `WebSocketChannelClientFactory` parameter
  defaulting to `webSocketChannelClientFactory`) so tests can swap it.
* Anti-patterns: calling `connect` without a type argument (messages become
  `dynamic`); listening to `channel.stream` twice; assuming `connect` throws on
  a bad url (the error arrives on `ready`/`stream`); keeping a channel after
  `sink.close()`; hard-coding `webSocketChannelClientFactory` deep in the code
  instead of injecting it.

## Examples

### Connect, send and receive

```dart
import 'dart:convert';

import 'package:tekartik_app_web_socket/web_socket.dart';

Future<void> main() async {
  var channel = webSocketChannelClientFactory.connect<String>(
    'wss://my.web.socket.url',
  );
  try {
    await channel.ready;
  } catch (e) {
    print('cannot connect: $e');
    return;
  }

  // Single subscription stream: listen once.
  var subscription = channel.stream.listen(
    (message) {
      var data = jsonDecode(message) as Map<String, Object?>;
      print('received $data');
    },
    onError: (Object error) => print('socket error $error'),
    onDone: () => print('socket closed'),
  );

  channel.sink.add(jsonEncode({'action': 'subscribe', 'topic': 'news'}));

  await Future<void>.delayed(const Duration(seconds: 5));
  await subscription.cancel();
  await channel.sink.close();
}
```

### Inject the factory, with a simple reconnect loop

```dart
import 'package:tekartik_app_web_socket/web_socket.dart';

/// A client that can be tested with the memory factory.
class NewsClient {
  final String url;
  final WebSocketChannelClientFactory factory;
  WebSocketChannel<String>? _channel;

  NewsClient({
    required this.url,
    WebSocketChannelClientFactory? factory,
    // Defaults to the platform factory (io or browser).
  }) : factory = factory ?? webSocketChannelClientFactory;

  /// Connect, retrying with a fixed delay.
  Future<WebSocketChannel<String>> connect({int retryCount = 3}) async {
    for (var i = 0; ; i++) {
      var channel = factory.connect<String>(url);
      try {
        await channel.ready;
        return _channel = channel;
      } catch (e) {
        await channel.sink.close();
        if (i >= retryCount) {
          rethrow;
        }
        // No automatic reconnect: wait and create a brand new channel.
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
  }

  void send(String message) => _channel!.sink.add(message);

  Future<void> close() async => _channel?.sink.close();
}
```

### Test with the in-memory client/server pair

```dart
import 'package:tekartik_app_web_socket/web_socket.dart';
import 'package:test/test.dart';

void main() {
  test('memory echo server', () async {
    // No network, works on the vm and in the browser.
    var server = await webSocketChannelServerFactoryMemory.serve<String>(
      port: 1234,
    );
    server.stream.listen((channel) {
      channel.stream.listen((message) => channel.sink.add('echo $message'));
    });
    expect(server.url, 'ws:1234'); // memory url, pass it to the client

    var client = webSocketChannelClientFactoryMemory.connect<String>(
      server.url,
    );
    await client.ready;
    client.sink.add('hello');
    expect(await client.stream.first, 'echo hello');

    await client.sink.close();
    await server.close();
  });
}
```
