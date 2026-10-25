import 'package:flutter/material.dart';
import 'package:flutter_forge_app/shared/genui/model_connection_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _openDialog(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showModelConnection(context),
            child: const Text('connect'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('connect'));
  await tester.pumpAndSettle();
}

String _fieldContent(WidgetTester tester, String label) {
  final field = tester.widget<TextFormField>(
    find.widgetWithText(TextFormField, label),
  );
  return field.controller!.text;
}

void main() {
  testWidgets('a saved endpoint and model are restored on reopen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'genui.connection.endpoint':
          'https://models.example.com/v1/chat/completions',
      'genui.connection.model': 'gpt-forge',
    });
    await _openDialog(tester);
    await tester.pumpAndSettle();

    expect(
      _fieldContent(tester, '完整端点 URL'),
      'https://models.example.com/v1/chat/completions',
    );
    expect(_fieldContent(tester, '模型名称'), 'gpt-forge');
  });

  testWidgets(
    'confirming remembers the endpoint and model but never the token',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _openDialog(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, '完整端点 URL'),
        'http://127.0.0.1:9000/v1/chat/completions',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '模型名称'),
        'local-model',
      );
      await tester.enterText(
        find.byKey(const ValueKey('genui-service-token')),
        'secret-token',
      );
      await tester.tap(find.text('使用此服务'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('genui.connection.endpoint'),
        'http://127.0.0.1:9000/v1/chat/completions',
      );
      expect(prefs.getString('genui.connection.model'), 'local-model');
      expect(
        prefs.getKeys().where((key) => key.toLowerCase().contains('token')),
        isEmpty,
        reason: '临时令牌绝不能写入偏好',
      );
    },
  );

  testWidgets('an invalid endpoint is rejected and stores nothing', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await _openDialog(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, '完整端点 URL'),
      'ftp://not-allowed',
    );
    await tester.tap(find.text('使用此服务'));
    await tester.pumpAndSettle();

    expect(find.text('请输入 HTTPS 端点或本机 HTTP 端点。'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), isEmpty);
  });

  testWidgets('typing is never clobbered by the async restore', (tester) async {
    SharedPreferences.setMockInitialValues({
      'genui.connection.endpoint':
          'https://saved.example.com/v1/chat/completions',
      'genui.connection.model': 'saved-model',
    });
    await _openDialog(tester);
    // One pump builds the dialog and starts the restore future; typing races
    // it. Whichever order the microtasks land in, the typed value must win.
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextFormField, '完整端点 URL'),
      'http://127.0.0.1:9001/v1/chat/completions',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '模型名称'),
      'typed-model',
    );
    await tester.pumpAndSettle();

    expect(
      _fieldContent(tester, '完整端点 URL'),
      'http://127.0.0.1:9001/v1/chat/completions',
    );
    expect(_fieldContent(tester, '模型名称'), 'typed-model');
  });

  testWidgets('empty saved values fall back to the defaults', (tester) async {
    SharedPreferences.setMockInitialValues({
      'genui.connection.endpoint': '',
      'genui.connection.model': '',
    });
    await _openDialog(tester);
    await tester.pumpAndSettle();

    expect(_fieldContent(tester, '完整端点 URL'), contains('127.0.0.1:8766'));
    expect(_fieldContent(tester, '模型名称'), 'codex-default');
  });
}
