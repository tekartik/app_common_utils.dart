import 'dart:async';

import 'package:pedantic/pedantic.dart';
import 'package:pool/pool.dart';
import 'package:quiver/collection.dart';
import 'package:tekartik_app_emit/emit.dart';
import 'package:tekartik_app_pager/src/data.dart';
import 'package:tekartik_common_utils/model/model.dart';

/// Provider to implement.
abstract class PagerDataProvider<T> {
  /// Get the total number of items
  Future<int> getItemCount();

  /// Get a page of result.
  Future<List<T>> getData(int offset, int limit);
}

/// A pager helps on getting/caching items by page
class Pager<T> {
  static const int defaultPageSize = 50;
  static const int defaultCachePageCount = 4;
  static const int defaultPoolSize = 4;

  final Pool _pool;
  final int _pageSize;
  final PagerDataProvider<T> _provider;

  /// key is the page
  final LruMap<int, PagerData<T>> _pageCache;

  Pager(
      {required PagerDataProvider<T> provider,
      int? pageSize,
      int? cachePageCount,
      int? poolSize})
      : _provider = provider,
        _pageSize = pageSize ?? defaultPageSize,
        _pageCache = LruMap<int, PagerData<T>>(
            maximumSize: cachePageCount ?? defaultCachePageCount),
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

  /// Use the provider
  Future<int> getItemCount() {
    return _provider.getItemCount();
  }

  /// If you don't want the item any more, you can call cancel
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
      // can be cancelled later
      final controller = EmitFutureOrController<T>();

      bool needFetch() {
        return !(controller.isCompleted) && (data!.needFetch);
      }

      unawaited(_pool.withResource(() async {
        // Don't fetch if not needed
        if (needFetch()) {
          await data!.lock.synchronized(() async {
            if (needFetch()) {
              data!.items = await _provider.getData(
                  _getPageProviderOffset(page), _pageSize);
              // Complete if needed too

            }
          });
        }
        if (!controller.isCompleted && data!.items != null) {
          controller.complete(data.getItem(inPageIndex));
        }
      }));

      return controller.futureOr;
    } else {
      return EmitFutureOr<T?>.withValue(data!.getItem(inPageIndex));
    }
  }

  @override
  String toString() {
    var model = Model();
    model['pageSize'] = _pageSize;
    return model.toString();
  }
}
