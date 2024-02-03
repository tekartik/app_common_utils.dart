import 'package:dev_build/package.dart';
import 'package:path/path.dart';

Future main() async {
  for (var dir in [
    'app_intl',
    'app_cv_firestore',
    'app_cv',
    'app',
    'app_emit',
    'app_pager',
    'app_serialize',
    'app_mirrors',
    'app_crypto',
    'app_csv',
    'app_web_socket',
    'app_bloc',
    'app_rx_bloc',
    'app_http',
    'app_sembast',
    'app_sqflite',
    'app_prefs',
  ]) {
    await packageRunCi(join('..', dir));
  }
}
