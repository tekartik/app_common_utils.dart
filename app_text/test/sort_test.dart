import 'package:tekartik_app_text/diacritic.dart';
import 'package:tekartik_app_text/sort.dart';
import 'package:test/test.dart';

void main() {
  group('sort', () {
    test('alphaNumericSort', () {
      var list = <String>[
        'item 1 via 3',
        'item 2',
        'item 10',
        'Item 5',
        'item 1 via 4',
        'item 20 other',
      ];
      list.alphaNumericSort();
      expect(list, [
        'Item 5',
        'item 1 via 3',
        'item 1 via 4',
        'item 2',
        'item 10',
        'item 20 other',
      ]);
    });

    test('ignore-case-diacritics', () {
      var list = <String>['ze 2', 'Zé 1', 'Zé 10'];
      var newList = list.toSortedByAlphaNumericTextList(
        (item) => item.removeDiacritics().toLowerCase(),
      );
      expect(newList, ['Zé 1', 'ze 2', 'Zé 10']);
      newList = list.toSortedByAlphaNumericTextList((item) => item);
      expect(newList, ['Zé 1', 'Zé 10', 'ze 2']);
      newList = list.toSortedBySmartTextList((item) => item);
      expect(newList, ['Zé 1', 'ze 2', 'Zé 10']);
    });
  });
}
