import 'package:tekartik_http/http.dart';

import 'platform/platform.dart' show httpClientFactoryUniversal;

export 'platform/platform.dart' show httpClientFactoryUniversal;

// Compat, prefer using httpClientFactoryUniversal
// @Deprecated('Use httpClientFactoryUniversal')
HttpClientFactory get httpClientFactory => httpClientFactoryUniversal;
