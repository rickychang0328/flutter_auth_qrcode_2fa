import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/providers.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  bool _handled = false;
  final _manualController = TextEditingController();

  Future<void> _onCode(String code) async {
    if (_handled || code.isEmpty) return;
    _handled = true;
    final handler = ref.read(deepLinkHandlerProvider);
    await handler.handleUri(context, code.trim());
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('掃描 QR')),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              onDetect: (capture) {
                final barcodes = capture.barcodes;
                for (final b in barcodes) {
                  final raw = b.rawValue;
                  if (raw != null) {
                    _onCode(raw);
                    break;
                  }
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manualController,
                    decoration: const InputDecoration(
                      hintText: '或貼上 otpauth:// / mustauth:// URI',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () => _onCode(_manualController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
