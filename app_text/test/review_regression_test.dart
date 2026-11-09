import 'package:tekartik_app_text/sanitize.dart';
import 'package:tekartik_app_text/search.dart';
import 'package:test/test.dart';

/// Regression tests of the 2026-11-09 review.
void main() {
  test('sanitizeString without letter nor digit', () {
    expect(sanitizeString('!'), '');
    expect(sanitizeString(' - '), '');
    expect(sanitizeString('_'), '');
    // Non latin letters are not kept.
    expect(sanitizeString('мир'), '');
    expect(sanitizeString('(a)'), 'a');
    expect(sanitizeString('_a_'), 'a');
  });
  test('SearchTextFinder with punctuation', () {
    expect(SearchTextFinder(searchText: 'abc').findIn('!'), isFalse);
    expect(SearchTextFinder(searchText: 'abc').findAllIn('?'), isFalse);
    // An empty search finds everything.
    expect(SearchTextFinder(searchText: '?').findIn('abc'), isTrue);
  });
}
