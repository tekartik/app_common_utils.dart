import 'package:tekartik_app_text/search.dart';
import 'package:test/test.dart';

Future<void> main() async {
  test('SearchTextFinder', () {
    var finder = SearchTextFinder(searchText: '  Ma éL  ');
    expect(finder.findIn(''), isFalse);
    expect(finder.findIn(' to ma'), isFalse);

    expect(finder.findIn('Elev   ma'), isTrue);
    expect(finder.findAllIn('Elev   ma'), isFalse);
    expect(finder.findAllIn('ma Elev   mca'), isTrue);

    finder = SearchTextFinder(searchText: 'i l');
    expect(finder.findAllIn('I loon'), isTrue);
    expect(finder.findAllIn('Delice'), isFalse);
  });
}
