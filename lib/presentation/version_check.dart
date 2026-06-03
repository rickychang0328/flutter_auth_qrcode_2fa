import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/providers.dart';
import 'package:url_launcher/url_launcher.dart';

const String kAppVersion = '1.0.0';

Future<void> checkAppVersion(BuildContext context, WidgetRef ref) async {
  final api = ref.read(versionApiProvider);
  try {
    final response = await api.checkVersion(
      platform: 'flutter',
      version: kAppVersion,
      mid: 'flutter-device',
      brand: 'flutter',
      model: 'demo',
      osVersion: 'unknown',
    );
    if (response.domain.isNotEmpty) {
      api.updateBaseUrl(response.domain.first, 18443);
    }
    if (!context.mounted) return;
    final info = response.versionInfo;
    if (info == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('API 回應：${response.info}')),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('版本 ${info.version}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final note in info.notes) Text('• $note'),
              if (info.notes.isEmpty) const Text('有新版本資訊'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('稍後'),
          ),
          if (info.url.isNotEmpty)
            FilledButton(
              onPressed: () async {
                final uri = Uri.parse(info.url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('前往更新'),
            ),
        ],
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('版本檢查失敗：$e')),
      );
    }
  }
}
