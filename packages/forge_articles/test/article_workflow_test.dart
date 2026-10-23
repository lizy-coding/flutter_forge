import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_articles/forge_articles.dart';

const definition = <String, dynamic>{
  'schema': 'forge.workflow.v1',
  'id': 'articles.explore',
  'version': 1,
  'steps': [
    {'id': 'fetch', 'capability': 'articles.fetch', 'version': 1},
    {'id': 'organize', 'capability': 'articles.organize', 'version': 1},
  ],
};
Map<String, dynamic> parameters() => {
  'page': 1,
  'pageSize': 10,
  'query': 'admin',
  'delayMs': 0,
  'simulateFailure': false,
};

void main() {
  test(
    'pure workflow executes Dio and deterministic transform without a widget',
    () async {
      final events = <String>[];
      final result = await ArticleWorkflowRunner().run(
        definition: definition,
        inputs: parameters(),
        cancelToken: CancelToken(),
        emit: (kind, step) async => events.add('$step:$kind'),
      );
      expect(events, [
        'fetch:step_started',
        'fetch:step_succeeded',
        'organize:step_started',
        'organize:step_succeeded',
      ]);
      final rows = result['rows'] as List;
      expect(rows.length, 5);
      expect(rows.first, ['2', '文章标题 2', 'admin']);
    },
  );

  test('cancellation stops fetch before transform', () async {
    final token = CancelToken();
    final events = <String>[];
    final future = ArticleWorkflowRunner().run(
      definition: definition,
      inputs: {...parameters(), 'delayMs': 500},
      cancelToken: token,
      emit: (kind, step) async {
        events.add(step);
      },
    );
    token.cancel('test');
    await expectLater(future, throwsA(isA<DioException>()));
    expect(events, isNot(contains('organize')));
  });

  test('failure and unsupported definitions are real errors', () async {
    Future<void> emit(String kind, String step) async {}
    await expectLater(
      ArticleWorkflowRunner().run(
        definition: definition,
        inputs: {...parameters(), 'simulateFailure': true},
        cancelToken: CancelToken(),
        emit: emit,
      ),
      throwsA(isA<DioException>()),
    );
    await expectLater(
      ArticleWorkflowRunner().run(
        definition: {...definition, 'version': 2},
        inputs: parameters(),
        cancelToken: CancelToken(),
        emit: emit,
      ),
      throwsFormatException,
    );
    await expectLater(
      ArticleWorkflowRunner().run(
        definition: definition,
        inputs: {...parameters(), 'url': 'https://example.invalid'},
        cancelToken: CancelToken(),
        emit: emit,
      ),
      throwsFormatException,
    );
  });
}
