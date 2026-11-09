// ignore_for_file: avoid_print

import 'package:tekartik_app_emit/emit.dart';
import 'package:tekartik_app_pager/pager.dart';

/// A slow source read by offset/limit, as a database query or a REST api.
class RowProvider implements PagerDataProvider<String> {
  final int count;
  var getDataCount = 0;

  RowProvider(this.count);

  @override
  Future<int> getItemCount() async => count;

  @override
  Future<List<String>> getData(int offset, int limit) async {
    getDataCount++;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    var end = offset + limit < count ? offset + limit : count;
    return [for (var i = offset; i < end; i++) 'row_$i'];
  }
}

/// What a list row holds: its item, cancelled when the row goes away.
class Row {
  final int index;
  late final EmitFutureOrSubscription<String?> _subscription;

  Row(Pager<String> pager, this.index) {
    _subscription = pager
        .getItemFutureOr(index)
        .listen(
          (value) => print('row $index: $value'),
          onError: (Object error) {
            // A cancel is an EmitCancelException, a provider error is given
            // as is.
            if (error is! EmitCancelException) {
              print('row $index failed: $error');
            }
          },
        );
  }

  void dispose() => _subscription.cancel();
}

Future<void> main() async {
  var provider = RowProvider(95);
  var pager = Pager<String>(provider: provider, pageSize: 20);
  var count = await pager.getItemCount();
  print('$count rows');

  // Scrolled past rows 40 to 59 at once: their page is never fetched.
  var skipped = [for (var i = 40; i < 60; i++) Row(pager, i)];
  for (var row in skipped) {
    row.dispose();
  }

  // Rows 0 and 1 stay: one getData(0, 20) for both.
  var rows = [Row(pager, 0), Row(pager, 1)];
  await Future<void>.delayed(const Duration(milliseconds: 100));
  print('getData calls: ${provider.getDataCount}'); // 1

  // Cached now: the value itself, without a Future.
  print(pager.getItemFutureOr(2).toFutureOr()); // row_2

  // Past the end: null.
  print(await pager.getItemFutureOr(100).toFuture()); // null

  for (var row in rows) {
    row.dispose();
  }
}
