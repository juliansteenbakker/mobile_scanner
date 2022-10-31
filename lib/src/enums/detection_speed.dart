/// The detection speed of the scanner.
enum DetectionSpeed {
  /// The scanner will only scan a barcode once, and never again until another
  /// barcode has been scanned.
  noDuplicates,

  /// Front facing camera.
  normal,

  /// Back facing camera.
  unrestricted,
}
