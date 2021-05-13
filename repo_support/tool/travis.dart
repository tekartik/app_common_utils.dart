import 'package:dev_test/package.dart';
import 'package:process_run/shell.dart';
import 'package:path/path.dart';

Future main() async {
  var shell = Shell();

  for (var dir in [
    'app_emit',
  ]) {
    shell = shell.pushd(join('..', dir));
    await shell.run('''
    
  pub get
  dart tool/travis.dart
  
''');
    shell = shell.popd();
  }

  for (var dir in [
    'app',
    'app_bloc',
    'app_cv',
    'app_cv_firestore',
    'app_rx_bloc',
    'app_crypto',
    'app_csv',
    'app_http',
    'app_web_socket',
    'app_serialize',
    'app_pager',
    'app_mirrors',
  ]) {
    await packageRunCi(join('..', dir));
  }
}
