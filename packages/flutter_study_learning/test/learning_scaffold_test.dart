import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_study_learning/flutter_study_learning.dart';

void main() {
  group('LearningObjectives', () {
    testWidgets('renders all objectives', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LearningObjectives(
                objectives: ['目标一', '目标二', '目标三'],
              ),
            ),
          ),
        ),
      );

      expect(find.text('目标一'), findsOneWidget);
      expect(find.text('目标二'), findsOneWidget);
      expect(find.text('目标三'), findsOneWidget);
    });
  });

  group('ConceptChips', () {
    testWidgets('renders all concept chips', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ConceptChips(concepts: ['Isolate', 'SendPort', 'Future']),
            ),
          ),
        ),
      );

      expect(find.text('Isolate'), findsOneWidget);
      expect(find.text('SendPort'), findsOneWidget);
      expect(find.text('Future'), findsOneWidget);
    });
  });

  group('CodeSnippetCard', () {
    testWidgets('renders title and code', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CodeSnippetCard(
                title: '示例代码',
                code: 'print("hello");',
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('示例代码'), findsOneWidget);
      expect(find.text('print("hello");'), findsOneWidget);
    });

    testWidgets('renders explanation when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CodeSnippetCard(
                title: '示例',
                code: 'int x = 1;',
                explanation: '声明一个整数变量',
              ),
            ),
          ),
        ),
      );

      expect(find.text('声明一个整数变量'), findsOneWidget);
    });
  });

  group('StateLogView', () {
    testWidgets('renders log entries', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StateLogView(logs: ['log 1', 'log 2', 'log 3']),
            ),
          ),
        ),
      );

      expect(find.text('log 1'), findsOneWidget);
      expect(find.text('log 2'), findsOneWidget);
      expect(find.text('log 3'), findsOneWidget);
    });
  });

  group('CommonPitfalls', () {
    testWidgets('renders all pitfalls', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CommonPitfalls(pitfalls: ['误区一', '误区二']),
            ),
          ),
        ),
      );

      expect(find.text('误区一'), findsOneWidget);
      expect(find.text('误区二'), findsOneWidget);
    });
  });

  group('ExerciseCard', () {
    testWidgets('renders task text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ExerciseCard(task: '完成一个练习任务'),
            ),
          ),
        ),
      );

      expect(find.text('完成一个练习任务'), findsOneWidget);
    });

    testWidgets('renders hint when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ExerciseCard(
                task: '完成一个任务',
                hint: '使用Future.delayed',
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('使用Future.delayed'), findsOneWidget);
    });
  });

  group('LearningScaffold', () {
    testWidgets('renders title and sections', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LearningScaffold(
            title: '测试页面',
            sections: [
              const Text('区块一'),
              const Text('区块二'),
            ],
          ),
        ),
      );

      expect(find.text('测试页面'), findsOneWidget);
      expect(find.text('区块一'), findsOneWidget);
      expect(find.text('区块二'), findsOneWidget);
    });

    testWidgets('renders interactive demo when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LearningScaffold(
            title: '测试',
            sections: const [],
            interactiveDemo: const Text('交互演示区域'),
          ),
        ),
      );

      expect(find.text('交互演示区域'), findsOneWidget);
    });

    testWidgets('renders floating action button when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LearningScaffold(
            title: '测试',
            sections: const [],
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
