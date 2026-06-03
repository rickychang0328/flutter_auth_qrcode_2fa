enum OtpType { totp, hotp, steam }

extension OtpTypeExtension on OtpType {
  String get jsonName => name.toUpperCase();

  static OtpType fromJsonName(String value) {
    return OtpType.values.firstWhere(
      (e) => e.jsonName == value.toUpperCase(),
      orElse: () => OtpType.totp,
    );
  }
}
