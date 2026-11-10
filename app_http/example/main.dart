// ignore_for_file: avoid_print

import 'package:tekartik_app_http/app_http.dart';

/// Works on the Dart VM, in the browser and in Flutter.
Future<void> main() async {
  var client = httpClientFactoryUniversal.newClient();
  try {
    var response = await client.get(Uri.parse('https://example.com/'));
    if (isHttpStatusCodeSuccessful(response.statusCode)) {
      print('${response.statusCode} ${response.body.length} chars');
    } else {
      print('failed: ${response.statusCode}');
    }
  } finally {
    client.close();
  }
}
