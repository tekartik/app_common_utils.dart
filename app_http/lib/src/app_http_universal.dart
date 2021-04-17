import 'package:tekartik_app_http/app_http.dart';
import 'package:tekartik_common_utils/env_utils.dart';
import 'package:tekartik_http/http_client.dart';

HttpClientFactory? _httpClientFactory;

/// The convenient client factory
HttpClientFactory get httpClientFactory => _httpClientFactory ??= () {
      if (isRunningAsJavascript) {
        return httpClientFactoryBrowser;
      } else {
        return httpClientFactoryIo;
      }
    }();
