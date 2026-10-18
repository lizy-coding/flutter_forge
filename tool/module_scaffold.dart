import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  try {
    final options = _parse(args);
    if (options.containsKey('help')) {
      stdout.write(_usage);
      return;
    }
    final candidate = await _candidate(options);
    final spec = candidate['spec'] as Map<String, dynamic>;
    final declaration = spec['declaration'] as Map<String, dynamic>;
    final files = _files(candidate);
    final output = Directory(
      options['output'] ?? 'build/module_scaffold/${declaration['id']}',
    );

    if (options['apply'] != 'true') {
      stdout.writeln(
        jsonEncode({
          'mode': 'preview',
          'output': output.path,
          'files': files.keys.toList(),
          'spec': spec,
          'registration': candidate['registration'],
        }),
      );
      return;
    }
    if (output.existsSync() && options['force'] != 'true') {
      throw ArgumentError(
        'output exists; pass --force to replace it: ${output.path}',
      );
    }
    for (final entry in files.entries) {
      final file = File.fromUri(
        output.absolute.uri.resolveUri(Uri(path: entry.key)),
      )..createSync(recursive: true);
      file.writeAsStringSync(entry.value);
    }
    stdout.writeln(
      jsonEncode({
        'mode': 'applied',
        'output': output.path,
        'files': files.keys.toList(),
        'routeRegistration': spec['routeRegistration'],
      }),
    );
  } on ArgumentError catch (error) {
    stderr.writeln('module_scaffold: ${error.message}');
    stderr.writeln(_usage);
    exitCode = 64;
  } on ProcessException catch (error) {
    stderr.writeln('module_scaffold: Node.js is required: ${error.message}');
    exitCode = 78;
  }
}

Map<String, String> _parse(List<String> args) {
  final result = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    final key = arg == '-h' ? 'help' : arg.replaceFirst(RegExp(r'^--'), '');
    if ((!arg.startsWith('--') && arg != '-h') || result.containsKey(key)) {
      throw ArgumentError('unknown or duplicate argument: $arg');
    }
    if (key == 'help' || key == 'apply' || key == 'force') {
      result[key] = 'true';
    } else if (i + 1 < args.length && !args[i + 1].startsWith('--')) {
      result[key] = args[++i];
    } else {
      throw ArgumentError('incomplete argument: $arg');
    }
  }
  if (result.containsKey('help') && result.length != 1) {
    throw ArgumentError('--help must be used by itself');
  }
  if (result.containsKey('force') && !result.containsKey('apply')) {
    throw ArgumentError('--force requires --apply');
  }
  return result;
}

Future<Map<String, dynamic>> _candidate(Map<String, String> options) async {
  final helper = File.fromUri(
    Platform.script.resolve('agent_indexes/module_spec.js'),
  );
  final process = await Process.start('node', [helper.path]);
  final output = process.stdout.transform(utf8.decoder).join();
  final errors = process.stderr.transform(utf8.decoder).join();
  process.stdin.writeln(jsonEncode(options));
  await process.stdin.close();
  final status = await process.exitCode;
  final error = await errors;
  if (status != 0) throw ArgumentError(error.trim());
  return jsonDecode(await output) as Map<String, dynamic>;
}

Map<String, String> _files(Map<String, dynamic> candidate) {
  final spec = candidate['spec'] as Map<String, dynamic>;
  final declaration = spec['declaration'] as Map<String, dynamic>;
  final category = declaration['category'] as String;
  final id = declaration['id'] as String;
  final title = declaration['title'] as String;
  final entryClass = declaration['entry'] as String;
  final pageClass = '${entryClass.substring(0, entryClass.length - 5)}Page';
  final concepts = (declaration['concepts'] as List)
      .cast<String>()
      .map(_dartLiteral)
      .join(', ');
  final root = 'lib/modules/$category/$id';
  final testRoot = 'test/modules/$category/$id';
  return {
    '$root/module_entry.dart':
        '''import 'package:flutter/material.dart';

import 'module_root.dart';

class $entryClass extends StatelessWidget {
  const $entryClass({super.key});

  @override
  Widget build(BuildContext context) => const $pageClass();
}
''',
    '$root/module_root.dart':
        '''import 'package:flutter/material.dart';
import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';

class $pageClass extends StatelessWidget {
  const $pageClass({super.key});

  @override
  Widget build(BuildContext context) {
    return const LearningScaffold(
      title: ${_dartLiteral(title)},
      interactiveDemo: _InteractiveDemo(),
      sections: [
        LearningObjectives(objectives: [${_dartLiteral('理解 $title 的核心机制')}]),
        ConceptChips(concepts: [$concepts]),
        ExerciseCard(task: '补充一个可验证的交互练习。'),
      ],
    );
  }
}

class _InteractiveDemo extends StatelessWidget {
  const _InteractiveDemo();

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 160,
        child: Center(child: Text(${_dartLiteral('在这里实现 $title 的交互演示')})),
      );
}
''',
    '$testRoot/${id}_test.dart':
        '''import 'package:flutter/material.dart';
import 'package:flutter_forge_app/modules/$category/$id/module_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(${_dartLiteral('$title renders in a compact viewport')}, (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: $entryClass()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
''',
    '$root/AI_ANALYSIS.md':
        '${const JsonEncoder.withIndent('  ').convert(candidate['contract'])}\n',
    'module_spec.json': '${const JsonEncoder.withIndent('  ').convert(spec)}\n',
    'module_registration.js.txt': candidate['registration'] as String,
  };
}

String _dartLiteral(String value) => jsonEncode(value).replaceAll(r'$', r'\$');

const _usage = '''Usage: dart run tool/module_scaffold.dart [options]

Required: --category --name --title --subtitle
Optional: --difficulty beginner|intermediate|advanced --minutes 15
          --concepts a,b,c --depends package_a,package_b
          --optional-capabilities capability_a,capability_b
          --restriction-reason REASON --restriction-sources path_a,path_b
          --output path --apply --force

Requires Node.js. Default mode previews the pending declaration without writes.
Platform policy comes from shared capability rules; --platforms is not accepted.
An entry restriction closes all target entries and requires existing sources.
--apply writes candidate files and a reviewable registration fragment. Review
the declaration explicitly before adding it to tool/generate_agent_indexes.js.
''';
