import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

  await shell.run('''
dartanalyzer --fatal-warnings --fatal-infos .
dartfmt -n --set-exit-if-changed .
dart pub run build_runner test -- -p vm,chrome
dart pub run test -p vm,chrome
''');
}
