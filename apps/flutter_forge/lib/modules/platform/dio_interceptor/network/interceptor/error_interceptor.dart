import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// 错误处理拦截器
/// 用于统一处理网络请求错误
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 错误信息
    String errorMessage = "未知错误";

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
        errorMessage = "连接超时";
        break;
      case DioExceptionType.sendTimeout:
        errorMessage = "请求超时";
        break;
      case DioExceptionType.receiveTimeout:
        errorMessage = "响应超时";
        break;
      case DioExceptionType.badResponse:
        // 服务器返回的错误信息
        final int? statusCode = err.response?.statusCode;
        switch (statusCode) {
          case 400:
            errorMessage = "请求参数错误";
            break;
          case 401:
            errorMessage = "未授权，请登录";
            break;
          case 403:
            errorMessage = "拒绝访问";
            break;
          case 404:
            errorMessage = "请求地址出错";
            break;
          case 500:
            errorMessage = "服务器内部错误";
            break;
          case 502:
            errorMessage = "网关错误";
            break;
          case 503:
            errorMessage = "服务不可用";
            break;
          case 505:
            errorMessage = "HTTP版本不支持";
            break;
          default:
            errorMessage = "响应错误: ${statusCode ?? '未知状态码'}";
            break;
        }

        // 尝试获取服务器返回的错误信息
        if (err.response?.data != null && err.response?.data is Map) {
          final data = err.response!.data as Map;
          if (data.containsKey('message')) {
            errorMessage = "服务器返回: ${data['message']}";
          }
        }
        break;
      case DioExceptionType.cancel:
        errorMessage = "请求取消";
        break;
      case DioExceptionType.connectionError:
        errorMessage = "连接错误，请检查网络";
        break;
      case DioExceptionType.unknown:
        if (err.error is SocketException) {
          errorMessage = "网络连接失败，请检查网络";
        } else {
          errorMessage = "未知错误: ${err.message}";
        }
        break;
      case DioExceptionType.badCertificate:
        errorMessage = "证书验证失败";
        break;
    }

    if (kDebugMode) {
      print('ErrorInterceptor - 捕获到错误: $errorMessage');
      print('URL: ${err.requestOptions.uri}');
      print('Method: ${err.requestOptions.method}');
      if (err.requestOptions.data != null) {
        print('Data: ${err.requestOptions.data}');
      }
      if (err.requestOptions.queryParameters.isNotEmpty) {
        print('QueryParams: ${err.requestOptions.queryParameters}');
      }
    }

    // 可以在这里统一显示错误提示，或者发送错误日志到服务器

    // 错误继续传递
    handler.next(err);
  }
}
