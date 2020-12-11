import 'package:tekartik_app_http/app_http.dart';
import 'package:test/test.dart';

var simleJsonUrl =
    'https://firebasestorage.googleapis.com/v0/b/tekartik-free-dev.appspot.com/o/test%2Fexpected%2Ftest.json?alt=media';
void main() {
  group('app_http', () {
    test('simple', () async {
      // If this fails, it is because the file has been removed from firebase storage
      var response = await httpClientFactory.newClient().get(simleJsonUrl);
      print(response.body);
      expect(response.statusCode, httpStatusCodeOk);
    });
  });
}
