import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_auth_qrcode_2fa/data/aes_gcm_cipher.dart';

/// PBKDF2 + AES-GCM backup format — mirrors Android `BackupHelper` / §6.2.
///
/// File layout: `[4 bytes iterations BE][12 bytes salt][IV||ciphertext||mac]`
class BackupCrypto {
  static const int headerLength = 4 + AesGcmCipher.ivLength;
  static const int minIterations = 1000;
  static const int maxIterations = 5000;
  static const int pbkdf2Bits = 256;
  static const int aesKeyBytes = 16;
  static final AesGcm _aes256 = AesGcm.with256bits();

  static int randomIterations() {
    final rnd = Random.secure();
    return minIterations +
        rnd.nextInt(maxIterations - minIterations + 1);
  }

  static Future<Uint8List> deriveAesKeyBytes(
    String password,
    List<int> salt,
    int iterations, {
    bool useFullPbkdf2Output = false,
  }) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha1(),
      iterations: iterations,
      bits: pbkdf2Bits,
    );
    final derived = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    final bytes = await derived.extractBytes();
    if (useFullPbkdf2Output) return Uint8List.fromList(bytes);
    return Uint8List.fromList(bytes.sublist(0, aesKeyBytes));
  }

  static Future<Uint8List> encryptJson(String json, String password) async {
    final iter = randomIterations();
    final salt = Uint8List.fromList(
      List<int>.generate(AesGcmCipher.ivLength, (_) => Random.secure().nextInt(256)),
    );
    final keyBytes = await deriveAesKeyBytes(password, salt, iter);
    final key = await AesGcmCipher.keyFromBytes(keyBytes);
    final encrypted = await AesGcmCipher.encrypt(
      key,
      Uint8List.fromList(utf8.encode(json)),
    );
    final header = ByteData(4);
    header.setUint32(0, iter, Endian.big);
    final out = Uint8List(headerLength + encrypted.length);
    out.setRange(0, 4, header.buffer.asUint8List(0, 4));
    out.setRange(4, headerLength, salt);
    out.setRange(headerLength, out.length, encrypted);
    return out;
  }

  static Future<String> decryptToJson(
    Uint8List fileBytes,
    String password,
  ) async {
    if (fileBytes.length <= headerLength + AesGcmCipher.ivLength + AesGcmCipher.macLength) {
      throw const FormatException('備份檔案格式不正確');
    }
    final header = ByteData.sublistView(fileBytes, 0, 4);
    final iter = header.getUint32(0, Endian.big);
    if (iter < minIterations || iter > maxIterations) {
      throw FormatException('備份迭代次數無效：$iter');
    }
    final salt = fileBytes.sublist(4, headerLength);
    final payload = Uint8List.fromList(fileBytes.sublist(headerLength));

    Object? lastError;
    for (final useFull in [false, true]) {
      try {
        final keyBytes = await deriveAesKeyBytes(
          password,
          salt,
          iter,
          useFullPbkdf2Output: useFull,
        );
        final plain = useFull
            ? await _decryptAes256(keyBytes, payload)
            : await AesGcmCipher.decrypt(
                await AesGcmCipher.keyFromBytes(keyBytes),
                payload,
              );
        return utf8.decode(plain);
      } catch (e) {
        lastError = e;
      }
    }
    throw FormatException('備份解密失敗，請確認密碼是否正確', lastError);
  }

  static Future<Uint8List> _decryptAes256(
    Uint8List keyBytes,
    Uint8List combined,
  ) async {
    if (keyBytes.length != 32) {
      throw ArgumentError('AES-256 key must be 32 bytes');
    }
    if (combined.length <= AesGcmCipher.ivLength + AesGcmCipher.macLength) {
      throw const FormatException('Invalid ciphertext');
    }
    final nonce = combined.sublist(0, AesGcmCipher.ivLength);
    final cipherText = combined.sublist(
      AesGcmCipher.ivLength,
      combined.length - AesGcmCipher.macLength,
    );
    final mac = Mac(combined.sublist(combined.length - AesGcmCipher.macLength));
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);
    return Uint8List.fromList(
      await _aes256.decrypt(secretBox, secretKey: SecretKey(keyBytes)),
    );
  }

  /// Fixed-vector encrypt for tests (`iter` + `salt` supplied).
  static Future<Uint8List> encryptJsonWithParams({
    required String json,
    required String password,
    required int iterations,
    required Uint8List salt,
  }) async {
    final keyBytes = await deriveAesKeyBytes(password, salt, iterations);
    final key = await AesGcmCipher.keyFromBytes(keyBytes);
    final encrypted = await AesGcmCipher.encrypt(
      key,
      Uint8List.fromList(utf8.encode(json)),
    );
    final header = ByteData(4);
    header.setUint32(0, iterations, Endian.big);
    final out = Uint8List(headerLength + encrypted.length);
    out.setRange(0, 4, header.buffer.asUint8List(0, 4));
    out.setRange(4, headerLength, salt);
    out.setRange(headerLength, out.length, encrypted);
    return out;
  }
}
