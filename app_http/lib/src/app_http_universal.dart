import 'package:tekartik_app_http/app_http.dart';
import 'package:tekartik_common_utils/env_utils.dart';

HttpClientFactory? _httpClientFactoryUniversal;

/// The convenient client factory
HttpClientFactory get httpClientFactoryUniversal =>
    _httpClientFactoryUniversal ??= () {
      if (isRunningAsJavascript) {
        return httpClientFactoryBrowser;
      } else {
        return httpClientFactoryIo;
      }
    }();

// Compat
HttpClientFactory get httpClientFactory => httpClientFactoryUniversal;
