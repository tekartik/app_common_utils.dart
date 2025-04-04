import 'dart:async';

import 'package:tekartik_app_common_utils/auto_dispose.dart';
import 'package:tekartik_app_common_utils/src/audi/auto_dispose.dart'
    show AutoDisposeMixinPrvExtension;
import 'package:test/test.dart';

class _TestDisposable {
  var disposed = false;
  void dispose() {
    disposed = true;
  }
}

class _TestAutoDisposable implements AutoDisposable {
  var disposed = false;
  @override
  void selfDispose() {
    disposed = true;
  }
}

/// Test mixin
class _TestAutoDisposerableMain extends AutoDisposerableBase {
  late final sub = audiAddDisposable(_TestAutoDisposerableSub());
}

class _TestAutoDisposerableSub extends AutoDisposerableBase {}

class _AutoDisposer with AutoDisposeMixin {}

void main() {
  group('audi', () {
    test('object disposable', () {
      var disposer = _AutoDisposer();
      var disposable = _TestDisposable();
      var user = disposer.audiAdd(disposable, disposable.dispose);
      expect(disposable.disposed, false);
      expect(user.disposed, false);
      expect(disposer.length, 1);
      disposer.audiDisposeAll();
      expect(disposable.disposed, true);
      expect(user.disposed, true);
      expect(disposer.length, 0);
    });
    test('object auto disposable', () {
      var disposer = _AutoDisposer();
      var disposable = _TestAutoDisposable();
      var user = disposer.audiAddDisposable(disposable);
      expect(disposable.disposed, false);
      expect(user.disposed, false);
      expect(disposer.length, 1);
      disposer.audiDisposeAll();
      expect(disposable.disposed, true);
      expect(user.disposed, true);
      expect(disposer.length, 0);
    });
    test('function', () {
      var doFail = false;
      var disposed = false;
      void dispose() {
        if (doFail) {
          fail('failed');
        } else {
          disposed = true;
        }
      }

      var disposer = _AutoDisposer();
      disposer.audiAddFunction(dispose);
      disposer.audiDisposeFunction(dispose);
      expect(disposed, true);
      doFail = true;
      disposer.audiDisposeFunction(dispose);
    });

    test('add', () {
      var disposer = _AutoDisposer();

      var disposable = _TestDisposable();
      var disposable2 = _TestDisposable();
      var disposable3 = _TestDisposable();
      expect(disposer.length, 0);
      disposer.audiAdd(disposable, disposable.dispose);
      disposer.audiAddFunction(disposable2.dispose);
      disposer.audiAddSelf(disposable3, (object) => object.dispose());
      expect(disposer.length, 3);
      expect(disposable.disposed, false);
      disposer.audiDispose(disposable);
      expect(disposer.length, 2);
      expect(disposable.disposed, true);
      expect(disposable2.disposed, false);
      expect(disposable3.disposed, false);
      disposer.audiDisposeAll();
      expect(disposable2.disposed, true);
      expect(disposable3.disposed, true);
      expect(disposer.length, 0);
    });
    test('subscription', () async {
      var disposer = _AutoDisposer();
      var controller = StreamController<bool>(sync: true);
      var received = false;
      // ignore: cancel_subscriptions
      var subscription = disposer.audiAddStreamSubscription(
        controller.stream.listen((_) {
          received = true;
        }),
      );
      controller.add(true);
      expect(received, true);
      received = false;
      disposer.audiDispose(subscription);
      controller.add(true);
      expect(received, false);
    });
    test('controller', () async {
      var disposer = _AutoDisposer();
      var controller = StreamController<bool>(sync: true);
      disposer.audiAddStreamController(controller);
      expect(controller.isClosed, isFalse);
      disposer.audiDispose(controller);
      expect(controller.isClosed, isTrue);
    });
    test('disposerable', () async {
      var disposer = _TestAutoDisposerableMain();
      var disposable = _TestAutoDisposable();
      disposer.sub.audiAddDisposable(disposable);
      expect(disposable.disposed, false);
      disposer.selfDispose();
      expect(disposable.disposed, true);
    });
  });
}
