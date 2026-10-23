import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Article transport shared by the interceptor lesson and workflow runner.
class ArticleApi {
  ArticleApi(this.dio, {this.defaultCancelToken});
  final Dio dio;
  final CancelToken? defaultCancelToken;

  Future<Map<String, dynamic>> getArticles({
    int page = 1,
    int pageSize = 10,
    CancelToken? cancelToken,
  }) async {
    if (page < 1 || pageSize < 1) {
      throw ArgumentError('Article pagination must be positive.');
    }
    final response = await dio.get<Map<String, dynamic>>(
      '/api/articles',
      queryParameters: {'page': page, 'pageSize': pageSize},
      cancelToken: cancelToken ?? defaultCancelToken,
    );
    return response.data ??
        (throw const FormatException('Missing article response'));
  }
}

/// A synthetic data source which exercises Dio's normal request/cancel path.
///
/// It never sends a request to the network.
class ArticleTeachingAdapter implements HttpClientAdapter {
  ArticleTeachingAdapter({
    this.delay = const Duration(milliseconds: 500),
    this.fail = false,
  });
  final Duration delay;
  final bool fail;
  bool _closed = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await Future.any([
      Future<void>.delayed(delay),
      if (cancelFuture != null)
        cancelFuture.then<void>(
          (_) => throw DioException.requestCancelled(
            requestOptions: options,
            reason: 'cancelled',
          ),
        ),
    ]);
    if (_closed) throw StateError('Article adapter closed');
    if (options.path != '/api/articles') {
      return ResponseBody.fromString('{}', 404);
    }
    if (fail) {
      return ResponseBody.fromString(
        '{"message":"教学故障：文章请求失败"}',
        503,
        headers: {
          'content-type': ['application/json'],
        },
      );
    }
    final page = options.queryParameters['page'] as int;
    final size = options.queryParameters['pageSize'] as int;
    final all = [
      for (var i = 1; i <= 20; i++)
        {
          'id': i,
          'title': '文章标题 $i',
          'content': '公开教学文章 $i',
          'author': i.isEven ? 'admin' : 'user',
          'createdAt': '2026-01-01T00:00:00Z',
        },
    ];
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': {
          'articles': all.skip((page - 1) * size).take(size).toList(),
          'total': all.length,
        },
      }),
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) => _closed = true;
}

const articleCapabilities = <Map<String, Object>>[
  {
    'id': 'articles.fetch',
    'version': 1,
    'title': '请求教学文章',
    'effect': 'read_synthetic_data',
  },
  {
    'id': 'articles.organize',
    'version': 1,
    'title': '筛选整理文章',
    'effect': 'pure_transform',
  },
];

class ArticleWorkflowRunner {
  ArticleWorkflowRunner({Dio? dio}) : _dio = dio;
  final Dio? _dio;

  Future<Map<String, Object>> run({
    required Map<String, dynamic> definition,
    required Map<String, dynamic> inputs,
    required CancelToken cancelToken,
    required Future<void> Function(String kind, String stepId) emit,
  }) async {
    if (!_validDefinition(definition)) {
      throw const FormatException('Unsupported workflow definition');
    }
    final page = _integer(inputs, 'page', 1, 20);
    final pageSize = _integer(inputs, 'pageSize', 1, 20);
    final delay = _integer(inputs, 'delayMs', 0, 5000);
    final query = inputs['query'];
    final failure = inputs['simulateFailure'];
    if (query is! String ||
        query.length > 80 ||
        failure is! bool ||
        inputs.keys.any(
          (key) => ![
            'page',
            'pageSize',
            'delayMs',
            'query',
            'simulateFailure',
          ].contains(key),
        )) {
      throw const FormatException('Invalid article workflow inputs');
    }
    final dio = _dio ?? Dio(BaseOptions(baseUrl: 'https://teaching.invalid'));
    if (_dio == null) {
      dio.httpClientAdapter = ArticleTeachingAdapter(
        delay: Duration(milliseconds: delay),
        fail: failure,
      );
    }
    try {
      _checkCancelled(cancelToken);
      await emit('step_started', 'fetch');
      final response = await ArticleApi(
        dio,
      ).getArticles(page: page, pageSize: pageSize, cancelToken: cancelToken);
      await emit('step_succeeded', 'fetch');
      _checkCancelled(cancelToken);
      await emit('step_started', 'organize');
      final data = response['data'];
      if (response['success'] != true ||
          data is! Map ||
          data['articles'] is! List) {
        throw const FormatException('Invalid article result');
      }
      final articles =
          (data['articles'] as List)
              .map((value) {
                if (value is! Map ||
                    value['id'] is! int ||
                    value['title'] is! String ||
                    value['author'] is! String) {
                  throw const FormatException('Invalid article row');
                }
                return Map<String, dynamic>.from(value);
              })
              .where(
                (row) => '${row['title']} ${row['author']}'
                    .toLowerCase()
                    .contains(query.toLowerCase()),
              )
              .toList()
            ..sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
      _checkCancelled(cancelToken);
      await emit('step_succeeded', 'organize');
      return {
        'columns': ['ID', '标题', '作者'],
        'rows': [
          for (final row in articles)
            ['${row['id']}', row['title'] as String, row['author'] as String],
        ],
      };
    } finally {
      if (_dio == null) dio.close(force: true);
    }
  }

  bool _validDefinition(Map<String, dynamic> definition) {
    if (definition['schema'] != 'forge.workflow.v1' ||
        definition['id'] != 'articles.explore' ||
        definition['version'] != 1) {
      return false;
    }
    final steps = definition['steps'];
    if (steps is! List || steps.length != 2) return false;
    for (var i = 0; i < 2; i++) {
      final step = steps[i];
      final name = i == 0 ? 'fetch' : 'organize';
      if (step is! Map ||
          step['id'] != name ||
          step['capability'] != 'articles.$name' ||
          step['version'] != 1) {
        return false;
      }
    }
    return true;
  }

  int _integer(Map<String, dynamic> values, String key, int low, int high) {
    final value = values[key];
    if (value is! int || value < low || value > high) {
      throw FormatException('Invalid $key');
    }
    return value;
  }

  void _checkCancelled(CancelToken token) {
    if (token.isCancelled) throw token.cancelError!;
  }
}
