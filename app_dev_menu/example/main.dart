// Example that works for both web and io
library;

import 'package:tekartik_app_dev_menu/dev_menu.dart';

var myVar = 'my_var'.kvFromVar();

void main(List<String> arguments) async {
  await mainMenu(arguments, () {
    keyValuesMenu('kv_menu', [myVar]);
    menu('main', () {
      item('write hola', () async {
        write('Hola');
        //write('RESULT prompt: ${await prompt()}');
      });
      item('prompt', () async {
        write(
          'RESULT prompt: ${await prompt('Some text please then [ENTER]')}',
        );
      });
      item('dump_my_var', () async {
        write(myVar.get());
      });

      item('print hi', () {
        print('hi');
      });
      item('crash', () {
        throw 'Hi';
      });
      menu('sub', () {
        item('print hi', () => print('hi'));
      });
    });
  });
}
