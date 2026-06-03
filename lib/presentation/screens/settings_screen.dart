import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/providers.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/screens/pattern_setup_screen.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/version_check.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/widgets/backup_actions.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _securityOn = false;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final security = await ref.read(securityServiceProvider.future);
    setState(() {
      _securityOn = security.isSecurityEnabled;
      _version = kAppVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('啟用安全驗證 (指紋/背景鎖)'),
            subtitle: const Text('isSecurityValidation'),
            value: _securityOn,
            onChanged: (v) async {
              final security =
                  await ref.read(securityServiceProvider.future);
              await security.setSecurityEnabled(v);
              setState(() => _securityOn = v);
            },
          ),
          ListTile(
            leading: const Icon(Icons.gesture),
            title: const Text('設定手勢密碼'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const PatternSetupScreen(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.system_update),
            title: const Text('檢查版本更新'),
            subtitle: Text('目前版本 $_version'),
            onTap: () => checkAppVersion(context, ref),
          ),
          const Divider(),
          const ListTile(
            title: Text('備份與還原'),
            subtitle: Text('otp_accounts.json / .json.aes'),
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('匯出明文備份'),
            onTap: () => exportPlainBackup(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('匯出加密備份'),
            onTap: () => exportEncryptedBackup(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('匯入明文備份'),
            onTap: () => importPlainBackup(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.download_for_offline),
            title: const Text('匯入加密備份'),
            onTap: () => importEncryptedBackup(context, ref),
          ),
        ],
      ),
    );
  }
}
