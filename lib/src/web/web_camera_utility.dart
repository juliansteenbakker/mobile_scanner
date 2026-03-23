import 'dart:js_interop';
import 'dart:ui';

import 'package:mobile_scanner/src/objects/barcode.dart';
import 'package:mobile_scanner/src/web/media_track_extension.dart';
import 'package:web/web.dart' as web;

/// Returns true if the video stream should be mirrored horizontally.
///
/// Mirrors when facingMode is 'user' (front camera on mobile), or when
/// facingMode is null (desktop cameras mainly face the user).
bool shouldMirrorStream(web.MediaStream? videoStream) {
  final tracks = videoStream?.getVideoTracks().toDart;

  if (tracks == null || tracks.isEmpty) {
    return false;
  }

  final facingMode = tracks.first.getSettings().facingModeNullable?.toDart;

  return facingMode == 'user' || facingMode == null;
}

/// Apply a horizontal CSS mirror transform to [videoElement] if the camera
/// is facing the user.
void maybeFlipVideoPreview(
  web.HTMLVideoElement videoElement,
  web.MediaStream videoStream,
) {
  if (shouldMirrorStream(videoStream)) {
    videoElement.style.transform = 'scaleX(-1)';
  }
}

/// Returns a copy of [barcode] with all corner x-coordinates mirrored
/// relative to [videoWidth].
Barcode mirrorBarcodeX(Barcode barcode, double videoWidth) {
  final corners = barcode.corners;

  if (corners.isEmpty) {
    return barcode;
  }

  // Mirror each x-coordinate.
  final mirrored = corners.map((c) => Offset(videoWidth - c.dx, c.dy)).toList();

  // Mirroring x reverses the clockwise winding order from
  // [TL, TR, BR, BL] to [TR_m, TL_m, BL_m, BR_m].
  // Swap TL↔TR and BL↔BR to restore [TL_m, TR_m, BR_m, BL_m].
  final reordered =
      mirrored.length == 4
          ? [mirrored[1], mirrored[0], mirrored[3], mirrored[2]]
          : mirrored;

  return Barcode(
    corners: reordered,
    format: barcode.format,
    displayValue: barcode.displayValue,
    // Populate deprecated rawBytes for backward compatibility.
    // ignore: deprecated_member_use_from_same_package
    rawBytes: barcode.rawBytes,
    rawDecodedBytes: barcode.rawDecodedBytes,
    rawValue: barcode.rawValue,
    size: barcode.size,
    type: barcode.type,
  );
}
