import 'package:tekartik_common_utils/common_utils_import.dart';

class PagerData<T> {
  final lock = Lock();
  List<T>? items;

  /// Safe way to get data
  T? getItem(int index) =>
      (items != null && index < items!.length) ? items![index] : null;

  // The current indecies wanted
  // ignore: prefer_collection_literals
  final indecies = Set<int>();

  // To check before and after the lock
  bool get needFetch => indecies.isNotEmpty && items == null;

  @override
  String toString() => 'PagerData($indecies)';
}
