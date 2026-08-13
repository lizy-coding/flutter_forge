import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// 日志拦截器
/// 用于打印网络请求和响应信息，方便调试
class LoggingInterceptor extends Interceptor {
  // 记录请求开始时间
  final Map<String, int> _requestStartTime = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 记录请求开始时间
    _requestStartTime[options.uri.toString()] =
        DateTime.now().millisecondsSinceEpoch;

    if (kDebugMode) {
      debugPrint(
        '┌────────────────────────────────────────────────────────────────────────────────────────────────────',
      );
      debugPrint('│ 请求 [${options.method}] → ${options.uri}');

      if (options.headers.isNotEmpty) {
        debugPrint('│ Headers:');
        options.headers.forEach((key, value) {
          debugPrint('│   $key: $value');
        });
      }

      if (options.data != null) {
        debugPrint('│ Body: ${options.data}');
      }

      if (options.queryParameters.isNotEmpty) {
        debugPrint('│ QueryParameters:');
        options.queryParameters.forEach((key, value) {
          debugPrint('│   $key: $value');
        });
      }

      debugPrint(
        '└────────────────────────────────────────────────────────────────────────────────────────────────────',
      );
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // 计算请求耗时
    final requestUrl = response.requestOptions.uri.toString();
    final startTime = _requestStartTime[requestUrl];
    final endTime = DateTime.now().millisecondsSinceEpoch;
    final duration = startTime != null ? endTime - startTime : null;

    // 请求完成后清除记录
    _requestStartTime.remove(requestUrl);

    if (kDebugMode) {
      debugPrint(
        '┌────────────────────────────────────────────────────────────────────────────────────────────────────',
      );
      debugPrint(
        '│ 响应 [${response.statusCode}] ← ${response.requestOptions.uri}',
      );

      if (duration != null) {
        debugPrint('│ 耗时: ${duration}ms');
      }

      if (response.headers.isEmpty == false) {
        debugPrint('│ Headers:');
        response.headers.forEach((key, values) {
          debugPrint('│   $key: ${values.join(', ')}');
        });
      }

      debugPrint('│ 响应数据:');
      printWrapped(response.data.toString());

      debugPrint(
        '└────────────────────────────────────────────────────────────────────────────────────────────────────',
      );
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 计算请求耗时
    final requestUrl = err.requestOptions.uri.toString();
    final startTime = _requestStartTime[requestUrl];
    final endTime = DateTime.now().millisecondsSinceEpoch;
    final duration = startTime != null ? endTime - startTime : null;

    // 请求完成后清除记录
    _requestStartTime.remove(requestUrl);

    if (kDebugMode) {
      debugPrint(
        '┌────────────────────────────────────────────────────────────────────────────────────────────────────',
      );
      debugPrint(
        '│ 错误 [${err.response?.statusCode ?? "未知状态码"}] ← ${err.requestOptions.uri}',
      );
      debugPrint('│ 类型: ${err.type}');

      if (duration != null) {
        debugPrint('│ 耗时: ${duration}ms');
      }

      debugPrint('│ 消息: ${err.message}');

      if (err.response != null) {
        debugPrint('│ 响应数据:');
        printWrapped(err.response.toString());
      }

      debugPrint(
        '└────────────────────────────────────────────────────────────────────────────────────────────────────',
      );
    }

    handler.next(err);
  }

  /// 格式化打印较长的内容
  void printWrapped(String text) {
    const int maxLength = 100;
    final pattern = RegExp('.{1,$maxLength}');

    pattern.allMatches(text).forEach((match) {
      if (kDebugMode) {
        debugPrint('│   ${match.group(0)}');
      }
    });
  }
}
