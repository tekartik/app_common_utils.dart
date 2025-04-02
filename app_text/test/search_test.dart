import 'package:tekartik_app_text/search.dart';
import 'package:test/test.dart';

Future<void> main() async {
  test('splitByWhitespace', () {
    var finder = SearchTextFinder(searchText: '  Ma éL  ');
    expect(finder.findIn(''), isFalse);
    expect(finder.findIn(' to ma'), isTrue);
    expect(finder.findIn('Elev   ma'), isTrue);
  });
}
