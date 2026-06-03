import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_auth_qrcode_2fa/domain/batch_qr_codec.dart';
import 'package:flutter_auth_qrcode_2fa/domain/group_model.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_account.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/providers.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ShareQrScreen extends ConsumerStatefulWidget {
  const ShareQrScreen({
    super.key,
    required this.accounts,
    required this.groups,
  });

  final List<OtpAccount> accounts;
  final List<GroupModel> groups;

  @override
  ConsumerState<ShareQrScreen> createState() => _ShareQrScreenState();
}

class _ShareQrScreenState extends ConsumerState<ShareQrScreen> {
  late final List<String> _qrStrings;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _qrStrings = BatchQrCodec.generateQrCodeStrings(
      widget.accounts,
      groups: widget.groups,
    );
    _recordHistory();
  }

  Future<void> _recordHistory() async {
    final repo = await ref.read(shareHistoryProvider.future);
    await repo.recordExport(widget.accounts);
  }

  @override
  Widget build(BuildContext context) {
    if (_qrStrings.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('無可匯出內容')),
      );
    }
    final payload = _qrStrings[_index];

    return Scaffold(
      appBar: AppBar(
        title: Text('匯出 QR (${_index + 1}/${_qrStrings.length})'),
        actions: [
          if (_qrStrings.length > 1)
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(() {
                _index = (_index + 1) % _qrStrings.length;
              }),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: QrImageView(
              data: payload,
              size: 260,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          SelectableText(
            payload,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
