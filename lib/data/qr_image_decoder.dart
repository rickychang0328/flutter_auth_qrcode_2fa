import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Gallery / static image QR decode via native ZXing (Android) or Vision (iOS).
class QrImageDecoder {
  QrImageDecoder({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = 'com.example.flutter_auth_qrcode_2fa/qr_decode';
  static const _methodDecodeFromImagePath = 'decodeFromImagePath';

  final MethodChannel _channel;

  /// Reads the first QR payload from an image file path (or `content://` on Android).
  Future<String> decodeFromImagePath(String path) async {
    if (kIsWeb) {
      throw const QrImageDecodeException('相簿辨識不支援 Web 平台');
    }

    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        _methodDecodeFromImagePath,
        <String, Object?>{'path': path},
      );
      final map = Map<String, dynamic>.from(result ?? {});
      final success = map['success'] == true;
      final payload = map['payload'] as String?;
      if (success && payload != null && payload.trim().isNotEmpty) {
        return payload.trim();
      }
      throw const QrImageDecodeException('無法從圖片中辨識 QR 碼');
    } on PlatformException catch (e) {
      throw QrImageDecodeException(_messageFromPlatformException(e));
    } on MissingPluginException {
      throw const QrImageDecodeException('相簿辨識僅支援 Android 與 iOS');
    }
  }

  static String _messageFromPlatformException(PlatformException e) {
    final message = e.message?.trim();
    if (message != null && message.isNotEmpty) {
      return message;
    }
    switch (e.code) {
      case 'NOT_FOUND':
        return '無法從圖片中辨識 QR 碼';
      case 'INVALID_PATH':
        return '無法讀取圖片';
      case 'UNSUPPORTED':
        return '此平台不支援相簿 QR 辨識';
      default:
        return 'QR 辨識失敗';
    }
  }
}

class QrImageDecodeException implements Exception {
  const QrImageDecodeException(this.message);
  final String message;

  @override
  String toString() => message;
}
