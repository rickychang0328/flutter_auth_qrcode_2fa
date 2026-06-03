import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_auth_qrcode_2fa/domain/base32_util.dart';
import 'package:flutter_auth_qrcode_2fa/domain/hash_algorithm.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_generator.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_type.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_uri_parser.dart';
import 'package:flutter_auth_qrcode_2fa/domain/third_party_action.dart';

/// Domain account — mirrors Android `Entry` (OTP + URI fields).
class OtpAccount {
  OtpAccount({
    required this.type,
    required this.secret,
    required this.secretText,
    required this.issuer,
    required this.account,
    required this.label,
    this.period = OtpGenerator.totpDefaultPeriod,
    this.digits = OtpGenerator.totpDefaultDigits,
    this.algorithm = OtpGenerator.defaultAlgorithm,
    this.counter = 0,
    this.tags = const [],
    this.groupList = const [],
    this.lastUsed = 0,
    this.action = ThirdPartyAction.create,
    this.currentOtp,
    this.hideOtp = false,
    this.remainingTime = OtpGenerator.totpDefaultPeriod,
    this.isTop = false,
  });

  OtpType type;
  Uint8List secret;
  String secretText;
  String issuer;
  String account;
  String label;
  int period;
  int digits;
  HashAlgorithm algorithm;
  int counter;
  List<String> tags;
  List<String> groupList;
  int lastUsed;
  ThirdPartyAction action;
  String? currentOtp;
  bool hideOtp;
  int remainingTime;
  bool isTop;

  factory OtpAccount.fromUri(String contents) {
    final parsed = OtpUriParser.parse(contents);
    if (parsed.secret == null || parsed.secretText == null) {
      throw FormatException(OtpUriParser.invalidSecret);
    }
    return OtpAccount(
      type: parsed.type,
      secret: parsed.secret!,
      secretText: parsed.secretText!,
      issuer: parsed.issuer,
      account: parsed.account,
      label: parsed.label,
      period: parsed.period,
      digits: parsed.digits,
      algorithm: parsed.algorithm,
      counter: parsed.counter,
      tags: parsed.tags,
      groupList: parsed.groupList,
      action: parsed.action,
    )..recomputeOtp();
  }

  bool get isTimeBased => type == OtpType.totp || type == OtpType.steam;

  bool get isCounterBased => type == OtpType.hotp;

  String generateOtp({int? timeSeconds}) {
    switch (type) {
      case OtpType.totp:
        return OtpGenerator.totpRfc6238(
          secret,
          period,
          digits,
          algorithm,
          timeSeconds: timeSeconds,
        );
      case OtpType.hotp:
        return OtpGenerator.hotp(secret, counter, digits, algorithm);
      case OtpType.steam:
        return OtpGenerator.totpSteam(
          secret,
          period,
          digits,
          algorithm,
          timeSeconds: timeSeconds,
        );
    }
  }

  void recomputeOtp({int? timeSeconds}) {
    if (action == ThirdPartyAction.copy) return;
    currentOtp = generateOtp(timeSeconds: timeSeconds);
  }

  /// Android `Entry.toJSON()` field names.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'secret': secretText.isNotEmpty
          ? secretText
          : Base32Util.encode(secret, stripPadding: true),
      'issuer': issuer,
      'account': account,
      'label': label,
      'type': type.jsonName,
      'algorithm': algorithm.jsonName,
      'digits': digits,
      'tags': tags,
      'thumbnail': 'DEFAULT',
      'last_used': lastUsed,
      'currentOTP': currentOtp ?? '',
      'ishideotp': hideOtp,
      'remainingTime': remainingTime,
      'istag': isTop,
    };
    if (type == OtpType.totp || type == OtpType.steam) {
      json['period'] = period;
    } else if (type == OtpType.hotp) {
      json['counter'] = counter;
    }
    return json;
  }

  factory OtpAccount.fromJson(Map<String, dynamic> json) {
    final secretStr = (json['secret'] as String? ?? '').toUpperCase();
    final account = OtpAccount(
      type: OtpTypeExtension.fromJsonName(json['type'] as String? ?? 'TOTP'),
      secret: Base32Util.decode(secretStr),
      secretText: secretStr,
      issuer: json['issuer'] as String? ?? '',
      account: json['account'] as String? ?? '',
      label: json['label'] as String? ?? '',
      period: json['period'] as int? ?? OtpGenerator.totpDefaultPeriod,
      digits: json['digits'] as int? ?? OtpGenerator.totpDefaultDigits,
      algorithm: HashAlgorithmExtension.fromJsonName(
        json['algorithm'] as String?,
      ),
      counter: (json['counter'] as num?)?.toInt() ?? 0,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      lastUsed: (json['last_used'] as num?)?.toInt() ?? 0,
      currentOtp: json['currentOTP'] as String?,
      hideOtp: json['ishideotp'] as bool? ?? false,
      remainingTime:
          (json['remainingTime'] as num?)?.toInt() ??
          OtpGenerator.totpDefaultPeriod,
      isTop: json['istag'] as bool? ?? false,
    );
    account.recomputeOtp();
    return account;
  }

  static List<OtpAccount> listFromJsonString(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => OtpAccount.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String listToJsonString(List<OtpAccount> accounts) =>
      jsonEncode(accounts.map((a) => a.toJson()).toList());

  String displayTitle() {
    if (issuer.isNotEmpty && account.isNotEmpty) {
      return '$issuer ($account)';
    }
    if (issuer.isNotEmpty) return issuer;
    if (account.isNotEmpty) return account;
    return label;
  }

}
