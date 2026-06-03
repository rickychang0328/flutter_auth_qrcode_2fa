import 'dart:typed_data';

import 'package:flutter_auth_qrcode_2fa/domain/base32_util.dart';
import 'package:flutter_auth_qrcode_2fa/domain/hash_algorithm.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_generator.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_type.dart';
import 'package:flutter_auth_qrcode_2fa/domain/third_party_action.dart';

/// Parses `otpauth://` / `mustauth://` URIs — mirrors Android `Entry(String)`.
class OtpUriParser {
  static const String invalidProtocol = 'Invalid Protocol';
  static const String invalidHost = 'Invalid Host';
  static const String invalidIssuerAccount = 'Invalid issuer:account';
  static const String invalidIssuer = 'Invalid issuer';
  static const String invalidSecret = 'Invalid secret';

  /// Android `Entry.parseIssuerAccountFromLabel`.
  static ({String issuer, String account}) parseIssuerAccountFromLabel(
    String label,
  ) {
    var issuer = '';
    var account = label;
    final parts = label.split(':');
    var colonCount = 0;
    for (var i = 0; i < label.length; i++) {
      if (label[i] == ':') {
        colonCount++;
        if (colonCount >= 2) break;
      }
    }
    if (colonCount == 1 &&
        parts.length == 2 &&
        parts[0].isNotEmpty &&
        parts[1].isNotEmpty) {
      issuer = parts[0];
      account = parts[1];
    }
    return (issuer: issuer, account: account);
  }

  static ParsedOtpUri parse(String contents) {
    var filterContents = contents.trim();
    if (filterContents.contains('://')) {
      final splitScheme = filterContents.split('://');
      filterContents =
          '${splitScheme[0].toLowerCase()}://${splitScheme.sublist(1).join('://')}';
    }

    var working = filterContents
        .replaceFirst(RegExp('otpauth'), 'http')
        .replaceFirst(RegExp('mustauth'), 'http');

    if (_extractScheme(working) != 'http') {
      throw FormatException(invalidProtocol);
    }

    var host = _extractHost(working);
    OtpType type;
    if (host == 'totp') {
      type = OtpType.totp;
    } else if (host == 'hotp') {
      type = OtpType.hotp;
    } else {
      for (var i = 0; i < host.length; i++) {
        if (_isUpperCase(host[i])) {
          throw FormatException(invalidHost);
        }
      }
      type = OtpType.totp;
      working = working.replaceFirst(
        'http://',
        'http://${type.name}/',
      );
      host = _extractHost(working);
    }

    final rawLabel = _extractRawPathLabel(working);
    final rawQuery = _extractRawQuery(working);

    if (rawLabel.isNotEmpty) {
      final decodedLabel = Uri.decodeComponent(rawLabel);
      final encodedPath = _androidSelectiveEncodePath(decodedLabel);
      working = working.replaceFirst(rawLabel, encodedPath);
    }
    if (rawQuery.isNotEmpty) {
      final encodedQuery = _androidSelectiveEncodeQuery(rawQuery);
      working = working.replaceFirst(rawQuery, encodedQuery);
    }

    final uri = Uri.parse(working);
    final rawPathLabel =
        uri.path.startsWith('/') ? uri.path.substring(1) : '';
    final label = Uri.decodeComponent(rawPathLabel);
    if (label.isEmpty) {
      throw FormatException(invalidIssuerAccount);
    }

    var counter = -1;
    var period = -1;
    if (type == OtpType.hotp) {
      counter = int.parse(uri.queryParameters['counter'] ?? '0');
    } else if (type == OtpType.totp || type == OtpType.steam) {
      period = int.parse(
        uri.queryParameters['period'] ?? '${OtpGenerator.totpDefaultPeriod}',
      );
    }

    final labelParts = parseIssuerAccountFromLabel(label);
    var issuer = labelParts.issuer;
    var account = labelParts.account;

    final issuerParams = uri.queryParametersAll['issuer'] ?? [];
    if (issuerParams.length > 1) {
      throw FormatException(invalidIssuer);
    }

    final queryIssuer = uri.queryParameters['issuer'];
    final queryAccount = uri.queryParameters['account'];
    if (queryIssuer != null && queryIssuer.isNotEmpty) {
      issuer = Uri.decodeComponent(queryIssuer).trim();
    }
    if (queryAccount != null && queryAccount.isNotEmpty) {
      account = Uri.decodeComponent(queryAccount).trim();
    }

    final action = ThirdPartyActionExtension.fromQueryAction(
      uri.queryParameters['action'],
    );

    final querySecret = uri.queryParameters['secret'];
    String? secretText;
    if (querySecret != null) {
      secretText = querySecret.toUpperCase();
    } else if (action == ThirdPartyAction.create) {
      throw FormatException(invalidSecret);
    }

    if (secretText != null) {
      if (!Base32Util.isValidSecret(secretText)) {
        throw FormatException(invalidSecret);
      }
    }

    final digits = int.parse(
      uri.queryParameters['digits'] ?? '${OtpGenerator.totpDefaultDigits}',
    );

    final algorithm = HashAlgorithmExtension.fromJsonName(
      uri.queryParameters['algorithm']?.toUpperCase(),
    );

    final tags = uri.queryParametersAll['tags'] ?? [];
    final groupList = uri.queryParametersAll['group'] ?? [];

    Uint8List? secretBytes;
    if (secretText != null) {
      secretBytes = Base32Util.decode(secretText);
    }

    return ParsedOtpUri(
      type: type,
      secret: secretBytes,
      secretText: secretText,
      issuer: issuer,
      account: account,
      label: label,
      period: period >= 0 ? period : OtpGenerator.totpDefaultPeriod,
      counter: counter >= 0 ? counter : 0,
      digits: digits,
      algorithm: algorithm,
      tags: List<String>.from(tags),
      groupList: List<String>.from(groupList),
      action: action,
    );
  }

