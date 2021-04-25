# tekartik_app_http

Http client factory for app (web, io, flutter)

## Getting Started

### Setup

```yaml
dependencies:
  tekartik_app_http:
    git:
      url: git://github.com/tekartik/app_common_utils.dart
      ref: null_safety
      path: app_http
    version: '>=0.1.0'
```

### Usage

```dart
import 'package:tekartik_app_http/app_http.dart';

Future main() async {
  var response =
    await httpClientFactory.newClient().get('https://www.github.com');
  print(response.statusCode);
  ...
}
```