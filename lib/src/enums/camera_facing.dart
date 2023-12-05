/// The facing of a camera.
enum CameraFacing {
  /// Front facing camera.
  front(0),

  /// Back facing camera.
  back(1);

  const CameraFacing(this.rawValue);

  factory CameraFacing.fromRawValue(int value) {
    switch (value) {
      case 0:
        return CameraFacing.front;
      case 1:
        return CameraFacing.back;
      default:
        throw ArgumentError.value(value, 'value', 'Invalid raw value.');
    }
  }

  /// The raw value for the camera facing direction.
  final int rawValue;
}
