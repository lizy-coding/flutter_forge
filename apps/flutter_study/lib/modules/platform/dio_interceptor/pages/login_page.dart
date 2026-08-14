import 'package:flutter/material.dart';
import 'package:flutter_study_learning/flutter_study_learning.dart';

import '../network/api/api_service.dart';
import '../network/interceptor/auth_interceptor.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await _apiService.login(username, password);
      if (result['success'] == true && result['data'] != null) {
        final token = result['data']['token'] as String;
        AuthInterceptor.setToken(token);
        if (mounted) Navigator.pop(context, true);
      } else {
        setState(() {
          _errorMessage = result['message'] ?? '登录失败';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '登录失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: '登录',
      interactiveDemo: SizedBox(
        height: 400,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: '用户名',
                  hintText: '请输入用户名',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? '请输入用户名' : null,
                textInputAction: TextInputAction.next,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: '密码',
                  hintText: '请输入密码',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? '请输入密码' : null,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _login(),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('登录'),
              ),
              const SizedBox(height: 16),
              const Text(
                '提示: 用户名: admin 或 user，密码: password123 或 user123',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      sections: [
        LearningObjectives(
          objectives: ['理解 Token 认证流程及拦截器自动注入机制', '掌握 AuthInterceptor 的实现与使用'],
        ),
        ConceptChips(concepts: ['Token', '认证', '登录', 'AuthInterceptor']),
        CodeSnippetCard(
          title: 'AuthInterceptor 实现',
          code:
              'class AuthInterceptor extends Interceptor {\n'
              '  @override\n'
              '  void onRequest(options, handler) {\n'
              '    final token = getToken();\n'
              '    if (token != null) {\n'
              '      options.headers["Authorization"] = "Bearer \$token";\n'
              '    }\n'
              '    handler.next(options);\n'
              '  }\n'
              '}',
          explanation: '拦截器在请求前检查 Token，自动注入 Authorization 请求头。',
        ),
        ExerciseCard(
          task: '在登录页添加"显示/隐藏密码"切换按钮，提升用户体验。',
          hint: '使用 TextFormField 的 obscureText 属性配合 State 中的 bool 变量切换显示状态。',
        ),
      ],
    );
  }
}