  static String _extractScheme(String uri) {
    final end = uri.indexOf('://');
    return end < 0 ? '' : uri.substring(0, end);
  }

  static String _extractHost(String uri) {
    final start = uri.indexOf('://');
    if (start < 0) return '';
    final pathStart = uri.indexOf('/', start + 3);
    if (pathStart < 0) {
      final q = uri.indexOf('?', start + 3);
      return q < 0
          ? uri.substring(start + 3)
          : uri.substring(start + 3, q);
    }
    return uri.substring(start + 3, pathStart);
  }

  static String _extractRawPathLabel(String uri) {
    final start = uri.indexOf('://');
    if (start < 0) return '';
    final pathStart = uri.indexOf('/', start + 3);
    if (pathStart < 0) return '';
    final pathEnd = uri.indexOf('?', pathStart);
    final path = pathEnd < 0
        ? uri.substring(pathStart + 1)
        : uri.substring(pathStart + 1, pathEnd);
    return path;
  }

  static String _extractRawQuery(String uri) {
    final q = uri.indexOf('?');
    if (q < 0) return '';
    return uri.substring(q + 1);
  }

  static String _androidSelectiveEncodePath(String path) {
    return Uri.encodeComponent(path).replaceAll('%3A', ':');
  }

  static String _androidSelectiveEncodeQuery(String query) {
    return Uri.encodeComponent(query)
        .replaceAll('%26', '&')
        .replaceAll('%3D', '=');
  }

  static bool _isUpperCase(String char) {
    final code = char.codeUnitAt(0);
    return code >= 0x41 && code <= 0x5a;
  }
}

class ParsedOtpUri {
  ParsedOtpUri({
    required this.type,
    required this.secret,
    required this.secretText,
    required this.issuer,
    required this.account,
    required this.label,
    required this.period,
    required this.counter,
    required this.digits,
    required this.algorithm,
    required this.tags,
    required this.groupList,
    required this.action,
  });

  final OtpType type;
  final Uint8List? secret;
  final String? secretText;
  final String issuer;
  final String account;
  final String label;
  final int period;
  final int counter;
  final int digits;
  final HashAlgorithm algorithm;
  final List<String> tags;
  final List<String> groupList;
  final ThirdPartyAction action;
}
