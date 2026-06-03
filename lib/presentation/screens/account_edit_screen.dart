import 'package:flutter/material.dart';
import 'package:flutter_auth_qrcode_2fa/domain/base32_util.dart';
import 'package:flutter_auth_qrcode_2fa/domain/hash_algorithm.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_account.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_generator.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_type.dart';

class AccountEditScreen extends StatefulWidget {
  const AccountEditScreen({super.key, this.existing});

  final OtpAccount? existing;

  @override
  State<AccountEditScreen> createState() => _AccountEditScreenState();
}

class _AccountEditScreenState extends State<AccountEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _issuer;
  late final TextEditingController _account;
  late final TextEditingController _secret;
  late OtpType _type;
  late HashAlgorithm _algorithm;
  late int _digits;
  late int _period;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _issuer = TextEditingController(text: e?.issuer ?? '');
    _account = TextEditingController(text: e?.account ?? '');
    _secret = TextEditingController(text: e?.secretText ?? '');
    _type = e?.type ?? OtpType.totp;
    _algorithm = e?.algorithm ?? OtpGenerator.defaultAlgorithm;
    _digits = e?.digits ?? OtpGenerator.totpDefaultDigits;
    _period = e?.period ?? OtpGenerator.totpDefaultPeriod;
  }

  @override
  void dispose() {
    _issuer.dispose();
    _account.dispose();
    _secret.dispose();
    super.dispose();
  }

  OtpAccount? _buildAccount() {
    if (!_formKey.currentState!.validate()) return null;
    final secretText = _secret.text.trim().toUpperCase();
    if (!Base32Util.isValidSecret(secretText)) return null;
    final secret = Base32Util.decode(secretText);
    final label = _account.text.contains(':')
        ? _account.text
        : (_issuer.text.isNotEmpty
            ? '${_issuer.text}:${_account.text}'
            : _account.text);
    if (widget.existing != null) {
      final e = widget.existing!;
      e.issuer = _issuer.text.trim();
      e.account = _account.text.trim();
      e.secret = secret;
      e.secretText = secretText;
      e.label = label;
      e.type = _type;
      e.algorithm = _algorithm;
      e.digits = _digits;
      e.period = _period;
      e.recomputeOtp();
      return e;
    }
    return OtpAccount(
      type: _type,
      secret: secret,
      secretText: secretText,
      issuer: _issuer.text.trim(),
      account: _account.text.trim(),
      label: label,
      period: _period,
      digits: _digits,
      algorithm: _algorithm,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? '新增帳戶' : '編輯帳戶'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              final acc = _buildAccount();
              if (acc != null) Navigator.pop(context, acc);
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _issuer,
              decoration: const InputDecoration(labelText: '發行者 (issuer)'),
            ),
            TextFormField(
              controller: _account,
              decoration: const InputDecoration(labelText: '帳戶名稱'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? '請輸入帳戶名稱' : null,
            ),
            TextFormField(
              controller: _secret,
              decoration: const InputDecoration(labelText: '密鑰 (Base32)'),
              validator: (v) {
                if (v == null || !Base32Util.isValidSecret(v.trim())) {
                  return '無效的 Base32 密鑰';
                }
                return null;
              },
            ),
            DropdownButtonFormField<OtpType>(
              value: _type,
              decoration: const InputDecoration(labelText: '類型'),
              items: OtpType.values
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.jsonName),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? OtpType.totp),
            ),
            DropdownButtonFormField<HashAlgorithm>(
              value: _algorithm,
              decoration: const InputDecoration(labelText: '演算法'),
              items: HashAlgorithm.values
                  .map(
                    (a) => DropdownMenuItem(
                      value: a,
                      child: Text(a.jsonName),
                    ),
                  )
                  .toList(),
              onChanged: (v) =>
                  setState(() => _algorithm = v ?? HashAlgorithm.sha1),
            ),
            TextFormField(
              initialValue: '$_digits',
              decoration: const InputDecoration(labelText: '位數'),
              keyboardType: TextInputType.number,
              onChanged: (v) => _digits = int.tryParse(v) ?? _digits,
            ),
            if (_type != OtpType.hotp)
              TextFormField(
                initialValue: '$_period',
                decoration: const InputDecoration(labelText: '週期 (秒)'),
                keyboardType: TextInputType.number,
                onChanged: (v) => _period = int.tryParse(v) ?? _period,
              ),
          ],
        ),
      ),
    );
  }
}
