/// Auto dispose class
abstract class AutoDisposable {
  /// Dispose function
  void selfDispose();
}

/// no op Auto dispose interface
mixin AutoDisposableMixin implements AutoDisposable {
  /// Dispose function
  @override
  void selfDispose() {}
}
