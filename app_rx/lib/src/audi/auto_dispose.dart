import 'package:tekartik_app_rx/auto_dispose.dart';

/// Auto dispose extension for rx
extension AutoDisposeRxExtension on AutoDispose {
  /// Add a BehaviorSubject to the auto dispose list
  BehaviorSubject<T> audiAddBehaviorSubject<T>(BehaviorSubject<T> subject) {
    return audiAdd(subject, subject.close);
  }
}
