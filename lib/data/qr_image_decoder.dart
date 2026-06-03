import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

typedef QrImageAnalyzeFn = Future<BarcodeCapture?> Function(String path);

/// Gallery / static image QR decode: [mobile_scanner] first, native ZXing/Vision fallback.
class QrImageDecoder {
  QrImageDecoder({
    MethodChannel? channel,
    MobileScannerController? scanner,
    QrImageAnalyzeFn? analyzeImage,
  })  : _channel = channel ?? const MethodChannel(_channelName),
        _scanner = scanner ?? (analyzeImage == null ? MobileScannerController() : null),
        _analyzeImage = analyzeImage;

  static const _channelName = 'com.example.flutter_auth_qrcode_2fa/qr_decode';
  static const _methodDecodeFromImagePath = 'decodeFromImagePath';

  final MethodChannel _channel;
  final MobileScannerController? _scanner;
  final QrImageAnalyzeFn? _analyzeImage;

  /// Reads the first QR payload from an image file path (or `content://` on Android).
  Future<String> decodeFromImagePath(String path) async {
    if (kIsWeb) {
      throw const QrImageDecodeException('相簿辨識不支援 Web 平台');
    }

    try {
      final capture = await _analyzeImageAtPath(path);
      final payload = extractFirstRawValue(capture);
      if (payload != null && payload.trim().isNotEmpty) {
        return payload.trim();
      }
    } catch (_) {
      // mobile_scanner unavailable or failed; try native below
    }

    return _decodeFromNative(path);
  }

  void dispose() => _scanner?.dispose();

  Future<BarcodeCapture?> _analyzeImageAtPath(String path) async {
    final analyze = _analyzeImage;
    if (analyze != null) {
      return analyze(path);
    }
    final scanner = _scanner;
    if (scanner == null) {
      return null;
    }
    return scanner.analyzeImage(path);
  }

  /// Pure helper for unit tests and shared scan/deep-link pipeline.
  static String? extractFirstRawValue(BarcodeCapture? capture) {
    if (capture == null) return null;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.trim().isNotEmpty) {
        return raw.trim();
      }
    }
    return null;
  }

  Future<String> _decodeFromNative(String path) async {
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
