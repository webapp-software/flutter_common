import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';

import '../local/auth_key_store.dart';
import '../utils/jwt_decoder.dart';

typedef TokenRefresher = Future<String?> Function(Dio dio, String? oldAccessToken);
typedef OnWriteHeaders = FutureOr<void> Function(Map<String, dynamic> headers);

const int kNetworkTimeout = 10000;

class TokenHeaderInterceptor extends Interceptor {
  TokenHeaderInterceptor({
    required this.authKeyStore,
    required this.tokenRefresher,
    required this.onTokenExpired,
    this.onWriteHeaders,
    this.showLogs = false,
  }) {
    _dio = Dio(BaseOptions(
      connectTimeout: kNetworkTimeout,
      receiveTimeout: kNetworkTimeout,
      sendTimeout: kNetworkTimeout,
    ));
    if (showLogs) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: true,
        request: true,
        error: true,
      ));
    }
  }

  final bool showLogs;
  final AuthKeyStore authKeyStore;
  final TokenRefresher tokenRefresher;
  final VoidCallback onTokenExpired;
  final OnWriteHeaders? onWriteHeaders;

  late final Dio _dio;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    String? accessToken = await authKeyStore.readAccessToken();

    if (accessToken != null) {
      if (JwtDecoder.isExpired(accessToken)) {
        await _tryRefreshAccessToken();
        accessToken = await authKeyStore.readAccessToken();
      }
      options.headers['Authorization'] = 'Bearer $accessToken';
      onWriteHeaders?.call(options.headers);
    }

    super.onRequest(options, handler);
  }

  Future<void> _tryRefreshAccessToken() async {
    final String? refreshToken = await authKeyStore.readRefreshToken();
    if (refreshToken != null) {
      if (JwtDecoder.isExpired(refreshToken)) {
        await _clearExit();
      } else {
        await _refreshAccessToken(refreshToken);
      }
    }
  }

  Future<void> _refreshAccessToken(String refreshToken) async {
    try {
      final String? oldAccessToken = await authKeyStore.readAccessToken();
      final String? newAccessToken = await tokenRefresher.call(_dio, oldAccessToken);
      if (newAccessToken != null) {
        authKeyStore.writeAccessToken(newAccessToken);
      } else {
        await _clearExit();
      }
    } on DioError catch (e) {
      log('TokenHeaderInterceptor._refreshAccessToken: ', error: e);
      if (e.type == DioErrorType.response) {
        await _clearExit();
      }
    }
  }

  Future<void> _clearExit() async {
    await authKeyStore.clear();
    onTokenExpired.call();
  }
}
