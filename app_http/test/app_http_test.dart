import 'dart:convert';

import 'package:tekartik_app_http/app_http.dart';
import 'package:test/test.dart';

/// A static file of the test fixtures site (CORS enabled, so readable from a
/// browser test too).
final connectedFixtureUri = Uri.parse(
  'https://tekartik-test-fixtures.web.app/http/connected.json',
);

void main() {
  group('app_http', () {
    test('compat', () {
      expect(httpClientFactory, httpClientFactoryUniversal);
    });
    test('simple', () async {
      var client = httpClientFactoryUniversal.newClient();
      try {
        var response = await client.get(connectedFixtureUri);
        expect(response.statusCode, httpStatusCodeOk);
        var map = jsonDecode(response.body) as Map;
        expect(map['name'], 'tekartik_http_test');
      } finally {
        client.close();
      }
    });
  });
}
