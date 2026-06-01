import 'package:tekartik_http/http.dart';

import 'platform/platform.dart' show httpClientFactoryUniversal;

export 'platform/platform.dart' show httpClientFactoryUniversal;

/// Compatibility getter, prefer using [httpClientFactoryUniversal].
// @Deprecated('Use httpClientFactoryUniversal')
HttpClientFactory get httpClientFactory => httpClientFactoryUniversal;
