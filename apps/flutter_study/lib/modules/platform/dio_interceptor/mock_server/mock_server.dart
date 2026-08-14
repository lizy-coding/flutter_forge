import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// 模拟服务器
/// 用于模拟后端API响应，测试拦截器功能
class MockServer {
  static const int defaultPort = 8080;

  HttpServer? _server;
  final int port;

  // 模拟的用户数据库
  final Map<String, String> _users = {
    'admin': 'password123',
    'user': 'user123',
  };

  // 模拟的token存储
  final Map<String, Map<String, dynamic>> _tokens = {};

  // 模拟的文章数据
  final List<Map<String, dynamic>> _articles = [];

  // 请求失败的概率（用于测试重试拦截器）
  double failureRate = 0.05;

  // 模拟网络延迟（毫秒）
  int networkDelay = 300;

  MockServer({this.port = defaultPort}) {
    // 初始化一些模拟数据
    _initMockData();
  }

  /// 初始化模拟数据
  void _initMockData() {
    // 生成一些模拟文章
    for (int i = 1; i <= 20; i++) {
      _articles.add({
        'id': i,
        'title': '文章标题 $i',
        'content': '这是文章 $i 的内容，用于测试拦截器功能。',
        'author': i % 2 == 0 ? 'admin' : 'user',
        'createdAt': DateTime.now()
            .subtract(Duration(days: 20 - i))
            .toIso8601String(),
      });
    }
  }

  /// 启动服务器
  Future<void> start() async {
    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);

      if (kDebugMode) {
        print('模拟服务器已启动，监听端口: $port');
      }

