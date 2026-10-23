import 'package:flutter/material.dart';
import 'model_source.dart';

Future<WorkbenchSource?> showModelConnection(BuildContext context) =>
    showDialog<WorkbenchSource>(
      context: context,
      builder: (_) => const _ModelConnectionDialog(),
    );

class _ModelConnectionDialog extends StatefulWidget {
  const _ModelConnectionDialog();
  @override
  State<_ModelConnectionDialog> createState() => _ModelConnectionDialogState();
}

class _ModelConnectionDialogState extends State<_ModelConnectionDialog> {
  final endpoint = TextEditingController(
    text: 'http://127.0.0.1:8766/v1/chat/completions',
  );
  final model = TextEditingController(text: 'codex-default');
  final token = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    endpoint.dispose();
    model.dispose();
    token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('连接模型服务'),
    content: SingleChildScrollView(
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '可连接单独启动的本机 Codex 桥接，使用已有 CLI 登录。也可连接兼容 Chat Completions 流式协议的服务。配置仅用于当前页面，离开后清除；浏览器端点需允许跨域。',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: endpoint,
              decoration: const InputDecoration(labelText: '完整端点 URL'),
              validator: (text) {
                final uri = Uri.tryParse(text?.trim() ?? '');
                if (uri == null ||
                    !uri.hasAuthority ||
                    uri.userInfo.isNotEmpty ||
                    uri.hasQuery ||
                    uri.hasFragment ||
                    (uri.scheme != 'https' &&
                        !(uri.scheme == 'http' &&
                            [
                              'localhost',
                              '127.0.0.1',
                              '::1',
                            ].contains(uri.host)))) {
                  return '请输入 HTTPS 端点或本机 HTTP 端点。';
                }
                return null;
              },
            ),
            TextFormField(
              controller: model,
              decoration: const InputDecoration(labelText: '模型名称'),
              validator: (text) =>
                  text == null || text.trim().isEmpty ? '请输入模型名称。' : null,
            ),
            TextField(
              key: const ValueKey('genui-service-token'),
              controller: token,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(labelText: '临时访问令牌（本机服务可留空）'),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: () {
          if (formKey.currentState!.validate()) {
            Navigator.pop(
              context,
              OpenAiWorkbenchSource(
                endpoint: Uri.parse(endpoint.text.trim()),
                model: model.text.trim(),
                token: token.text.trim(),
              ),
            );
          }
        },
        child: const Text('使用此服务'),
      ),
    ],
  );
}
