import 'dart:async';

import 'package:cv/cv.dart';
import 'package:pool/pool.dart';
import 'package:quiver/collection.dart';
import 'package:tekartik_app_emit/emit.dart';
import 'package:tekartik_app_pager/src/data.dart';

/// The source of a [Pager], read by offset/limit.
abstract class PagerDataProvider<T> {
  /// Get the total number of items (called by [Pager.getItemCount] each
  /// time).
  Future<int> getItemCount();

  /// Get at most [limit] items from [offset], fewer (or none) past the end.
  ///
  /// An error completes the items waiting for this page with it.
  Future<List<T>> getData(int offset, int limit);
}

/// Reads items by index from a [PagerDataProvider], a page at a time.
///
/// Pages are kept in an LRU cache of `cachePageCount` pages, at most
/// `poolSize` [PagerDataProvider.getData] run at once, and a page whose
/// readers all cancelled before its fetch started is not fetched.
class Pager<T> {
  /// Default number of items per page.
  static const int defaultPageSize = 50;

  /// Default number of pages kept in the cache.
  static const int defaultCachePageCount = 4;

  /// Default number of concurrent [PagerDataProvider.getData] calls.
  static const int defaultPoolSize = 4;

  final Pool _pool;
  final int _pageSize;
  final PagerDataProvider<T> _provider;

  /// key is the page
  final LruMap<int, PagerData<T>> _pageCache;

  Pager({
    required this._provider,
    int? pageSize,
    int? cachePageCount,
    int? poolSize,
  }) : _pageSize = pageSize ?? defaultPageSize,
       _pageCache = LruMap<int, PagerData<T>>(
         maximumSize: cachePageCount ?? defaultCachePageCount,
       ),
       _pool = Pool(poolSize ?? defaultPoolSize);

  /// Get the page from a given item index
  int _getItemIndexPage(int index) {
    return index ~/ _pageSize;
  }

  /// Get the index in the page from a given item index
  int _getItemIndexInPageIndex(int index) {
    return index % _pageSize;
  }

  /// Get the offset to use for a given page
  int _getPageProviderOffset(int page) {
    return page * _pageSize;
  }

  /// The item count of the provider (not cached).
  Future<int> getItemCount() {
    return _provider.getItemCount();
  }

  /// The item at [index] (`>= 0`), null past the end.
  ///
  /// Already completed when its page is cached (`toFutureOr()` is then the
  /// item itself). Cancel the subscription of `listen` when the item is no
  /// longer needed: a page whose readers all cancelled before its fetch is
  /// not fetched. A [PagerDataProvider.getData] error completes the item
  /// with that error.
  EmitFutureOr<T?> getItemFutureOr(int index) {
    var page = _getItemIndexPage(index);
    var data = _pageCache[page];
    var inPageIndex = _getItemIndexInPageIndex(index);
    if (data?.items == null) {
      if (data == null) {
        data = PagerData<T>();
        _pageCache[page] = data;
      }
      data.indecies.add(inPageIndex);
      // can be cancelled later. Typed T? as the returned value: an index past
      // the end of the page completes with null.
      final controller = EmitFutureOrController<T?>();

      bool needFetch() {
        return !(controller.isCompleted) && (data!.needFetch);
      }

      unawaited(
        _pool.withResource(() async {
          try {
            // Don't fetch if not needed
            if (needFetch()) {
              await data!.lock.synchronized(() async {
                if (needFetch()) {
                  data!.items = await _provider.getData(
                    _getPageProviderOffset(page),
                    _pageSize,
                  );
                  // Complete if needed too
                }
              });
            }
            if (!controller.isCompleted && data!.items != null) {
              controller.complete(data.getItem(inPageIndex));
            }
          } catch (e, st) {
            // A provider error goes to the item (the page is fetched again
            // on the next access).
            if (!controller.isCompleted) {
              controller.completeError(e, st);
            }
          }
        }),
      );

      return controller.futureOr;
    } else {
      return EmitFutureOr<T?>.withValue(data!.getItem(inPageIndex));
    }
  }

  @override
  String toString() {
    var model = newModel();
    model['pageSize'] = _pageSize;
    return model.toString();
  }
}
