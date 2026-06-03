import 'package:flutter/services.dart';
import 'package:flutter_auth_qrcode_2fa/data/qr_image_decoder.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_account.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channelName = 'com.example.flutter_auth_qrcode_2fa/qr_decode';
  const payload =
      'otpauth://totp/Rollbar:ricky.chang@rollbar.com?secret=JBSWY3DPEHPK3PXP&issuer=Rollbar';

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

  group('QrImageDecoder.decodeFromImagePath', () {
    late QrImageDecoder decoder;

    setUp(() {
      decoder = QrImageDecoder(
        analyzeImage: (_) async => null,
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel(channelName), (
        MethodCall call,
      ) async {
        if (call.method == 'decodeFromImagePath') {
          final path = call.arguments['path'] as String?;
          if (path == null || path.isEmpty) {
            throw PlatformException(
              code: 'INVALID_PATH',
              message: '無法讀取圖片：路徑為空',
            );
          }
          if (path.contains('no_qr')) {
            throw PlatformException(
              code: 'NOT_FOUND',
              message: '無法從圖片中辨識 QR 碼',
            );
          }
          return <String, Object>{
            'success': true,
            'payload': payload,
          };
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel(channelName), null);
    });

    test('returns trimmed payload from native channel mock', () async {
      final result = await decoder.decodeFromImagePath('/tmp/qrcodetest1.png');
      expect(result, payload);

      final account = OtpAccount.fromUri(result);
      expect(account.secret, isNotEmpty);
      expect(account.issuer, 'Rollbar');
    });

    test('maps NOT_FOUND PlatformException to QrImageDecodeException', () async {
      expect(
        () => decoder.decodeFromImagePath('/tmp/no_qr.png'),
        throwsA(
          isA<QrImageDecodeException>().having(
            (e) => e.message,
            'message',
            '無法從圖片中辨識 QR 碼',
          ),
        ),
      );
    });

    test('maps INVALID_PATH PlatformException to QrImageDecodeException', () async {
      expect(
        () => decoder.decodeFromImagePath(''),
        throwsA(
          isA<QrImageDecodeException>().having(
            (e) => e.message,
            'message',
            '無法讀取圖片：路徑為空',
          ),
        ),
      );
    });

    test('returns mobile_scanner payload without calling native', () async {
      final scannerDecoder = QrImageDecoder(
        analyzeImage: (_) async => BarcodeCapture(
          barcodes: [
            Barcode(
              rawValue: '  $payload  ',
              format: BarcodeFormat.qrCode,
            ),
          ],
        ),
      );

      var nativeCalled = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel(channelName), (
        MethodCall call,
      ) async {
        nativeCalled = true;
        return null;
      });

      final result = await scannerDecoder.decodeFromImagePath('/tmp/qrcodetest1.png');
      expect(result, payload);
      expect(nativeCalled, isFalse);
    });
  });
}
