import 'dart:async';
import 'dart:math';

import 'package:pedantic/pedantic.dart';
import 'package:tekartik_app_common_utils/pager/pager.dart';
import 'package:tekartik_common_utils/completer/completer.dart';

import 'package:test/test.dart';

class Provider implements PagerDataProvider<int> {
  final int count;

  Provider([this.count = 1]);

  @override
  Future<List<int>> getData(int offset, int limit) async {
    int remainings = count - offset;
    if (remainings < 0) {
      limit = 0;
    } else {
      limit = min(limit, remainings);
    }
    return List<int>.generate(limit, (index) => offset + index);
  }

  @override
  Future<int> getItemCount() async => count;
}

void main() {
  group('pager', () {
    test('provider', () async {
      var provider = Provider(2);
      expect(await provider.getData(0, 3), [0, 1]);
      expect(await provider.getData(0, 1), [0]);
      expect(await provider.getData(1, 2), [1]);
    });

    test('getItem', () async {
      var pager = Pager<int>(provider: Provider(2));
      var item = pager.getItem(0).value;
      expect(item, const TypeMatcher<Future>());
      expect(await item, 0);
    });

    test('wait getItem', () async {
      var pager = Pager<int>(provider: Provider(2));
      var item = pager.getItem(0);
      expect(item.value, const TypeMatcher<Future>());
      expect(await item.future, 0);
      expect(item.value, 0);
    });

    test('wait 2 getItem', () async {
      var pager = Pager<int>(provider: Provider(2));
      var item1 = pager.getItem(0);
      var item2 = pager.getItem(1);
      expect(await item1.future, 0);
      expect(await item2.future, 1);
    });

    test('cancel getItem', () async {
      var pager = Pager<int>(provider: Provider(2));
      var item = pager.getItem(0);
      expect(item.value, const TypeMatcher<Future>());

      // Needed to prevent crash
      unawaited(item.future.catchError((_) => null));
      item.cancel();
      try {
        expect(await item.value, isNull);
        fail('should fail');
      } on CancelException catch (_) {}
    });

    test('cancel 2 getItem', () async {
      var pager = Pager<int>(provider: Provider(2));
      var item1 = pager.getItem(0);
      var item2 = pager.getItem(1);

      // Needed to prevent crash
      unawaited(item1.future.catchError((_) => null));
      unawaited(item2.future.catchError((_) => null));
      item1.cancel();
      item2.cancel();
      try {
        expect(await item1.value, isNull);
        fail('should fail');
      } on CancelException catch (_) {}
      try {
        expect(await item2.value, isNull);
        fail('should fail');
      } on CancelException catch (_) {}
    });

    test('cancel 1/2 getItem', () async {
      var pager = Pager<int>(provider: Provider(2));
      var item1 = pager.getItem(0);
      var item2 = pager.getItem(1);

      // Needed to prevent crash
      unawaited(item1.future.catchError((_) => null));
      item1.cancel();
      try {
        expect(await item1.value, isNull);
        fail('should fail');
      } on CancelException catch (_) {}
      expect(await item2.value, 1);
    });
  });
}
