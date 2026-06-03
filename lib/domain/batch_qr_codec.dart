import 'package:flutter_auth_qrcode_2fa/domain/base32_util.dart';
import 'package:flutter_auth_qrcode_2fa/domain/group_model.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_account.dart';

/// Batch QR export/import — mirrors `ExportAccSelectActivityViewModel` + scanner.
class BatchQrCodec {
  static const int maxAccountsPerQr = 8;
  static const String mainScheme = 'mustauth';
  static const String mainHost = 'mulitpleshare';
  static const String mainPath = 'mulitpleshare';
  static const String mainAction = 'mulitpleshare';
  static const String multipleUrlKey = 'mulitpleURL';

  /// Android `genQRCodeStr`.
  static List<String> generateQrCodeStrings(
    List<OtpAccount> exportList, {
    List<GroupModel>? groups,
  }) {
    if (exportList.isEmpty) return [];

    final codeStrList = <String>[];
    var tempStr = '';

    for (var i = 0; i < exportList.length; i++) {
      final entry = exportList[i];

      var tempGroupStr = '';
      if (groups != null) {
        for (final group in groups) {
          if (group.codeLastIdList.contains(entry.lastUsed)) {
            tempGroupStr += '&group=${group.text}';
          }
        }
      }

      if ((i + 1) % maxAccountsPerQr == 1) {
        tempStr =
            '$mainScheme://$mainHost/$mainPath?action=$mainAction';
      }
      tempStr += '&$multipleUrlKey=';

      final multipleUrlStr = _buildSingleExportUri(entry) + tempGroupStr;
      tempStr += Uri.encodeComponent(multipleUrlStr);

      if ((i + 1) % maxAccountsPerQr == 0 && i != 0) {
        codeStrList.add(tempStr);
      }
    }

    if (exportList.length % maxAccountsPerQr != 0) {
      codeStrList.add(tempStr);
    }

    return codeStrList;
  }

  /// Android `SimpleScannerActivity` batch branch.
  static bool isBatchSharePayload(String content) =>
      content.contains(multipleUrlKey);

  static List<OtpAccount> parseBatchShare(String content) {
    final uri = Uri.parse(content);
    final encodedUrls = uri.queryParametersAll[multipleUrlKey] ?? [];
    return encodedUrls
        .map((encoded) => OtpAccount.fromUri(Uri.decodeComponent(encoded)))
        .toList();
  }

  static String _buildSingleExportUri(OtpAccount entry) {
    var accountForPath = entry.account;
    if (accountForPath.isNotEmpty) {
      var letterCount = 0;
      for (final letter in accountForPath.runes) {
        if (String.fromCharCode(letter) == ':') letterCount++;
      }
      if (letterCount == 1) {
        accountForPath = '$accountForPath:';
      }
    }

    final queryParts = <String>[];
    queryParts.add(
      'secret=${Base32Util.encode(entry.secret, stripPadding: true)}',
    );
    queryParts.add('algorithm=${entry.algorithm.name.toUpperCase()}');
    queryParts.add('digits=${entry.digits}');
    queryParts.add('period=${entry.period}');
    queryParts.add('counter=${entry.counter}');
    queryParts.add('action=set');
    if (entry.issuer.isNotEmpty) {
      queryParts.add('issuer=${Uri.encodeComponent(entry.issuer)}');
    }

    final labelStr = Uri.encodeComponent(accountForPath);
    final queryString = '?${queryParts.join('&')}';
    final typeHost = entry.type.name;
    return '$mainScheme://$typeHost/$labelStr$queryString';
  }
}
