import '../../l10n/strings.dart';
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
    title: Text(appStrings(context).modelServiceTitle),
    content: SingleChildScrollView(
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(appStrings(context).modelServiceIntro),
            const SizedBox(height: 12),
            Text(
              appStrings(context).modelDataNotice,
              key: const ValueKey('genui-data-use-notice'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: endpoint,
              onChanged: (_) => endpointEdited = true,
              decoration: InputDecoration(
                labelText: appStrings(context).endpointLabel,
              ),
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
                  return appStrings(context).endpointInvalid;
                }
                return null;
              },
            ),
            TextFormField(
              controller: model,
              onChanged: (_) => modelEdited = true,
              decoration: InputDecoration(
                labelText: appStrings(context).modelName,
              ),
              validator: (text) => text == null || text.trim().isEmpty
                  ? appStrings(context).modelNameRequired
                  : null,
            ),
            TextField(
              key: const ValueKey('genui-service-token'),
              controller: token,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: appStrings(context).modelToken,
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(appStrings(context).cancel),
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
        child: Text(appStrings(context).useService),
      ),
    ],
  );
}
