import 'package:tekartik_app_dev_menu/dev_menu.dart';
import 'package:test/test.dart';

var myVar = 'n1xqmEiN4xLJy6bQDGNk.myTestVar'.kvFromVar(defaultValue: '12345');
void main() {
  group('universal vars', () {
    test('init', () async {
      expect(myVar.value, '12345');
      expect(myVar.valid, true);
      var myVar2 = 'n1xqmEiN4xLJy6bQDGNk.myTestVar2'.kvFromVar();
      expect(myVar2.value, isNull);
      expect(myVar2.valid, false);
    });
    test('delete/set/get', () async {
      await myVar.delete();
      expect(myVar.get(), isNull);
      await myVar.set('test');
      expect(myVar.get(), 'test');
      await myVar.set('test1');
      expect(myVar.get(), 'test1');
      await myVar.set(null);
      expect(myVar.get(), isNull);
    });
  });
}
