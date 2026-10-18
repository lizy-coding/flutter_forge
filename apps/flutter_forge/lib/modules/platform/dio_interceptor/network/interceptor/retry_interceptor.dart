import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'socket_error_io.dart'
    if (dart.library.js_interop) 'socket_error_web.dart';

/// 重试拦截器
/// 用于网络请求失败时自动重试
class RetryInterceptor extends Interceptor {
  final Dio dio;
  // 最大重试次数
  final int maxRetries;
  // 重试间隔（毫秒）
  final int retryInterval;
  // 需要重试的错误类型
  final Set<DioExceptionType> retryableErrors;

  // 重试计数器，记录每个请求的重试次数
  final Map<String, int> _retryCountMap = {};

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.retryInterval = 1000,
    Set<DioExceptionType>? retryableErrors,
  }) : retryableErrors =
           retryableErrors ??
           {
             DioExceptionType.connectionTimeout,
             DioExceptionType.receiveTimeout,
             DioExceptionType.connectionError,
           };

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 获取请求的唯一标识符（URL+参数+方法）
    final String requestId = _getRequestId(err.requestOptions);

    // 获取当前重试次数，默认为0
    final int currentRetryCount = _retryCountMap[requestId] ?? 0;

    // 判断是否满足重试条件
    bool shouldRetry =
        currentRetryCount < maxRetries && // 未超过最大重试次数
        _shouldRetryError(err) && // 是可重试的错误类型
        _isIdempotentRequest(err.requestOptions); // 是幂等请求

    if (shouldRetry) {
      // 增加重试计数
      _retryCountMap[requestId] = currentRetryCount + 1;

      if (kDebugMode) {
        print(
          'RetryInterceptor - 将在${retryInterval}ms后进行第${currentRetryCount + 1}次重试',
        );
        print('请求: ${err.requestOptions.uri}');
      }

      // 等待指定的重试间隔
      await Future.delayed(Duration(milliseconds: retryInterval));
      final token = err.requestOptions.cancelToken;
      if (token?.isCancelled == true) {
        _retryCountMap.remove(requestId);
        handler.next(token!.cancelError ?? err);
        return;
      }

      try {
        // Reuse the owning client so URI, adapter, authentication and cancellation
        // remain attached to the same lesson session.
        final response = await dio.fetch<dynamic>(err.requestOptions);

        if (kDebugMode) {
          print('RetryInterceptor - 重试成功: ${response.statusCode}');
        }

        // 重试成功，清除重试计数
        _retryCountMap.remove(requestId);

        // 返回重试成功的响应
        handler.resolve(response);
        return;
      } catch (e) {
        if (kDebugMode) {
          print('RetryInterceptor - 重试失败: $e');
        }

        // 如果是最后一次重试失败，清除重试计数
        if (currentRetryCount + 1 >= maxRetries) {
          _retryCountMap.remove(requestId);
        }

        // 重试失败，继续传递错误
        handler.next(err);
        return;
      }
    }

    // 不满足重试条件，继续传递错误
    handler.next(err);
  }

  /// 判断错误是否应该重试
  bool _shouldRetryError(DioException err) {
    // 网络连接错误
    if (isSocketError(err.error)) {
      return true;
    }

    // 检查错误类型是否在可重试错误列表中
    return retryableErrors.contains(err.type);
  }

  /// 判断请求是否是幂等的（可以安全重试）
  bool _isIdempotentRequest(RequestOptions options) {
    // GET、HEAD、OPTIONS 请求通常是幂等的
    return [
      'GET',
      'HEAD',
      'OPTIONS',
      'PUT',
      'DELETE',
    ].contains(options.method.toUpperCase());
    // 注意：POST请求通常不是幂等的，但某些特定API可能设计为幂等，这需要具体情况具体分析
  }

  /// 生成请求的唯一标识符
  String _getRequestId(RequestOptions options) {
    return '${options.method}_${options.uri}_${options.data.hashCode}_${options.queryParameters.hashCode}';
  }
}
