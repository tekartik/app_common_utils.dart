import 'package:tekartik_app_http/app_http.dart';

Future main() async {
  var response =
      await httpClientFactory.newClient().get('https://www.github.com');
  print(response.statusCode);
}
