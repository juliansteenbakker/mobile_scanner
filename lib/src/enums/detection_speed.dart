/// The detection speed of the scanner.
enum DetectionSpeed {
  /// The scanner will only scan a barcode once, and never again until another
  /// barcode has been scanned.
  ///
  /// NOTE: This mode does analyze every frame in order to check if the value
  /// has changed.
  noDuplicates,

  /// The barcode scanner will scan one barcode, and wait 250 Miliseconds before
  /// scanning again. This will prevent memory issues on older devices.
  ///
  /// You can change the timeout duration with [detectionTimeout] parameter.
  normal,

  /// Let the scanner detect barcodes without restriction.
  ///
  /// NOTE: This can cause memory issues with older devices.
  unrestricted,
}
