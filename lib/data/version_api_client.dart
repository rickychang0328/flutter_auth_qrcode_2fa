import 'package:dio/dio.dart';

class VersionInfo {
  VersionInfo({
    required this.notes,
    required this.platform,
    required this.url,
    required this.version,
  });

  final List<String> notes;
  final String platform;
  final String url;
  final String version;

  factory VersionInfo.fromJson(Map<String, dynamic> json) => VersionInfo(
        notes: (json['notes'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        platform: json['platform'] as String? ?? '',
        url: json['url'] as String? ?? '',
        version: json['version'] as String? ?? '',
      );
}

class VersionResponse {
  VersionResponse({
    required this.code,
    this.domain = const [],
    this.info = '',
    this.versionInfo,
  });

  final int code;
  final List<String> domain;
  final String info;
  final VersionInfo? versionInfo;

  factory VersionResponse.fromJson(Map<String, dynamic> json) =>
      VersionResponse(
        code: json['code'] as int? ?? -1,
        domain: (json['domain'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        info: json['info'] as String? ?? '',
        versionInfo: json['version_info'] != null
            ? VersionInfo.fromJson(
                json['version_info'] as Map<String, dynamic>,
              )
            : null,
      );
}

/// POST /version — mirrors `JsonPlaceholderService`.
class VersionApiClient {
  VersionApiClient({
    Dio? dio,
    String? baseUrl,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ??
                    const String.fromEnvironment(
                      'API_BASE_URL',
                      defaultValue:
                          'https://maapi-dev.azuredigitaltech.com.tw:18443/api/',
                    ),
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
              ),
            ),
        _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  String get baseUrl => _baseUrl ?? _dio.options.baseUrl;

  void updateBaseUrl(String domain, int port) {
    _dio.options.baseUrl = 'https://$domain:$port/api/';
  }

  Future<VersionResponse> checkVersion({
    required String platform,
    required String version,
    required String mid,
    String brand = '',
    String model = '',
    String osVersion = '',
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'version',
      queryParameters: {
        'platform': platform,
        'version': version,
        'mid': mid,
        'brand': brand,
        'model': model,
        'os_version': osVersion,
      },
    );
    return VersionResponse.fromJson(response.data ?? {});
  }
}
