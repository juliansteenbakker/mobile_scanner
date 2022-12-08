import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

Size toSize(Map data) {
  final width = data['width'] as double;
  final height = data['height'] as double;
  return Size(width, height);
}

List<Offset>? toCorners(List? data) {
  if (data != null) {
    return List.unmodifiable(
      data.map((e) => Offset((e as Map)['x'] as double, e['y'] as double)),
    );
  } else {
    return null;
  }
}

BarcodeFormat toFormat(int value) {
  switch (value) {
    case 0:
      return BarcodeFormat.all;
    case 1:
      return BarcodeFormat.code128;
    case 2:
      return BarcodeFormat.code39;
    case 4:
      return BarcodeFormat.code93;
    case 8:
      return BarcodeFormat.codebar;
    case 16:
      return BarcodeFormat.dataMatrix;
    case 32:
      return BarcodeFormat.ean13;
    case 64:
      return BarcodeFormat.ean8;
    case 128:
      return BarcodeFormat.itf;
    case 256:
      return BarcodeFormat.qrCode;
    case 512:
      return BarcodeFormat.upcA;
    case 1024:
      return BarcodeFormat.upcE;
    case 2048:
      return BarcodeFormat.pdf417;
    case 4096:
      return BarcodeFormat.aztec;
    default:
      return BarcodeFormat.unknown;
  }
}

CalendarEvent? toCalendarEvent(Map? data) {
  if (data != null) {
    return CalendarEvent.fromNative(data);
  } else {
    return null;
  }
}

DateTime? toDateTime(Map<String, dynamic>? data) {
  if (data != null) {
    final year = data['year'] as int;
    final month = data['month'] as int;
    final day = data['day'] as int;
    final hour = data['hours'] as int;
    final minute = data['minutes'] as int;
    final second = data['seconds'] as int;
    return data['isUtc'] as bool
        ? DateTime.utc(year, month, day, hour, minute, second)
        : DateTime(year, month, day, hour, minute, second);
  } else {
    return null;
  }
}

ContactInfo? toContactInfo(Map? data) {
  if (data != null) {
    return ContactInfo.fromNative(data);
  } else {
    return null;
  }
}

PersonName? toName(Map? data) {
  if (data != null) {
    return PersonName.fromNative(data);
  } else {
    return null;
  }
}

DriverLicense? toDriverLicense(Map? data) {
  if (data != null) {
    return DriverLicense.fromNative(data);
  } else {
    return null;
  }
}

Email? toEmail(Map? data) {
  if (data != null) {
    return Email.fromNative(data);
  } else {
    return null;
  }
}

GeoPoint? toGeoPoint(Map? data) {
  if (data != null) {
    return GeoPoint.fromNative(data);
  } else {
    return null;
  }
}

Phone? toPhone(Map? data) {
  if (data != null) {
    return Phone.fromNative(data);
  } else {
    return null;
  }
}

SMS? toSMS(Map? data) {
  if (data != null) {
    return SMS.fromNative(data);
  } else {
    return null;
  }
}

UrlBookmark? toUrl(Map? data) {
  if (data != null) {
    return UrlBookmark.fromNative(data);
  } else {
    return null;
  }
}

WiFi? toWiFi(Map? data) {
  if (data != null) {
    return WiFi.fromNative(data);
  } else {
    return null;
  }
}

Size applyBoxFit(BoxFit fit, Size input, Size output) {
  if (input.height <= 0.0 ||
      input.width <= 0.0 ||
      output.height <= 0.0 ||
      output.width <= 0.0) {
    return Size.zero;
  }

  Size destination;

  final inputAspectRatio = input.width / input.height;
  final outputAspectRatio = output.width / output.height;

  switch (fit) {
    case BoxFit.fill:
      destination = output;
      break;
    case BoxFit.contain:
      if (outputAspectRatio > inputAspectRatio) {
        destination = Size(
          input.width * output.height / input.height,
          output.height,
        );
      } else {
        destination = Size(
          output.width,
          input.height * output.width / input.width,
        );
      }
      break;

    case BoxFit.cover:
      if (outputAspectRatio > inputAspectRatio) {
        destination = Size(
          output.width,
          input.height * (output.width / input.width),
        );
      } else {
        destination = Size(
          input.width * (output.height / input.height),
          output.height,
        );
      }
      break;
    case BoxFit.fitWidth:
      destination = Size(
        output.width,
        input.height * (output.width / input.width),
      );
      break;
    case BoxFit.fitHeight:
      destination = Size(
        input.width * (output.height / input.height),
        output.height,
      );
      break;
    case BoxFit.none:
      destination = Size(
        math.min(input.width, output.width),
        math.min(input.height, output.height),
      );
      break;
    case BoxFit.scaleDown:
      destination = input;
      if (destination.height > output.height) {
        destination = Size(output.height * inputAspectRatio, output.height);
      }
      if (destination.width > output.width) {
        destination = Size(output.width, output.width / inputAspectRatio);
      }
      break;
  }

  return destination;
}
