import 'package:flutter/material.dart';
import 'package:flutter_study_learning/flutter_study_learning.dart';
import 'package:go_router/go_router.dart';

import '../models/article.dart';
import '../network/api/api_service.dart';
import '../network/interceptor/auth_interceptor.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _baseRoute = '/dio-interceptor';

  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  List<Article> _articles = [];
  int _currentPage = 1;
  int _totalPages = 1;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadArticles() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await _apiService.getArticles(page: _currentPage);
      if (result['success'] == true && result['data'] != null) {
        final articlesData = result['data']['articles'] as List;
        final articles = articlesData
            .map((json) => Article.fromJson(json))
            .toList();
        setState(() {
          _articles = articles;
          _totalPages = result['data']['totalPages'] as int;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? '加载文章失败';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshArticles() async {
    _currentPage = 1;
    await _loadArticles();
  }

  Future<void> _loadNextPage() async {
    if (_currentPage < _totalPages) {
      setState(() => _currentPage++);
      await _loadArticles();
    }
  }

  Future<void> _loadPreviousPage() async {
    if (_currentPage > 1) {
      setState(() => _currentPage--);
      await _loadArticles();
    }
  }

  void _openLoginPage() async {
    final result = await context.push<bool>('$_baseRoute/login');
    if (result == true) await _refreshArticles();
  }

  void _logout() {
    AuthInterceptor.clearToken();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已退出登录')));
    _refreshArticles();
  }

  bool get isLoggedIn => AuthInterceptor.getToken() != null;

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: 'Dio 拦截器演示',
      floatingActionButton: isLoggedIn
          ? FloatingActionButton(
              onPressed: _showAddArticleDialog,
              tooltip: '添加文章',
              child: const Icon(Icons.add),
            )
          : null,
      interactiveDemo: SizedBox(
        height: 500,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  isLoggedIn ? '已登录' : '未登录',
                  style: TextStyle(
                    fontSize: 12,
                    color: isLoggedIn ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(isLoggedIn ? Icons.logout : Icons.login, size: 20),
                  onPressed: isLoggedIn ? _logout : _openLoginPage,
                  tooltip: isLoggedIn ? '退出登录' : '登录',
                ),
              ],
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      sections: [
        LearningObjectives(
          objectives: [
            '理解 Dio 拦截器的工作原理和链路机制',
            '掌握 Auth 拦截器实现 Token 自动注入',
            '理解 Error 拦截器统一错误处理',
            '掌握 Retry 拦截器实现请求重试',
          ],
        ),
        ConceptChips(
          concepts: ['Dio', '拦截器', 'Token', '重试机制', '错误处理', 'Mock Server'],
        ),
        CodeSnippetCard(
          title: 'Dio 拦截器链路',
          code:
              'final dio = Dio(BaseOptions(baseUrl: url));\n'
              'dio.interceptors.addAll([\n'
              '  AuthInterceptor(),\n'
              '  LoggingInterceptor(),\n'
              '  RetryInterceptor(),\n'
              '  ErrorInterceptor(),\n'
              ']);',
          explanation: '拦截器按添加顺序组成链路，请求从 Auth → Logging → Retry → Error 依次经过。',
        ),
        CommonPitfalls(
          pitfalls: [
            '拦截器顺序很重要 — Auth 应放在首位确保后续拦截器也能使用 Token',
            'Retry 拦截器需避免死循环 — 设置最大重试次数和指数退避策略',
            'Error 拦截器不要吞掉异常 — 统一处理后应继续抛出或返回友好提示',
          ],
        ),
        ExerciseCard(
          task: '在 RetryInterceptor 中添加"登录过期"检测，当响应为 401 时自动跳转登录页。',
          hint:
              '在 onError 中检查 DioException.response?.statusCode == 401，然后触发全局导航事件。',
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading && _articles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null && _articles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '错误: $_errorMessage',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshArticles,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    if (_articles.isEmpty) {
      return const Center(child: Text('没有文章'));
    }
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshArticles,
            child: ListView.builder(
              itemCount: _articles.length,
              itemBuilder: (context, index) {
                final article = _articles[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(article.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(article.content),
                        const SizedBox(height: 4),
                        Text(
                          '作者: ${article.author} · ${_formatDate(article.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ),
        ),
        _buildPagination(),
      ],
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _currentPage > 1 ? _loadPreviousPage : null,
            tooltip: '上一页',
          ),
          Text('$_currentPage / $_totalPages'),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _currentPage < _totalPages ? _loadNextPage : null,
            tooltip: '下一页',
          ),
        ],
      ),
    );
  }

  void _showAddArticleDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('添加文章'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: '标题',
                hintText: '请输入文章标题',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                labelText: '内容',
                hintText: '请输入文章内容',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final content = contentController.text.trim();
              if (title.isEmpty || content.isEmpty) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('标题和内容不能为空')),
                );
                return;
              }
              Navigator.pop(dialogContext);
              setState(() => _isLoading = true);
              try {
                final result = await _apiService.createArticle(title, content);
                if (!mounted) return;
                if (result['success'] == true) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('文章创建成功')),
                  );
                  await _refreshArticles();
                } else {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text(result['message'] ?? '文章创建失败')),
                  );
                  setState(() => _isLoading = false);
                }
              } catch (e) {
                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('创建失败: $e')),
                );
                setState(() => _isLoading = false);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
