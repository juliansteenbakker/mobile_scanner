/// The facing of a camera.
enum CameraFacing {
  /// Front facing camera.
  front(0),

  /// Back facing camera.
  back(1);

  const CameraFacing(this.rawValue);

  /// The raw value for the camera facing direction.
  final int rawValue;
}
