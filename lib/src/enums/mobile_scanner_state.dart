/// The authorization state of the scanner.
enum MobileScannerState {
  /// The scanner has not yet requested the required permissions.
  undetermined(0),

  /// The scanner has the required permissions.
  authorized(1),

  /// The user denied the required permissions.
  denied(2);

  const MobileScannerState(this.rawValue);

  factory MobileScannerState.fromRawValue(int value) {
    switch (value) {
      case 0:
        return MobileScannerState.undetermined;
      case 1:
        return MobileScannerState.authorized;
      case 2:
        return MobileScannerState.denied;
      default:
        throw ArgumentError.value(value, 'value', 'Invalid raw value.');
    }
  }

  /// The raw value for the state.
  final int rawValue;
}
