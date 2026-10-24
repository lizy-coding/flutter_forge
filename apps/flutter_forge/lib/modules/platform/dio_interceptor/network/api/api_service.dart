import '../http_client.dart';
import 'package:forge_articles/forge_articles.dart';

/// API服务类
/// 封装对后端API的调用
class ApiService {
  ApiService(this._httpClient);
  final HttpClient _httpClient;
  bool get isLoggedIn => _httpClient.auth.getToken() != null;
  void setToken(String token) => _httpClient.auth.setToken(token);
  void clearToken() => _httpClient.auth.clearToken();

  /// 登录
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _httpClient.post(
        '/api/login',
        data: {'username': username, 'password': password},
      );

      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// 刷新令牌
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await _httpClient.post(
        '/api/refresh-token',
        data: {'refreshToken': refreshToken},
      );

      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// 获取文章列表
  Future<Map<String, dynamic>> getArticles({
    int page = 1,
    int pageSize = 10,
  }) async {
    return ArticleApi(
      _httpClient.dio,
      defaultCancelToken: _httpClient.requestCancelToken,
    ).getArticles(page: page, pageSize: pageSize);
  }

  /// 创建文章
  Future<Map<String, dynamic>> createArticle(
    String title,
    String content,
  ) async {
    try {
      final response = await _httpClient.post(
        '/api/articles/create',
        data: {'title': title, 'content': content},
      );

      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
