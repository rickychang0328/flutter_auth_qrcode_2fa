import 'package:flutter_auth_qrcode_2fa/data/qr_image_decoder.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QrImageDecoder.extractFirstRawValue', () {
    test('returns first non-empty rawValue', () {
      final capture = BarcodeCapture(
        barcodes: [
          Barcode(
            rawValue: '  otpauth://totp/Test?secret=JBSWY3DPEHPK3PXP  ',
            format: BarcodeFormat.qrCode,
          ),
          Barcode(
            rawValue: 'second',
            format: BarcodeFormat.qrCode,
          ),
        ],
      );
      expect(
        QrImageDecoder.extractFirstRawValue(capture),
        'otpauth://totp/Test?secret=JBSWY3DPEHPK3PXP',
      );
    });

    test('returns null when empty', () {
      expect(QrImageDecoder.extractFirstRawValue(null), isNull);
      expect(
        QrImageDecoder.extractFirstRawValue(
          BarcodeCapture(barcodes: []),
        ),
        isNull,
      );
    });
  });
}
