/// The state of the flashlight.
enum TorchState {
  /// The flashlight is off.
  off(0),

  /// The flashlight is on.
  on(1);

  const TorchState(this.rawValue);

  factory TorchState.fromRawValue(int value) {
    switch (value) {
      case 0:
        return TorchState.off;
      case 1:
        return TorchState.on;
      default:
        throw ArgumentError.value(value, 'value', 'Invalid raw value.');
    }
  }

  /// The raw value for the torch state.
  final int rawValue;
}
