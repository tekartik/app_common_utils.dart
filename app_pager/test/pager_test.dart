import 'dart:async';
import 'dart:math';

import 'package:tekartik_app_emit/emit.dart';
import 'package:tekartik_app_pager/pager.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:test/test.dart';

bool debug = false;

class Action {
  final String text;

  Action(this.text);
}

class Provider implements PagerDataProvider<int> {
  final int count;

  final List<Action> actions = [];

  Provider([this.count = 1]);

  @override
  Future<List<int>> getData(int offset, int limit) async {
    actions.add(Action('getData($offset, $limit)'));
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
    actions.add(Action('getItemCount()'));
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
      var provider = Provider(2);
      var pager = Pager<int>(provider: provider);
      var item1 = pager.getItemFutureOr(0);
      var item2 = pager.getItemFutureOr(1);

      // onError needed to prevent unit test failure
      var subscription1 = item1.listen(null, onError: (_) => null);
      var subscription2 = item2.listen(null, onError: (_) => null);
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
      expect(provider.actions.map((action) => action.text), []);
    });

    test('cancel 1/2 getItem', () async {
      var provider = Provider(2);
      var pager = Pager<int>(provider: provider);
      var item1 = pager.getItemFutureOr(0);
      var item2 = pager.getItemFutureOr(1);

// onError needed to prevent unit test failure
      var subscription1 = item1.listen(null, onError: (_) => null);
      subscription1.cancel();
      expect(provider.actions.map((action) => action.text), []);
      try {
        expect(await item1.toFuture(), isNull);
        fail('should fail');
      } on EmitCancelException catch (_) {}
      expect(provider.actions.map((action) => action.text), ['getData(0, 50)']);
      expect(await item2.toFuture(), 1);
    });
  });
}
