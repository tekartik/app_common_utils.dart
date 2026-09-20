---
name: tekartik-app-pager-paging
description: >-
  Use when lazily loading items by index from an offset/limit source (a list
  view, an infinite scroll, a paged query) with tekartik_app_pager: Pager,
  PagerDataProvider (getItemCount, getData(offset, limit)), getItemFutureOr
  returning an EmitFutureOr, pageSize / cachePageCount / poolSize,
  Pager.defaultPageSize, Pager.defaultCachePageCount, Pager.defaultPoolSize,
  and cancelling a pending item with an EmitFutureOrSubscription, from
  package:tekartik_app_pager/pager.dart.
---

# Paged access by item index (tekartik_app_pager)

`tekartik_app_pager` turns a source that can only be read by `offset`/`limit`
into a "give me item #N" API: it groups requests into pages, keeps the last
pages in an LRU cache, limits concurrent fetches with a pool, and - crucially
for fast scrolling - never fetches a page whose consumers all cancelled before
the fetch started.

## Guidelines

* Dependency (git, not on pub.dev - the package lives in the `app_pager/`
  directory of the repo). Add `tekartik_app_emit` too: `getItemFutureOr`
  returns an `EmitFutureOr` and that type is not re-exported:
  ```yaml
  dependencies:
    tekartik_app_pager:
      git:
        url: https://github.com/tekartik/app_common_utils.dart
        path: app_pager
      version: '>=0.1.0'
    tekartik_app_emit:
      git:
        url: https://github.com/tekartik/app_common_utils.dart
        path: app_emit
  ```
* Import `package:tekartik_app_pager/pager.dart` (it declares `Pager` and
  `PagerDataProvider`, nothing else) and `package:tekartik_app_emit/emit.dart`
  for `EmitFutureOr`, `EmitFutureOrSubscription` and `EmitCancelException`.
* Implement `PagerDataProvider<T>`: `Future<int> getItemCount()` and
  `Future<List<T>> getData(int offset, int limit)`. `getData` must honour
  both arguments and may return fewer than `limit` items at the end of the
  source (return an empty list past the end, never throw).
* Create one `Pager<T>(provider: myProvider, pageSize: ..., cachePageCount:
  ..., poolSize: ...)` per source/query. Defaults are
  `Pager.defaultPageSize` (50), `Pager.defaultCachePageCount` (4 pages kept in
  an LRU cache) and `Pager.defaultPoolSize` (4 concurrent `getData` calls).
  Make `pageSize` a small multiple of what a screen shows.
* `EmitFutureOr<T?> getItemFutureOr(int index)` is the only read API: it maps
  `index` to page `index ~/ pageSize` and calls
  `getData(page * pageSize, pageSize)` once for the whole page. When the page
  is already cached, the returned `EmitFutureOr` is already completed, so
  `toFutureOr()` gives the item synchronously - use that to render without a
  frame of placeholder.
* Always keep `index` inside `0 ..< getItemCount()`. The declared value type
  is `T?`, but the internal completer is typed `T`: for a non nullable `T`,
  an index past the end (the page returned fewer items) completes with `null`
  and throws an unhandled `TypeError` in the pool. Declare `Pager<T?>` /
  `PagerDataProvider<T?>` if out of range reads must return `null` instead.
* `pager.getItemCount()` just forwards to the provider on each call: it is not
  cached, so cache it yourself (typically once before building the list).
* Cancellation is the reason to use this package: `var subscription =
  pager.getItemFutureOr(i).listen((item) {...}, onError: (_) {});` and call
  `subscription.cancel()` when the row is disposed/scrolled away. If every
  index of a page cancels before the pool starts the fetch, `getData` is never
  called at all; a cancelled consumer sees an `EmitCancelException`, so always
  pass an `onError` (or catch it around `toFuture()`) to avoid an unhandled
  error.
* Read a pending item with `await emitFutureOr.toFuture()`, or branch on
  `toFutureOr()` (`is Future<T?>`) to stay synchronous when cached. See
  `tekartik-app-emit-future-or`
  for the full `EmitFutureOr` API.
* Only `cachePageCount` pages are kept: a page evicted from the LRU cache is
  re-fetched on the next access. There is no invalidation API - when the
  underlying data changes, drop the `Pager` and create a new one (together
  with a fresh `getItemCount()`).
