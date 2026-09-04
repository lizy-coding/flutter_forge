import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final temp = await Directory.systemTemp.createTemp(
    'flutterforge_scaffold_test_',
  );
  try {
    final output = Directory('${temp.path}/module');
    final args = [
      'run',
      'tool/module_scaffold.dart',
      '--category',
      'async',
      '--name',
      'cancellation_timeout',
      '--title',
      '任务取消与超时',
      '--subtitle',
      '学习异步任务控制',
      '--concepts',
      'Future,取消,超时',
      '--platforms',
      'android,macOS',
      '--output',
      output.path,
      '--apply',
    ];

    final result = await Process.run(Platform.resolvedExecutable, args);
    _check(
      result.exitCode == 0,
      'apply exited ${result.exitCode}: ${result.stderr}',
    );
    final files = [
      'lib/modules/async/cancellation_timeout/module_entry.dart',
      'lib/modules/async/cancellation_timeout/module_root.dart',
      'lib/modules/async/cancellation_timeout/AI_ANALYSIS.md',
      'module_spec.json',
    ];
    for (final relative in files) {
      _check(
        File('${output.path}/$relative').existsSync(),
        'missing $relative',
      );
    }
    final contract =
        jsonDecode(
              File(
                '${output.path}/lib/modules/async/cancellation_timeout/AI_ANALYSIS.md',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    _check(contract['mode'] == 'module_contract', 'invalid module contract');
    _check(contract['route'] == '/cancellation-timeout', 'invalid route');
    _check(
      File(
        '${output.path}/lib/modules/async/cancellation_timeout/module_root.dart',
      ).readAsStringSync().contains('LearningScaffold'),
      'teaching scaffold missing',
    );

    final previewOutput = Directory('${temp.path}/preview');
    final previewArgs = args
        .where((arg) => arg != '--apply')
        .map((arg) => arg == output.path ? previewOutput.path : arg)
        .toList();
    final preview = await Process.run(Platform.resolvedExecutable, previewArgs);
    _check(preview.exitCode == 0, 'preview exited ${preview.exitCode}');
    _check(
      !Directory('${previewOutput.path}/lib').existsSync(),
      'preview wrote files',
    );
    stdout.writeln('module_scaffold_test: PASS');
  } finally {
    await temp.delete(recursive: true);
  }
}

void _check(bool condition, String message) {
  if (!condition) throw StateError(message);
}
