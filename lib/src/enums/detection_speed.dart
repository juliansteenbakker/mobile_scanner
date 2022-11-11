/// The detection speed of the scanner.
enum DetectionSpeed {
  /// The scanner will only scan a barcode once, and never again until another
  /// barcode has been scanned.
  noDuplicates,

  /// The barcode scanner will wait
  normal,

  /// Back facing camera.
  unrestricted,
}
