import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_auth_qrcode_2fa/data/qr_image_decoder.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/providers.dart';
import 'package:image_picker/image_picker.dart';

/// Pick a gallery image, decode QR, and run the deep-link import pipeline.
/// Returns `true` when a payload was imported successfully.
Future<bool> pickAndImportQrFromGallery(
  BuildContext context,
  WidgetRef ref,
) async {
  if (kIsWeb) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('相簿辨識不支援 Web 平台')),
    );
    return false;
  }

  final decoder = QrImageDecoder();
  try {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null || !context.mounted) return false;
    final payload = await decoder.decodeFromImagePath(image.path);
    if (!context.mounted) return false;
    await ref.read(deepLinkHandlerProvider).handleUri(context, payload);
    return true;
  } on QrImageDecodeException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
    return false;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('讀取圖片失敗：$e')),
      );
    }
    return false;
  } finally {
    decoder.dispose();
  }
}
