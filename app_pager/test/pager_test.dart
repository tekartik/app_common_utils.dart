import 'dart:async';
import 'dart:math';

import 'package:pedantic/pedantic.dart';
import 'package:tekartik_app_emit/emit.dart';
import 'package:tekartik_app_pager/pager.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:test/test.dart';

bool debug = false;

class Provider implements PagerDataProvider<int> {
  final int count;

  Provider([this.count = 1]);

  @override
  Future<List<int>> getData(int offset, int limit) async {
    if (debug) {
      print('getting offset $offset limit $limit');
    }
    int remainings = count - offset;
    if (remainings < 0) {
      limit = 0;
    } else {
      limit = min(limit, remainings);
    }
    return List<int>.generate(limit, (index) => offset + index);
  }

  @override
  Future<int> getItemCount() async {
    if (debug) {
      print('getting count $count');
    }
    return count;
  }
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
      var item = pager.getItemFutureOr(0).toFutureOr();
      expect(item, const TypeMatcher<Future>());
      expect(await item, 0);
    });

    test('wait getItem', () async {
      var pager = Pager<int>(provider: Provider(2));
      var item = pager.getItemFutureOr(0);
      expect(item.toFuture(), const TypeMatcher<Future>());
      expect(await item.toFuture(), 0);
      expect(item.toFutureOr(), 0);
    });

    test('wait 2 getItem', () async {
      var pager = Pager<int>(provider: Provider(2));
      var item1 = pager.getItemFutureOr(0);
      var item2 = pager.getItemFutureOr(1);
      expect(await item1.toFuture(), 0);
      expect(await item2.toFuture(), 1);
    });

    test('cancel getItem', () async {
      var pager = Pager<int>(provider: Provider(2));
      var item = pager.getItemFutureOr(0);

      expect(item.toFuture(), const TypeMatcher<Future>());

      // onError needed to prevent unit test failure
      var subscription = item.listen(null, onError: (_) => null);

      subscription.cancel();
      try {
        expect(await item.toFuture(), isNull);
        fail('should fail');
      } on EmitCancelException catch (_) {}
    });

    test('cancel 2 getItem', () async {
      var pager = Pager<int>(provider: Provider(2));
      var item1 = pager.getItemFutureOr(0);
      var item2 = pager.getItemFutureOr(1);

      // Needed to prevent crash
      unawaited(item1.toFuture().catchError((_) => null));
      unawaited(item2.toFuture().catchError((_) => null));

      // onError needed to prevent unit test failure
      var subscription1 = item1.listen(null, onError: (_) => null);
      var subscription2 = item1.listen(null, onError: (_) => null);
      subscription1.cancel();
      subscription2.cancel();
      var future1 = () async {
        try {
          await subscription1.asFutureOr();
          fail('should fail');
        } on EmitCancelException catch (_) {}
      }();
      var future2 = () async {
        try {
          await subscription2.asFutureOr();
          fail('should fail');
        } on EmitCancelException catch (_) {}
      }();
      await Future.wait([future1, future2]);
    });

    test('cancel 1/2 getItem', () async {
      var pager = Pager<int>(provider: Provider(2));
      var item1 = pager.getItemFutureOr(0);
      var item2 = pager.getItemFutureOr(1);

// onError needed to prevent unit test failure
      var subscription1 = item1.listen(null, onError: (_) => null);
      subscription1.cancel();
      try {
        expect(await item1.toFuture(), isNull);
        fail('should fail');
      } on EmitCancelException catch (_) {}
      expect(await item2.toFuture(), 1);
    });
  });
}
