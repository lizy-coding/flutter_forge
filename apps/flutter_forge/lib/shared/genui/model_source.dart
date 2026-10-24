import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';

class WorkbenchRequest {
  const WorkbenchRequest({
    required this.prompt,
    required this.snapshot,
    required this.components,
    required this.systemPrompt,
  });

  final String prompt;
  final Map<String, Object?> snapshot;
  final List<Map<String, dynamic>> components;
  final String systemPrompt;
}

abstract interface class WorkbenchSource {
  String get label;
  bool get isReplay;
  Stream<String> generate(WorkbenchRequest request, CancelToken cancelToken);
  void dispose();
}

// A single optional live adapter. Credentials stay in this object for the
// current page only; no preferences, logs, or browser assets store the token.
class OpenAiWorkbenchSource implements WorkbenchSource {
  OpenAiWorkbenchSource({
    required this.endpoint,
    required this.model,
    required String token,
    Dio? dio,
  }) : _token = token,
       _dio =
           dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 15)));

  final Uri endpoint;
  final String model;
  final String _token;
  final Dio _dio;
  @override
  String get label => '真实生成 · $model';
  @override
  bool get isReplay => false;

  @override
  Stream<String> generate(
    WorkbenchRequest request,
    CancelToken cancelToken,
  ) async* {
    if (endpoint.scheme != 'https' &&
        !(endpoint.scheme == 'http' &&
            ['localhost', '127.0.0.1', '::1'].contains(endpoint.host))) {
      throw const FormatException('远程端点须使用 HTTPS；本机开发可用 HTTP。');
    }
    final response = await _dio.postUri<ResponseBody>(
      endpoint,
      cancelToken: cancelToken,
      options: Options(
        responseType: ResponseType.stream,
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 100),
        headers: {
          'Content-Type': 'application/json',
          if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
        },
      ),
      data: {
        'model': model,
        'stream': true,
        'messages': [
          {'role': 'system', 'content': request.systemPrompt},
          {
            'role': 'user',
            'content': jsonEncode({
              'question': request.prompt,
              'snapshot': request.snapshot,
              'components': request.components,
            }),
          },
        ],
      },
    );
    var completed = false;
    await for (final line
        in response.data!.stream
            .cast<List<int>>()
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      if (cancelToken.isCancelled) return;
      if (!line.startsWith('data:')) continue;
      final payload = line.substring(5).trim();
      if (payload == '[DONE]') {
        completed = true;
        break;
      }
      if (payload.isEmpty) continue;
      final json = jsonDecode(payload) as Map<String, dynamic>;
      if (json.containsKey('error')) throw const FormatException('模型服务返回错误。');
      final choices = json['choices'] as List?;
      if (choices == null || choices.isEmpty) continue;
      final choice = choices.first as Map<String, dynamic>;
      final delta = choice['delta'] as Map<String, dynamic>?;
      final content = delta?['content'];
      if (content is String) yield content;
      if (choice['finish_reason'] == 'length') {
        throw const FormatException('模型输出被截断，请缩短请求后重试。');
      }
    }
    if (!completed) throw const FormatException('流式响应未完整结束，请重试。');
  }

  @override
  void dispose() => _dio.close(force: true);
}
