import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// 认证拦截器
/// 用于在请求发出前为每个请求添加认证信息（如：token）
class AuthInterceptor extends Interceptor {
  /// 模拟的本地存储token
  static String? _token;

  /// 设置token
  static void setToken(String token) {
    _token = token;
  }

  /// 清除token
  static void clearToken() {
    _token = null;
  }

  /// 获取token
  static String? getToken() {
    return _token;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 如果存在token，则添加到请求头中
    if (_token != null && _token!.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $_token';
      if (kDebugMode) {
        print('AuthInterceptor - 添加认证信息: Bearer $_token');
      }
    }

    // 请求继续
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // 检查响应中是否包含新的token
    if (response.statusCode == 200 && response.data is Map) {
      final Map<String, dynamic> data = response.data;
      if (data.containsKey('token')) {
        final String newToken = data['token'];
        _token = newToken;
        if (kDebugMode) {
          print('AuthInterceptor - 更新认证Token: $newToken');
        }
      }
    }

    // 响应继续
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 401表示未授权，可能是token过期
    if (err.response?.statusCode == 401) {
      if (kDebugMode) {
        print('AuthInterceptor - 认证失败: ${err.message}');
      }

      // 清除token
      _token = null;

      // 这里可以跳转到登录页面或者自动刷新token
      // 如果要实现token刷新，应该在这里尝试刷新token并重试请求
    }

    // 错误继续传递
    handler.next(err);
  }
}
