import 'package:dio/dio.dart';
import '../../../../shared/platform/build_features.dart';
import 'web_mock_http_adapter.dart';

void configurePlatformAdapter(Dio dio) {
  if (offlineEdition) dio.httpClientAdapter = WebMockHttpClientAdapter();
}
