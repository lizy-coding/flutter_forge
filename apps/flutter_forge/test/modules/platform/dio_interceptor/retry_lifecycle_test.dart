import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_forge_app/modules/platform/dio_interceptor/network/interceptor/retry_interceptor.dart';

class _RetryAdapter implements HttpClientAdapter {
  final seen = <Uri>[];
  final firstAttempt = Completer<void>();
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    seen.add(options.uri);
    if (seen.length == 1) {
      firstAttempt.complete();
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      '{"success":true}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'retry stays on the owned adapter and preserves the dynamic server URI',
    () async {
      final adapter = _RetryAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:49123'))
        ..httpClientAdapter = adapter;
      dio.interceptors.add(RetryInterceptor(dio: dio, retryInterval: 1));
      try {
        final response = await dio.get<dynamic>('/api/articles');
        expect(response.statusCode, 200);
        expect(adapter.seen, [
          Uri.parse('http://127.0.0.1:49123/api/articles'),
          Uri.parse('http://127.0.0.1:49123/api/articles'),
        ]);
      } finally {
        dio.close(force: true);
      }
    },
  );

  test(
    'closing a session cancels delayed retry before another transport call',
    () async {
      final adapter = _RetryAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:49123'))
        ..httpClientAdapter = adapter;
      dio.interceptors.add(RetryInterceptor(dio: dio, retryInterval: 20));
      final token = CancelToken();
      final response = dio.get<dynamic>('/api/articles', cancelToken: token);
      final cancelled = expectLater(response, throwsA(isA<DioException>()));
      await adapter.firstAttempt.future;
      token.cancel('owner closed');
      dio.close(force: true);
      await cancelled;
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(adapter.seen, hasLength(1));
    },
  );
}
