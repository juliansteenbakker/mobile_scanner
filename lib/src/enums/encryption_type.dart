/// Wifi encryption type constants.
enum EncryptionType {
  /// Unknown encryption type.
  none(0),

  /// Not encrypted.
  open(1),

  /// WPA level encryption.
  wpa(2),

  /// WEP level encryption.
  wep(3);

  const EncryptionType(this.rawValue);

  factory EncryptionType.fromRawValue(int value) {
    switch (value) {
      case 0:
        return EncryptionType.none;
      case 1:
        return EncryptionType.open;
      case 2:
        return EncryptionType.wpa;
      case 3:
        return EncryptionType.wep;
      default:
        throw ArgumentError.value(value, 'value', 'Invalid raw value.');
    }
  }

  /// The raw value for the encryption type.
  final int rawValue;
}
