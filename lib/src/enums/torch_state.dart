/// The state of the flashlight.
enum TorchState {
  /// The flashlight is off.
  off(0),

  /// The flashlight is on.
  on(1);

  const TorchState(this.rawValue);

  /// The raw value for the torch state.
  final int rawValue;
}