* Pure Dart (VM, web, Flutter). `pager.toString()` prints a small `cv` model
  with the page size, useful in logs.
* Anti-patterns: one `Pager` per item or per rebuild; a provider that ignores
  `offset`/`limit` and returns everything; awaiting `getItemFutureOr` without
  ever cancelling while scrolling fast; assuming `getItemCount()` is cheap;
  expecting the page cache to grow with the list.

## Examples

### A provider over an offset/limit source

```dart
import 'dart:math';

import 'package:tekartik_app_pager/pager.dart';

/// Any source that reads by offset/limit (sql, sembast, a rest api...).
class MyProvider implements PagerDataProvider<String> {
  final int count;

  MyProvider(this.count);

  @override
  Future<int> getItemCount() async => count;

  @override
  Future<List<String>> getData(int offset, int limit) async {
    // Never return more than limit items, and clamp at the end.
    var remaining = count - offset;
    if (remaining <= 0) {
      return <String>[];
    }
    var actualLimit = min(limit, remaining);
    return List<String>.generate(actualLimit, (i) => 'item_${offset + i}');
  }
}

Future<void> main() async {
  var pager = Pager<String>(provider: MyProvider(1000), pageSize: 20);
  print(await pager.getItemCount()); // 1000

  // One getData(0, 20) call serves both.
  print(await pager.getItemFutureOr(0).toFuture()); // item_0
  print(await pager.getItemFutureOr(5).toFuture()); // item_5

  // Second page: getData(20, 20).
  print(await pager.getItemFutureOr(25).toFuture()); // item_25

  // Never ask for an index >= getItemCount() with a non nullable item type.
}
```

### Synchronous read when the page is cached

```dart
import 'package:tekartik_app_pager/pager.dart';

class NumberProvider implements PagerDataProvider<int> {
  @override
  Future<int> getItemCount() async => 100;

  @override
  Future<List<int>> getData(int offset, int limit) async =>
      List<int>.generate(limit, (i) => offset + i);
}

/// Returns the item without awaiting when its page is already loaded.
Future<String> renderItem(Pager<int> pager, int index) async {
  var futureOr = pager.getItemFutureOr(index).toFutureOr();
  if (futureOr is Future<int?>) {
    return 'loading, then ${await futureOr}';
  }
  return 'cached $futureOr';
}

Future<void> main() async {
  var pager = Pager<int>(
    provider: NumberProvider(),
    pageSize: 10,
    cachePageCount: 2,
    poolSize: 2,
  );
  print(await renderItem(pager, 3)); // loading, then 3
  print(await renderItem(pager, 4)); // cached 4 (same page)
  print(pager); // {pageSize: 10}
}
```

### Cancel items that scrolled away before they are fetched

```dart
import 'package:tekartik_app_emit/emit.dart';
import 'package:tekartik_app_pager/pager.dart';

class SlowProvider implements PagerDataProvider<String> {
  var getDataCount = 0;

  @override
  Future<int> getItemCount() async => 500;

  @override
  Future<List<String>> getData(int offset, int limit) async {
    getDataCount++;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return List<String>.generate(limit, (i) => 'row_${offset + i}');
  }
}

/// What a list item widget/controller would hold.
class RowController {
  final EmitFutureOrSubscription<String?> subscription;

  RowController(Pager<String> pager, int index)
    : subscription = pager.getItemFutureOr(index).listen(
        (value) => print('row $index: $value'),
        // Mandatory: a cancelled row completes with EmitCancelException.
        onError: (Object error) {
          if (error is! EmitCancelException) {
            print('row $index failed: $error');
          }
        },
      );

  void dispose() => subscription.cancel();
}

Future<void> main() async {
  var provider = SlowProvider();
  var pager = Pager<String>(provider: provider, pageSize: 50);

  // The user scrolled past these rows immediately.
  var rows = [for (var i = 0; i < 10; i++) RowController(pager, i)];
  for (var row in rows) {
    row.dispose();
  }
  await Future<void>.delayed(const Duration(milliseconds: 100));
  print(provider.getDataCount); // 0: the page was never fetched

  // A row that stays alive does fetch.
  var kept = RowController(pager, 0);
  await Future<void>.delayed(const Duration(milliseconds: 100));
  print(provider.getDataCount); // 1
  kept.dispose();
}
```
