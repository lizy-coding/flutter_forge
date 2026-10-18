import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'interceptor/auth_interceptor.dart';
import 'interceptor/error_interceptor.dart';
import 'interceptor/log_interceptor.dart';
import 'interceptor/retry_interceptor.dart';
import 'platform_adapter_io.dart'
    if (dart.library.js_interop) 'platform_adapter_web.dart';

/// 网络请求客户端
class HttpClient {
  late Dio dio;
  final CancelToken _cancelToken = CancelToken();
  final AuthInterceptor auth = AuthInterceptor();

  HttpClient({required String baseUrl}) {
    // 基础配置
    BaseOptions options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {},
      contentType: 'application/json; charset=utf-8',
      responseType: ResponseType.json,
    );

    dio = Dio(options);
    configurePlatformAdapter(dio);

    // 添加拦截器
    dio.interceptors.add(auth);
    dio.interceptors.add(ErrorInterceptor());
    dio.interceptors.add(RetryInterceptor(dio: dio));

    // 调试模式下启用日志拦截器
    if (kDebugMode) {
      dio.interceptors.add(LoggingInterceptor());
    }
  }

  /// 关闭dio
  void cancelRequests() {
    _cancelToken.cancel("应用关闭");
  }

  void dispose() {
    cancelRequests();
    dio.close(force: true);
  }

  /// GET请求
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    return await dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken ?? _cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// POST请求
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return await dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken ?? _cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// PUT请求
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return await dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken ?? _cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// DELETE请求
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return await dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken ?? _cancelToken,
    );
  }
}
