import 'package:tekartik_common_utils/common_utils_import.dart';

class PagerData<T> {
  final lock = Lock();
  List<T> items;

  // The current indecies wanted
  final indecies = Set<int>();

  // To check before and after the lock
  bool get needFetch => indecies.isNotEmpty && items == null;

  @override
  String toString() => 'PagerData($indecies)';
}
