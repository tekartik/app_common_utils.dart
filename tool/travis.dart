import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

  for (var dir in [
    'app',
    'app_emit',
    'app_pager',
    'app_serialize',
    'app_mirrors',
    'app_crypto',
    'app_csv',
    'app_web_socket',
    'app_bloc'
  ]) {
    shell = shell.pushd(dir);
    await shell.run('''
    
  pub get
  dart tool/travis.dart
  
''');
    shell = shell.popd();
  }
}
