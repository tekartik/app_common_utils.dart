import 'package:tekartik_app_http/app_http.dart';
import 'package:tekartik_common_utils/env_utils.dart';

HttpClientFactory? _httpClientFactory;

/// The convenient client factory
HttpClientFactory get httpClientFactory => _httpClientFactory ??= () {
      if (isRunningAsJavascript) {
        return httpClientFactoryBrowser;
      } else {
        return httpClientFactoryIo;
      }
    }();
