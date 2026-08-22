import '../http_client.dart';

/// API服务类
/// 封装对后端API的调用
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  final HttpClient _httpClient = HttpClient();

  ApiService._internal();

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
    try {
      final response = await _httpClient.get(
        '/api/articles',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );

      return response.data;
    } catch (e) {
      rethrow;
    }
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
