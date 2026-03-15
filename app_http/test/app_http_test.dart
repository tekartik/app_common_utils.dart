import 'package:tekartik_app_http/app_http.dart';
import 'package:test/test.dart';

var simplePublicUrl = 'https://cdn.ampproject.org/v0.js';

void main() {
  group('app_http', () {
    test('compat', () {
      expect(httpClientFactory, httpClientFactoryUniversal);
    });
    test('simple', () async {
      // If this fails, update the url!
      var response = await httpClientFactoryUniversal.newClient().get(
        Uri.parse(simplePublicUrl),
      );
      print(response.body);
      expect(response.statusCode, httpStatusCodeOk);
    });
  });
}
