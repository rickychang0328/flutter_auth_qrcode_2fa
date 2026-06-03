import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// AES-GCM — mirrors Android `EncryptionHelper` (IV 12 bytes prepended).
class AesGcmCipher {
  static const int ivLength = 12;
  static final AesGcm _algorithm = AesGcm.with128bits();

  static Future<SecretKey> generateKey() async {
    final key = await _algorithm.newSecretKey();
    return key;
  }

  static const int macLength = 16;

  static Future<Uint8List> encrypt(SecretKey key, Uint8List plaintext) async {
    final secretBox = await _algorithm.encrypt(
      plaintext,
      secretKey: key,
    );
    final nonce = secretBox.nonce;
    final macBytes = secretBox.mac.bytes;
    final combined = Uint8List(
      nonce.length + secretBox.cipherText.length + macBytes.length,
    );
    var offset = 0;
    combined.setRange(offset, offset + nonce.length, nonce);
    offset += nonce.length;
    combined.setRange(
      offset,
      offset + secretBox.cipherText.length,
      secretBox.cipherText,
    );
    offset += secretBox.cipherText.length;
    combined.setRange(offset, combined.length, macBytes);
    return combined;
  }

  static Future<Uint8List> decrypt(SecretKey key, Uint8List combined) async {
    if (combined.length <= ivLength + macLength) {
      throw FormatException('Invalid ciphertext');
    }
    final nonce = combined.sublist(0, ivLength);
    final cipherText = combined.sublist(
      ivLength,
      combined.length - macLength,
    );
    final mac = Mac(combined.sublist(combined.length - macLength));
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);
    return Uint8List.fromList(
      await _algorithm.decrypt(secretBox, secretKey: key),
    );
  }

  static Future<SecretKey> keyFromBytes(List<int> bytes) async {
    final data = Uint8List.fromList(bytes);
    if (data.length != 16) {
      throw ArgumentError('AES key must be 16 bytes');
    }
    return SecretKey(data);
  }

  static List<int> randomKeyBytes() {
    final rnd = Random.secure();
    return List<int>.generate(16, (_) => rnd.nextInt(256));
  }
}
