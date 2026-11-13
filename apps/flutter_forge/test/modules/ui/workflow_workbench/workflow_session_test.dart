import 'package:flutter_forge_app/modules/ui/workflow_workbench/workflow_session.dart';
import 'package:flutter_forge_app/shared/workflows/hub_client.dart';
import 'package:flutter_test/flutter_test.dart';

const flow = <String, dynamic>{
  'id': 'articles.explore',
  'version': 1,
  'inputSchema': {
    'properties': {
      'query': {'type': 'string', 'default': ''},
      'page': {'type': 'integer', 'default': 1},
    },
  },
};

class StubHub extends WorkflowHubClient {
  StubHub({this.workflowsPayload})
    : super(endpoint: Uri.parse('http://127.0.0.1:8768'), token: 'test');

  final Map<String, dynamic>? workflowsPayload;
  bool closed = false;

  @override
  Future<Map<String, dynamic>> workflows() async =>
      workflowsPayload ??
      {
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
  void close() {
    closed = true;
    super.close();
  }
}

void main() {
  test('connect stores the definition and schema input defaults', () async {
    final session = WorkflowSession();
    addTearDown(session.dispose);
    await session.connect(StubHub());

    expect(session.connected, isTrue);
    expect(session.error, isNull);
    expect(session.definition?['id'], 'articles.explore');
    expect(session.inputs, {'query': '', 'page': 1});
    expect(session.state, 'idle');
    expect(session.busy, isFalse);
  });

  test('connect rejects hubs without the supported flow version', () async {
    final session = WorkflowSession();
    addTearDown(session.dispose);
    final hub = StubHub(workflowsPayload: {'workflows': []});
    await session.connect(hub);

    expect(session.connected, isFalse);
    expect(session.error, contains('文章流程版本'));
    expect(hub.closed, isTrue, reason: '被拒绝的连接必须关闭 hub');
  });

  test('dispose stops polling and disconnects cleanly', () async {
    final session = WorkflowSession();
    final hub = StubHub();
    await session.connect(hub);
    expect(session.connected, isTrue);
    session.dispose();
    expect(session.connected, isTrue, reason: 'dispose 不清引用，只停轮询');
  });
}
