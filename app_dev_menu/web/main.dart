import 'package:tekartik_app_dev_menu/dev_menu.dart';

var kvTestValue = 'TestValue'.kvFromVar();
Future main(List<String> arguments) async {
  await mainMenu(arguments, () {
    keyValuesMenu('kv', [kvTestValue]);
    item('write hola', () async {
      write('!Hola');
      //write('RESULT prompt: ${await prompt()}');
    });
    item('prompt', () async {
      write('RESULT prompt: ${await prompt('Some text please then [ENTER]')}');
    });
  });
}
