import 'package:dio/dio.dart';

class WorkflowHubClient {
  WorkflowHubClient({required Uri endpoint, required String token, Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
            ),
          ) {
    if (endpoint.userInfo.isNotEmpty ||
        endpoint.hasQuery ||
        endpoint.hasFragment ||
        !endpoint.hasAuthority ||
        (endpoint.scheme != 'https' &&
            !(endpoint.scheme == 'http' &&
                ['localhost', '127.0.0.1', '::1'].contains(endpoint.host)))) {
      throw const FormatException('Hub 须为 HTTPS 或本机 HTTP 地址。');
    }
    _dio.options.baseUrl = endpoint.toString().replaceFirst(RegExp(r'/$'), '');
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  final Dio _dio;

  Future<Map<String, dynamic>> _request(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final response = await _dio.request<Object?>(
      path,
      data: body,
      options: Options(method: method),
    );
    if (response.data == null) return {};
    if (response.data is! Map) throw const FormatException('Hub 返回了无效对象。');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> workflows() => _request('GET', '/v1/workflows');
  Future<void> register(
    String executor,
    List<Map<String, Object>> capabilities,
  ) async {
    await _request('POST', '/v1/executors', {
      'executorId': executor,
      'capabilities': capabilities,
    });
  }

  Future<Map<String, dynamic>> create(
    String executor,
    String key,
    Map<String, dynamic> definition,
    Map<String, dynamic> inputs, {
    String? retryOf,
  }) => _request('POST', '/v1/runs', {
    'executorId': executor,
    'requestKey': key,
    'workflowId': definition['id'],
    'workflowVersion': definition['version'],
    'inputs': inputs,
    if (retryOf != null) 'retryOf': retryOf,
  });
  Future<Map<String, dynamic>> claim(String executor) =>
      _request('POST', '/v1/executors/$executor/claim', {});
  Future<Map<String, dynamic>> run(String id) =>
      _request('GET', '/v1/runs/$id');
  Future<List<Map<String, dynamic>>> history(String executor) async {
    final response = await _request(
      'GET',
      '/v1/runs?executorId=${Uri.encodeQueryComponent(executor)}',
    );
    return (response['runs'] as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<Map<String, dynamic>> cancel(String id) =>
      _request('POST', '/v1/runs/$id/cancel', {});
  Future<Map<String, dynamic>> event(
    String id,
    String executor,
    String lease,
    String key,
    Map<String, dynamic> value,
  ) => _request('POST', '/v1/runs/$id/events', {
    'executorId': executor,
    'leaseToken': lease,
    'eventKey': key,
    'event': value,
  });
  void close() => _dio.close(force: true);
}
