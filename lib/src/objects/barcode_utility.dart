import 'package:flutter/material.dart';

import 'barcode.dart';

Size toSize(Map<dynamic, dynamic> data) {
  final width = data['width'];
  final height = data['height'];
  return Size(width, height);
}

List<Offset>? toCorners(List<dynamic>? data) {
  if (data != null) {
    return List.unmodifiable(data.map((e) => Offset(e['x'], e['y'])));
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

CalendarEvent? toCalendarEvent(Map<dynamic, dynamic>? data) {
  if (data != null) {
    return CalendarEvent.fromNative(data);
  } else {
    return null;
  }
}

DateTime? toDateTime(Map<dynamic, dynamic>? data) {
  if (data != null) {
    final year = data['year'];
    final month = data['month'];
    final day = data['day'];
    final hour = data['hours'];
    final minute = data['minutes'];
    final second = data['seconds'];
    return data['isUtc']
        ? DateTime.utc(year, month, day, hour, minute, second)
        : DateTime(year, month, day, hour, minute, second);
  } else {
    return null;
  }
}

ContactInfo? toContactInfo(Map<dynamic, dynamic>? data) {
  if (data != null) {
    return ContactInfo.fromNative(data);
  } else {
    return null;
  }
}

PersonName? toName(Map<dynamic, dynamic>? data) {
  if (data != null) {
    return PersonName.fromNative(data);
  } else {
    return null;
  }
}

DriverLicense? toDriverLicense(Map<dynamic, dynamic>? data) {
  if (data != null) {
    return DriverLicense.fromNative(data);
  } else {
    return null;
  }
}

Email? toEmail(Map<dynamic, dynamic>? data) {
  if (data != null) {
    return Email.fromNative(data);
  } else {
    return null;
  }
}

GeoPoint? toGeoPoint(Map<dynamic, dynamic>? data) {
  if (data != null) {
    return GeoPoint.fromNative(data);
  } else {
    return null;
  }
}

Phone? toPhone(Map<dynamic, dynamic>? data) {
  if (data != null) {
    return Phone.fromNative(data);
  } else {
    return null;
  }
}

SMS? toSMS(Map<dynamic, dynamic>? data) {
  if (data != null) {
    return SMS.fromNative(data);
  } else {
    return null;
  }
}

UrlBookmark? toUrl(Map<dynamic, dynamic>? data) {
  if (data != null) {
    return UrlBookmark.fromNative(data);
  } else {
    return null;
  }
}

WiFi? toWiFi(Map<dynamic, dynamic>? data) {
  if (data != null) {
    return WiFi.fromNative(data);
  } else {
    return null;
  }
}
