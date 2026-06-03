enum HashAlgorithm { sha1, sha256, sha512 }

extension HashAlgorithmExtension on HashAlgorithm {
  String get jsonName => name.toUpperCase();

  String get hmacName => 'Hmac$jsonName';

  static HashAlgorithm fromJsonName(String? value) {
    if (value == null || value.isEmpty) return HashAlgorithm.sha1;
    return HashAlgorithm.values.firstWhere(
      (e) => e.jsonName == value.toUpperCase(),
      orElse: () => HashAlgorithm.sha1,
    );
  }
}
