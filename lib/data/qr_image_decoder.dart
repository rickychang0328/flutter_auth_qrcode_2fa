import 'package:mobile_scanner/mobile_scanner.dart';

/// Gallery QR decode — mirrors `LoadingPictureActivity` + ZXing flow.
class QrImageDecoder {
  QrImageDecoder({MobileScannerController? controller})
      : _controller = controller ?? MobileScannerController();

  final MobileScannerController _controller;

  /// Reads the first QR/barcode payload from an image file path.
  Future<String> decodeFromImagePath(String path) async {
    final capture = await _controller.analyzeImage(path);
    final value = extractFirstRawValue(capture);
    if (value == null || value.isEmpty) {
      throw const QrImageDecodeException('無法從圖片中辨識 QR 碼');
    }
    return value;
  }

  void dispose() => _controller.dispose();

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
}

class QrImageDecodeException implements Exception {
  const QrImageDecodeException(this.message);
  final String message;

  @override
  String toString() => message;
}
