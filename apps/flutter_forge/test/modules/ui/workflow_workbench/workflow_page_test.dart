import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_forge_app/shared/table/scroll_table.dart';
import 'package:flutter_forge_app/shared/workflows/hub_client.dart';
import 'package:flutter_forge_app/modules/ui/workflow_workbench/workflow_page.dart';
import 'package:flutter_forge_app/modules/ui/workflow_workbench/workflow_session.dart';

const flow = <String, dynamic>{
  'id': 'articles.explore',
  'version': 1,
  'inputSchema': {
    'properties': {
      'query': {
        'type': 'string',
        'title': '筛选词',
        'default': '',
        'maxLength': 80,
      },
      'page': {
        'type': 'integer',
        'title': '页码',
        'default': 1,
        'minimum': 1,
        'maximum': 20,
      },
    },
  },
};

class FakeHub extends WorkflowHubClient {
  FakeHub()
    : super(endpoint: Uri.parse('http://127.0.0.1:8768'), token: 'test');
  @override
  Future<Map<String, dynamic>> workflows() async => {
    'workflows': [flow],
  };
  @override
  Future<void> register(
    String executor,
    List<Map<String, Object>> capabilities,
  ) async {}
  @override
  Future<Map<String, dynamic>> claim(String executor) async => {};
  @override
  Future<List<Map<String, dynamic>>> history(String executor) async => [];
  @override
  Future<Map<String, dynamic>> create(
    String executor,
    String key,
    Map<String, dynamic> definition,
    Map<String, dynamic> inputs, {
    String? retryOf,
  }) async => {
    'id': 'demo-run',
    'state': 'succeeded',
    'events': [],
    'result': {
      'columns': ['ID', '标题', '作者'],
      'rows': [
        ['1', '示例文章', 'admin'],
      ],
    },
  };
}

class ExpiredHub extends FakeHub {
  @override
  Future<Map<String, dynamic>> create(
    String executor,
    String key,
    Map<String, dynamic> definition,
    Map<String, dynamic> inputs, {
    String? retryOf,
  }) async => {'id': 'expired-run', 'state': 'queued', 'events': []};

  @override
  Future<Map<String, dynamic>> run(String id) async => {
    'id': id,
    'state': 'failed',
    'events': [
      {'seq': 1, 'kind': 'failed'},
    ],
    'error': 'queue expired',
  };
}

void main() {
  test('idle polling reconciles a queued run expired by Hub', () async {
    final session = WorkflowSession(executorId: 'expiry-test');
    await session.connect(ExpiredHub());
    await session.submit();
    expect(session.state, 'failed');
    expect(session.busy, isFalse);
    session.dispose();
  });
  testWidgets('schema inputs and shared table work at 360dp with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = WorkflowSession(executorId: 'test');
    await session.connect(FakeHub());
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.4)),
          child: child!,
        ),
        home: Scaffold(body: WorkflowPage(session: session)),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('workflow-input-1-query')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('workflow-input-1-query')),
      'admin',
    );
    await tester.pump();
    expect(session.inputs['query'], 'admin');
    await tester.runAsync(session.submit);
    await tester.pumpAndSettle();
    expect(find.byType(ScrollTable), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    session.dispose();
    await tester.pump(const Duration(seconds: 1));
  });
}
