/// Address type constants.
enum AddressType {
  /// Unknown address type.
  unknown(0),

  /// Work address.
  work(1),

  /// Home address.
  home(2);

  const AddressType(this.rawValue);

  factory AddressType.fromRawValue(int value) {
    switch (value) {
      case 1:
        return AddressType.work;
      case 2:
        return AddressType.home;
      case 0:
      default:
        return AddressType.unknown;
    }
  }

  /// The raw address type value.
  final int rawValue;
}
