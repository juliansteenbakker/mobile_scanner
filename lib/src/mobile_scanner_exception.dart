class MobileScannerException implements Exception {
  String message;
  MobileScannerException(this.message);

  @override
  String toString() {
    return "MobileScannerException: $message";
  }
}
