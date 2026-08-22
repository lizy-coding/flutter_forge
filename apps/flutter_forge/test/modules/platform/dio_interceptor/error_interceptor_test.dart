import 'package:dio/dio.dart';
import 'package:flutter_forge_app/modules/platform/dio_interceptor/network/interceptor/error_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ErrorInterceptor', () {
    final interceptor = ErrorInterceptor();

    test('transformTimeout is handled and forwarded without error', () {
      final handler = _RecordingErrorHandler();
      final exception = DioException(
        type: DioExceptionType.transformTimeout,
        requestOptions: RequestOptions(path: '/x'),
      );

      interceptor.onError(exception, handler);

      expect(handler.passed, same(exception));
    });

    test('every DioExceptionType value is forwarded without error', () {
      for (final type in DioExceptionType.values) {
        final handler = _RecordingErrorHandler();
        final exception = DioException(
          type: type,
          requestOptions: RequestOptions(path: '/x'),
        );

        interceptor.onError(exception, handler);

        expect(handler.passed, same(exception), reason: 'type=$type');
      }
    });
  });
}

class _RecordingErrorHandler extends ErrorInterceptorHandler {
  DioException? passed;

  @override
  void next(DioException error) {
    passed = error;
  }
}