      _handleRequests();
    } catch (e) {
      if (kDebugMode) {
        print('启动模拟服务器失败: $e');
      }
    }
  }

  /// 停止服务器
  Future<void> stop() async {
    await _server?.close();
    _server = null;

    if (kDebugMode) {
      print('模拟服务器已停止');
    }
  }

  /// 处理请求
  void _handleRequests() {
    _server?.listen((request) async {
      // 添加CORS头
      request.response.headers.add('Access-Control-Allow-Origin', '*');
      request.response.headers.add(
        'Access-Control-Allow-Methods',
        'GET, POST, PUT, DELETE, OPTIONS',
      );
      request.response.headers.add(
        'Access-Control-Allow-Headers',
        'Origin, Content-Type, X-Auth-Token, Authorization',
      );

      // 处理预检请求
      if (request.method == 'OPTIONS') {
        request.response.statusCode = HttpStatus.ok;
        await request.response.close();
        return;
      }

      // 模拟网络延迟
      await Future.delayed(Duration(milliseconds: networkDelay));

      // 模拟随机失败（用于测试重试拦截器）
      if (Random().nextDouble() < failureRate) {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          json.encode({'success': false, 'message': '模拟服务器随机错误，请重试'}),
        );
        await request.response.close();

        if (kDebugMode) {
          print('${request.method} ${request.uri.path} - 模拟随机失败');
        }
        return;
      }

      // 路由到对应的处理器
      try {
        switch (request.uri.path) {
          case '/api/login':
            await _handleLogin(request);
            break;
          case '/api/refresh-token':
            await _handleRefreshToken(request);
            break;
          case '/api/articles':
            await _handleArticles(request);
            break;
          case '/api/articles/create':
            await _handleCreateArticle(request);
            break;
          default:
            // 404 Not Found
            request.response.statusCode = HttpStatus.notFound;
            request.response.headers.contentType = ContentType.json;
            request.response.write(
              json.encode({
                'success': false,
                'message': '404 Not Found: ${request.uri.path}',
              }),
            );
            break;
        }
      } catch (e) {
        // 处理过程中的错误
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          json.encode({'success': false, 'message': '服务器内部错误: $e'}),
        );

        if (kDebugMode) {
          print('处理请求时出错: $e');
        }
      } finally {
        await request.response.close();
      }
    });
  }

  /// 处理登录请求
  Future<void> _handleLogin(HttpRequest request) async {
    if (request.method != 'POST') {
      request.response.statusCode = HttpStatus.methodNotAllowed;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        json.encode({'success': false, 'message': '方法不允许'}),
      );
      return;
    }

    try {
      final requestBody = await _readRequestBody(request);
      final data = json.decode(requestBody);

      if (data is! Map ||
          !data.containsKey('username') ||
          !data.containsKey('password')) {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          json.encode({'success': false, 'message': '缺少用户名或密码'}),
        );
        return;
      }

      final username = data['username'] as String;
      final password = data['password'] as String;

      // 验证用户名和密码
      if (!_users.containsKey(username) || _users[username] != password) {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          json.encode({'success': false, 'message': '用户名或密码错误'}),
        );
        return;
      }

      // 生成一个新的token
      final token = _generateToken();
      final refreshToken = _generateToken(prefix: 'refresh');
      const expiresIn = 3600; // 1小时过期

      // 存储token信息
      _tokens[token] = {
        'username': username,
        'refreshToken': refreshToken,
        'expiresAt': DateTime.now()
            .add(const Duration(seconds: expiresIn))
            .toIso8601String(),
      };

      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        json.encode({
          'success': true,
          'data': {
            'token': token,
            'refreshToken': refreshToken,
            'expiresIn': expiresIn,
            'username': username,
          },
        }),
      );

      if (kDebugMode) {
        print('用户 $username 登录成功');
      }
    } catch (e) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        json.encode({'success': false, 'message': '无效的请求数据: $e'}),
      );
    }
  }

  /// 处理刷新token请求
  Future<void> _handleRefreshToken(HttpRequest request) async {
    if (request.method != 'POST') {
      request.response.statusCode = HttpStatus.methodNotAllowed;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        json.encode({'success': false, 'message': '方法不允许'}),
      );
      return;
    }

    try {
      final requestBody = await _readRequestBody(request);
      final data = json.decode(requestBody);

      if (data is! Map || !data.containsKey('refreshToken')) {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          json.encode({'success': false, 'message': '缺少刷新令牌'}),
        );
        return;
      }

      final refreshToken = data['refreshToken'] as String;

      // 查找匹配的刷新令牌
      String? matchedToken;
      for (final entry in _tokens.entries) {
        if (entry.value['refreshToken'] == refreshToken) {
          matchedToken = entry.key;
          break;
        }
      }

      if (matchedToken == null) {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          json.encode({'success': false, 'message': '无效的刷新令牌'}),
        );
        return;
      }

      // 生成新的token
      final oldTokenData = _tokens[matchedToken]!;
      final username = oldTokenData['username'];

      // 删除旧的token
      _tokens.remove(matchedToken);

      // 生成新的token
      final newToken = _generateToken();
      final newRefreshToken = _generateToken(prefix: 'refresh');
      const expiresIn = 3600; // 1小时过期

      // 存储新的token信息
      _tokens[newToken] = {
        'username': username,
        'refreshToken': newRefreshToken,
        'expiresAt': DateTime.now()
            .add(const Duration(seconds: expiresIn))
            .toIso8601String(),
      };

      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        json.encode({
          'success': true,
          'data': {
            'token': newToken,
            'refreshToken': newRefreshToken,
            'expiresIn': expiresIn,
            'username': username,
          },
        }),
      );

      if (kDebugMode) {
        print('用户 $username 刷新令牌成功');
      }
    } catch (e) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        json.encode({'success': false, 'message': '无效的请求数据: $e'}),
      );
    }
  }

  /// 处理获取文章列表请求
  Future<void> _handleArticles(HttpRequest request) async {
    // 验证token
    final authHeader = request.headers.value('Authorization');
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      request.response.statusCode = HttpStatus.unauthorized;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        json.encode({'success': false, 'message': '未授权，缺少有效的认证信息'}),
      );
      return;
    }

    // 解析token
    final token = authHeader.substring(7);
    if (!_tokens.containsKey(token)) {
      request.response.statusCode = HttpStatus.unauthorized;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        json.encode({'success': false, 'message': '无效的认证令牌'}),
      );
      return;
    }

    // 检查token是否过期
    final tokenData = _tokens[token]!;
    final expiresAt = DateTime.parse(tokenData['expiresAt']);
    if (DateTime.now().isAfter(expiresAt)) {
      request.response.statusCode = HttpStatus.unauthorized;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        json.encode({'success': false, 'message': '认证令牌已过期'}),
      );
      return;
    }

    // 获取分页参数
    final page = int.tryParse(request.uri.queryParameters['page'] ?? '1') ?? 1;
    final pageSize =
        int.tryParse(request.uri.queryParameters['pageSize'] ?? '10') ?? 10;

    // 计算分页
    final startIndex = (page - 1) * pageSize;
    final endIndex = startIndex + pageSize;
    final pagedArticles = _articles.length > startIndex
        ? _articles.sublist(
            startIndex,
            endIndex > _articles.length ? _articles.length : endIndex,
          )
        : [];

    request.response.statusCode = HttpStatus.ok;
    request.response.headers.contentType = ContentType.json;
    request.response.write(
      json.encode({
        'success': true,
        'data': {
          'articles': pagedArticles,
          'total': _articles.length,
          'page': page,
          'pageSize': pageSize,
          'totalPages': (_articles.length / pageSize).ceil(),
        },
      }),
    );
  }

  /// 处理创建文章请求
  Future<void> _handleCreateArticle(HttpRequest request) async {
    if (request.method != 'POST') {
      request.response.statusCode = HttpStatus.methodNotAllowed;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        json.encode({'success': false, 'message': '方法不允许'}),
      );
      return;
    }

    // 验证token
    final authHeader = request.headers.value('Authorization');
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      request.response.statusCode = HttpStatus.unauthorized;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        json.encode({'success': false, 'message': '未授权，缺少有效的认证信息'}),
      );
      return;
    }

    // 解析token
    final token = authHeader.substring(7);
    if (!_tokens.containsKey(token)) {
      request.response.statusCode = HttpStatus.unauthorized;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        json.encode({'success': false, 'message': '无效的认证令牌'}),
      );
      return;
    }

    // 检查token是否过期
    final tokenData = _tokens[token]!;
    final expiresAt = DateTime.parse(tokenData['expiresAt']);
    if (DateTime.now().isAfter(expiresAt)) {
      request.response.statusCode = HttpStatus.unauthorized;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        json.encode({'success': false, 'message': '认证令牌已过期'}),
      );
      return;
    }

    try {
      final requestBody = await _readRequestBody(request);
      final data = json.decode(requestBody);

      if (data is! Map ||
          !data.containsKey('title') ||
          !data.containsKey('content')) {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          json.encode({'success': false, 'message': '缺少标题或内容'}),
        );
        return;
      }

      final title = data['title'] as String;
      final content = data['content'] as String;
      final username = tokenData['username'] as String;

      // 创建新文章
      final newArticle = {
        'id': _articles.length + 1,
        'title': title,
        'content': content,
        'author': username,
        'createdAt': DateTime.now().toIso8601String(),
      };

      _articles.add(newArticle);

      request.response.statusCode = HttpStatus.created;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        json.encode({'success': true, 'data': newArticle}),
      );

      if (kDebugMode) {
        print('用户 $username 创建了新文章: $title');
      }
    } catch (e) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        json.encode({'success': false, 'message': '无效的请求数据: $e'}),
      );
    }
  }

  /// 读取请求体
  Future<String> _readRequestBody(HttpRequest request) {
    return utf8.decoder.bind(request).join();
  }

  /// 生成随机token
  String _generateToken({String prefix = 'token'}) {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    final token = base64Url.encode(values);
    return '$prefix.$token';
  }
}
