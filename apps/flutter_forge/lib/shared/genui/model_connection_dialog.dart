import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model_source.dart';
import '../platform/build_features.dart';

const _endpointPreferenceKey = 'genui.connection.endpoint';
const _modelPreferenceKey = 'genui.connection.model';
const _defaultEndpoint = 'http://127.0.0.1:8766/v1/chat/completions';
const _defaultModel = 'codex-default';

Future<WorkbenchSource?> showModelConnection(BuildContext context) =>
    offlineEdition
    ? Future.value()
    : showDialog<WorkbenchSource>(
        context: context,
        builder: (_) => const _ModelConnectionDialog(),
      );

class _ModelConnectionDialog extends StatefulWidget {
  const _ModelConnectionDialog();
  @override
  State<_ModelConnectionDialog> createState() => _ModelConnectionDialogState();
}

class _ModelConnectionDialogState extends State<_ModelConnectionDialog> {
  // Programmatic updates from stored preferences must not clobber typing
  // that starts before the async load completes.
  bool endpointEdited = false;
  bool modelEdited = false;
  late final TextEditingController endpoint;
  late final TextEditingController model;
  final token = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    endpoint = TextEditingController(text: _defaultEndpoint);
    model = TextEditingController(text: _defaultModel);
    unawaited(_restoreSavedConfiguration());
  }

  Future<void> _restoreSavedConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final savedEndpoint = prefs.getString(_endpointPreferenceKey);
    final savedModel = prefs.getString(_modelPreferenceKey);
    if (savedEndpoint != null && savedEndpoint.isNotEmpty && !endpointEdited) {
      endpoint.text = savedEndpoint;
    }
    if (savedModel != null && savedModel.isNotEmpty && !modelEdited) {
      model.text = savedModel;
    }
  }

  // The access token is deliberately excluded: it stays in the returned
  // source object for the current page only, never in preferences or logs.
  Future<void> _rememberConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_endpointPreferenceKey, endpoint.text.trim());
    await prefs.setString(_modelPreferenceKey, model.text.trim());
  }

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
              '可连接单独启动的本机 Codex 桥接，使用已有 CLI 登录。也可连接兼容 Chat Completions 流式协议的服务。端点与模型名会记住，方便下次连接；临时令牌仅当前页面有效，离开后清除；浏览器端点需允许跨域。',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: endpoint,
              onChanged: (_) => endpointEdited = true,
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
              onChanged: (_) => modelEdited = true,
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
            unawaited(_rememberConfiguration());
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
