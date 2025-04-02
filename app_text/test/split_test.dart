import 'package:tekartik_app_text/split.dart';
import 'package:test/test.dart';

Future<void> main() async {
  test('splitByWhitespace', () {
    expect(stringSplitByWhitespace('Hello'), ['Hello']);
    expect(stringSplitByWhitespace('Hello world'), ['Hello', 'world']);
    expect(stringSplitByWhitespace('Hello  world'), ['Hello', 'world']);
    expect(stringSplitByWhitespace('Hello  world '), ['Hello', 'world']);
    expect(stringSplitByWhitespace(' Hello \t\r\n world '), ['Hello', 'world']);
    expect(stringSplitByWhitespace(' Hello  world'), ['Hello', 'world']);
    expect(stringSplitByWhitespace(' Hello  world'), ['Hello', 'world']);
    expect(stringSplitByWhitespace(', Hello  world'), [',', 'Hello', 'world']);
  });
}
