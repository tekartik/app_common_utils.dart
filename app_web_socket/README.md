# tekartik_app_web_socket

Web socket factory for app (web, io, flutter)

## Getting Started

### Setup

```yaml
dependencies:
  tekartik_app_web_socket:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_web_socket
    version: '>=0.1.0'
```

### Usage

```dart
import 'package:tekartik_app_web_socket/web_socket.dart';

Future main() async {
  var channel =
      webSocketChannelClientFactory.connect('wss://my.web.socket.url');
  ...
}
```
