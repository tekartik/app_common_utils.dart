import 'package:tekartik_app_pager/pager.dart';
import 'package:test/test.dart';

/// Items 0..count-1, fails when [error] is set.
class _Provider implements PagerDataProvider<int> {
  final int count;
  StateError? error;
  var getDataCount = 0;

  _Provider(this.count);

  @override
  Future<int> getItemCount() async => count;

  @override
  Future<List<int>> getData(int offset, int limit) async {
    getDataCount++;
    var error = this.error;
    if (error != null) {
      throw error;
    }
    var end = offset + limit > count ? count : offset + limit;
    return [for (var i = offset; i < end; i++) i];
  }
}

void main() {
  // Each item future is bounded: the old code never completed them.
  const itemTimeout = Duration(seconds: 5);
  group('pager', () {
    test('index past the end, non nullable item type', () async {
      var pager = Pager<int>(provider: _Provider(3), pageSize: 10);
      // Not cached yet: used to complete a Completer<int> with null, a
      // TypeError uncaught in the pool and an item never completed.
      expect(
        await pager.getItemFutureOr(5).toFuture().timeout(itemTimeout),
        isNull,
      );
      // Cached: null too.
      expect(pager.getItemFutureOr(6).toFutureOr(), isNull);
      expect(await pager.getItemFutureOr(2).toFuture(), 2);
    }, timeout: const Timeout(Duration(seconds: 10)));

    test('getData error', () async {
      var provider = _Provider(3)..error = StateError('getData failed');
      var pager = Pager<int>(provider: provider, pageSize: 10);
      // Used to be an uncaught error and an item never completed.
      await expectLater(
        pager.getItemFutureOr(0).toFuture().timeout(itemTimeout),
        throwsStateError,
      );
      var errors = <Object>[];
      pager.getItemFutureOr(1).listen((_) {}, onError: errors.add);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(errors, [isStateError]);

      // The page is fetched again on the next access.
      provider.error = null;
      expect(await pager.getItemFutureOr(1).toFuture().timeout(itemTimeout), 1);
      expect(provider.getDataCount, 3);
    }, timeout: const Timeout(Duration(seconds: 10)));
  });
}
