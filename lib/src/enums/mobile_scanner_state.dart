/// The authorization state of the scanner.
enum MobileScannerState {
  /// The scanner has not yet requested the required permissions.
  undetermined,

  /// The scanner has the required permissions.
  authorized,

  /// The user denied the required permissions.
  denied
}
