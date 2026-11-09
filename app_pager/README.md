# tekartik_app_pager

Read items by index from a source that can only be read by offset/limit (a
SQL query, a sembast finder, a REST api...). The pager fetches whole pages,
keeps the last ones in an LRU cache, limits the concurrent fetches, and skips
the fetch of a page whose readers all cancelled before it started (fast
scrolling in a list).

## Getting started

Not on pub.dev, add it as a git dependency (Dart SDK `^3.12.0`), with
`tekartik_app_emit` for the `EmitFutureOr` returned by the pager:

```yaml
dependencies:
  tekartik_app_pager:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_pager
  tekartik_app_emit:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_emit
```

```dart
import 'package:tekartik_app_pager/pager.dart';

/// Items `item_0` to `item_<count - 1>`.
class ItemProvider implements PagerDataProvider<String> {
  final int count;

  ItemProvider(this.count);

  @override
  Future<int> getItemCount() async => count;

  @override
  Future<List<String>> getData(int offset, int limit) async {
    var end = offset + limit < count ? offset + limit : count;
    return [for (var i = offset; i < end; i++) 'item_$i'];
  }
}

Future<void> main() async {
  var pager = Pager<String>(provider: ItemProvider(1000), pageSize: 20);
  // One getData(0, 20) for both.
  print(await pager.getItemFutureOr(0).toFuture()); // item_0
  // Cached: the value itself, no Future.
  print(pager.getItemFutureOr(5).toFutureOr()); // item_5
}
```

Pure Dart: Dart VM, Flutter (mobile, desktop, web), browser. See
[example/main.dart](example/main.dart).

## What to use

* `PagerDataProvider<T>`: implement `getItemCount()` and
  `getData(offset, limit)` (fewer items, or none, past the end).
* `Pager<T>(provider: ..., pageSize: 50, cachePageCount: 4, poolSize: 4)`:
  one per source or query.
* `pager.getItemFutureOr(index)`: an `EmitFutureOr<T?>`; `toFutureOr()` is
  the item itself when its page is cached, `toFuture()` always a `Future`,
  `listen(onValue, onError: ...)` returns a subscription whose `cancel()`
  gives up the item (no fetch if every reader of the page cancelled
  first).
* `pager.getItemCount()`: calls the provider each time (not cached).

## Common pitfalls

* An index past the end gives `null` (since 2026-11-09: for a non nullable
  `T` on a page not cached yet, it was an uncaught `TypeError` and an item
  that never completed).
* A `getData` error completes the items waiting for that page with that
  error, and the page is fetched again on the next access (since 2026-11-09:
  it was uncaught and the items never completed). Pass an `onError` to
  `listen`, or catch around `await ...toFuture()`.
* A cancelled item completes with an `EmitCancelException`: `toFuture()`
  throws it, a `listen` without `onError` ignores it.
* There is no invalidation: when the source changes, create a new `Pager`.
* Keep `index >= 0`: a negative index reads the end of page 0.

## Agent skills

[skills/tekartik-app-pager-paging](skills/tekartik-app-pager-paging/SKILL.md).
