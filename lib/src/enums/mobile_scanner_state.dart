/// The authorization state of the scanner.
enum MobileScannerState {
  /// The scanner has yet to request weather it is [authorized] or [denied]
  undetermined,

  /// The scanner has the required permissions.
  authorized,

  /// The user denied the required permissions.
  denied
}
