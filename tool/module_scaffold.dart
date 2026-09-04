import 'dart:convert';
import 'dart:io';

const _categories = {'basic', 'async', 'state', 'ui', 'popupTable', 'platform'};
const _difficulties = {'beginner', 'intermediate', 'advanced'};
const _platforms = {'android', 'iOS', 'macOS', 'windows', 'linux', 'fuchsia'};

Future<void> main(List<String> args) async {
  try {
    final options = _parse(args);
    if (options.containsKey('help')) {
      stdout.write(_usage);
      return;
    }
    final spec = _spec(options);
    final files = _files(spec);
    final output = Directory(
      options['output'] ?? 'build/module_scaffold/${spec['name']}',
    );

    if (options['apply'] != 'true') {
      stdout.writeln(
        jsonEncode({
          'mode': 'preview',
          'output': output.path,
          'files': files.keys.toList(),
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
      final file = File('${output.path}/${entry.key}')
        ..createSync(recursive: true);
      file.writeAsStringSync(entry.value);
    }
    stdout.writeln(
      jsonEncode({
        'mode': 'applied',
        'output': output.path,
        'files': files.keys.toList(),
      }),
    );
  } on ArgumentError catch (error) {
    stderr.writeln('module_scaffold: ${error.message}');
    stderr.writeln(_usage);
    exitCode = 64;
  }
}

Map<String, String> _parse(List<String> args) {
  final result = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--help' || arg == '-h') {
      result['help'] = 'true';
    } else if (arg == '--apply' || arg == '--force') {
      result[arg.substring(2)] = 'true';
    } else if (arg.startsWith('--') && i + 1 < args.length) {
      result[arg.substring(2)] = args[++i];
    } else {
      throw ArgumentError('unknown or incomplete argument: $arg');
    }
  }
  return result;
}

Map<String, String> _spec(Map<String, String> options) {
  String required(String name) {
    final value = options[name];
    if (value == null || value.trim().isEmpty) {
      throw ArgumentError('--$name is required');
    }
    return value.trim();
  }

  final category = required('category');
  final name = required('name');
  final title = required('title');
  final subtitle = required('subtitle');
  final difficulty = options['difficulty'] ?? 'beginner';
  final minutes = int.tryParse(options['minutes'] ?? '15');
  if (!_categories.contains(category))
    throw ArgumentError('invalid category: $category');
  if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name))
    throw ArgumentError('name must be snake_case: $name');
  if (!_difficulties.contains(difficulty))
    throw ArgumentError('invalid difficulty: $difficulty');
  if (minutes == null || minutes <= 0)
    throw ArgumentError('minutes must be a positive integer');
  final platforms = (options['platforms'] ?? '')
      .split(',')
      .where((item) => item.isNotEmpty)
      .toSet();
  if (platforms.any((platform) => !_platforms.contains(platform)))
    throw ArgumentError('invalid platform in: $platforms');
  final concepts = (options['concepts'] ?? 'Flutter,实践')
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
  if (concepts.isEmpty) throw ArgumentError('concepts must not be empty');
  return {
    'category': category,
    'name': name,
    'title': title,
    'subtitle': subtitle,
    'difficulty': difficulty,
    'minutes': '$minutes',
    'concepts': jsonEncode(concepts),
    'platforms': jsonEncode(platforms.toList()),
  };
}

Map<String, String> _files(Map<String, String> spec) {
  final platforms = (jsonDecode(spec['platforms']!) as List).cast<String>();
  final concepts = (jsonDecode(spec['concepts']!) as List)
      .map((item) => "'$item'")
      .join(', ');
  final root = 'lib/modules/${spec['category']}/${spec['name']}';
  return {
    '$root/module_entry.dart':
        '''import 'package:flutter/material.dart';

import 'module_root.dart';

class ${_className(spec['name']!)}Entry extends StatelessWidget {
  const ${_className(spec['name']!)}Entry({super.key});

  @override
  Widget build(BuildContext context) => const ${_className(spec['name']!)}Page();
}
''',
    '$root/module_root.dart':
        '''import 'package:flutter/material.dart';
import 'package:flutter_study_learning/flutter_study_learning.dart';

class ${_className(spec['name']!)}Page extends StatelessWidget {
  const ${_className(spec['name']!)}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return const LearningScaffold(
      title: '${spec['title']}',
      interactiveDemo: _InteractiveDemo(),
      sections: [
        LearningObjectives(objectives: ['理解 ${spec['title']} 的核心机制']),
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
        child: Center(child: Text('在这里实现 ${spec['title']} 的交互演示')),
      );
}
''',
    '$root/AI_ANALYSIS.md': jsonEncode({
      'schema': 'vibecoding.harness.ai_analysis.v2',
      'mode': 'module_contract',
      'node': {
        'id': 'flutter_forge_app.modules.${spec['category']}.${spec['name']}',
        'kind': 'learning_module',
        'package': 'flutter_forge_app',
        'path': root.replaceFirst('lib/', ''),
        'status': 'pending',
      },
      'route': '/${spec['name']!.replaceAll('_', '-')}',
      'category': spec['category'],
      'entrypoints': ['module_entry.dart', 'module_root.dart'],
      'owns': ['module_entry', 'module_ui', 'module_docs'],
      'depends': ['flutter_study_learning', 'module_registry'],
      'children': [],
      'analysis_parent': 'lib/modules/AI_ANALYSIS.md',
      'contracts': {
        'no_natural_language': true,
        'index_only': true,
        'max_index_depth': 2,
        'doc_consumer': 'coding_agent',
        'doc_mode': 'machine_contract',
        'update_required_on_file_change': true,
        'import_direction_enforced': true,
      },
      'validation': ['flutter analyze', 'flutter test'],
    }),
    'module_spec.json': jsonEncode({...spec, 'supportedPlatforms': platforms}),
  };
}

String _className(String value) => value
    .split('_')
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join();

const _usage = '''Usage: dart run tool/module_scaffold.dart [options]

Required: --category --name --title --subtitle
Optional: --difficulty beginner|intermediate|advanced --minutes 15
          --concepts a,b,c --platforms android,iOS,macOS,windows
          --output path --apply --force

Default mode is preview. --apply writes the candidate files and never edits
the route table; route registration remains an Agent Hub frozen-task decision.
''';
