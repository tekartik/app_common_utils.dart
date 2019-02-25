/// Cancel exception thrown when cancelling a completer or controller
class EmitCancelException implements Exception {
  final String reason;

  EmitCancelException(this.reason);

  @override
  String toString() {
    String result = "Emit cancelled";
    if (reason != null) {
      result = "$result due to: $reason";
    }
    return result;
  }
}
