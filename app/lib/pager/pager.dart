import 'dart:async';

import 'package:meta/meta.dart';
import 'package:pedantic/pedantic.dart';
import 'package:pool/pool.dart';
import 'package:quiver/collection.dart';
import 'package:tekartik_common_utils/completer/completer.dart';
import 'package:tekartik_common_utils/model/model.dart';

/// Provider to implement.
abstract class PagerDataProvider<T> {
  /// Get the total number of items
  Future<int> getItemCount();

  /// Get a page of result.
  Future<List<T>> getData(int offset, int limit);
}

class _PagerData<T> {
  List<T> items;

  // The current indecies wanted
  final indecies = Set<int>();

  @override
  String toString() => 'Data($indecies)';
}

class _ItemCancellableCompleter<T> with CancellableCompleterMixin<T> {
  final _PagerData data;
  final int index;
  _ItemCancellableCompleter(this.data, this.index) {
    completer = Completer<T>.sync();
  }

  @override
  void cancel({String reason}) {
    // Remove the pending indecies
    // if empty we won't need to fetch again
    data.indecies.remove(index);
    super.cancel(reason: reason);

  }

  @override
  Model toDebugModel() {
    var model = super.toDebugModel();
    model['index'] = index;
    return model;
  }

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
  final LruMap<int, _PagerData<T>> _pageCache;

  Pager(
      {@required PagerDataProvider<T> provider,
      int pageSize,
      int cachePageCount,
      int poolSize})
      : _provider = provider,
        _pageSize = pageSize ?? defaultPageSize,
        _pageCache = LruMap<int, _PagerData<T>>(
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

  /// If you don't want the item any more, you can call cancel
  CancellableCompleter<T> getItem(int index) {
    var page = _getItemIndexPage(index);
    var data = _pageCache[page];
    var inPageIndex = _getItemIndexInPageIndex(index);
    if (data?.items == null) {
      if (data == null) {
        data = _PagerData<T>();
        _pageCache[page] = data;
      }
      data.indecies.add(inPageIndex);
      // can be cancelled leter
      final completer = _ItemCancellableCompleter<T>(data, inPageIndex);
      unawaited(_pool.withResource(() async {
          // Don't fetch if not needed
          if (data.indecies.isNotEmpty) {
            data.items = await _provider.getData(
                _getPageProviderOffset(page), _pageSize);
            // Complete if needed too
            if (!completer.isCompleted) {
              completer.complete(data.items[inPageIndex]);
            }
          }
        }));

      return completer;
    } else {
      return CancellableCompleter<T>(
          sync: true, value: data.items[inPageIndex]);
    }
  }

  @override
  String toString() {
    var model = Model();
    model['pageSize'] = _pageSize;
    return model.toString();
  }

}
