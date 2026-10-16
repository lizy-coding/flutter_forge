import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final dart = Platform.environment['FORGE_DART_TEST_EXECUTABLE'] ?? 'dart';
  final temp = await Directory.systemTemp.createTemp(
    'flutterforge_scaffold_test_',
  );
  final script = File.fromUri(Platform.script.resolve('module_scaffold.dart'));
  final registry = File.fromUri(
    Platform.script.resolve('generate_agent_indexes.js'),
  );
  final registryBefore = registry.readAsStringSync();
  try {
    const title = '图形 \'单引号\' "双引号" \\路径 \$name\n第二行';
    const concepts = 'UV,颜色\'与"位置",\$value\\offset';
    final output = Directory.fromUri(temp.uri.resolve('candidate/'));
    final base = [
      '--category',
      'popup_table',
      '--name',
      'candidate_lesson',
      '--title',
      title,
      '--subtitle',
      '待补充的学习练习',
      '--concepts',
      concepts,
      '--output',
      output.path,
    ];
    Future<ProcessResult> run(List<String> args) =>
        Process.run(dart, ['run', script.path, ...args]);

    final preview = await run(base);
    _check(preview.exitCode == 0, 'preview failed: ${preview.stderr}');
    _check(!output.existsSync(), 'preview created output');
    final summary =
        jsonDecode(preview.stdout as String) as Map<String, dynamic>;
    final previewSpec = summary['spec'] as Map<String, dynamic>;
    _check(summary['registration'] is String, 'registration preview missing');
    _check(
      previewSpec['routeRegistration'] == 'explicit_review_required',
      'candidate must require registration review',
    );

    final applied = await run([...base, '--apply']);
    _check(applied.exitCode == 0, 'apply failed: ${applied.stderr}');
    final contractFile = File.fromUri(
      output.uri.resolve(
        'lib/modules/popup_table/candidate_lesson/AI_ANALYSIS.md',
      ),
    );
    final contract =
        jsonDecode(contractFile.readAsStringSync()) as Map<String, dynamic>;
    final node = contract['node'] as Map<String, dynamic>;
    _check(node['status'] == 'pending', 'candidate was admitted automatically');
    _check(contract['route'] == '/candidate-lesson', 'invalid route');
    _check(
      contract['analysis_parent'] == 'lib/modules/popup_table/AI_ANALYSIS.md',
      'incorrect parent contract',
    );
    final platform = contract['platform_support'] as Map<String, dynamic>;
    _check(
      jsonEncode(platform['target_platforms']) ==
          jsonEncode(['android', 'iOS', 'macOS', 'web', 'windows']),
      'incorrect target platform semantics',
    );
    _check(
      (platform['excluded_platforms'] as List).isEmpty,
      'normal entry closed',
    );
    final specFile = File.fromUri(output.uri.resolve('module_spec.json'));
    final spec =
        jsonDecode(specFile.readAsStringSync()) as Map<String, dynamic>;
    _check(
      jsonEncode(spec) == jsonEncode(previewSpec),
      'preview/apply spec differs',
    );
    final declaration = spec['declaration'] as Map<String, dynamic>;
    _check(declaration['title'] == title, 'title changed in candidate');
    _check(declaration['estimatedMinutes'] == 15, 'minutes must be numeric');
    _check(declaration['concepts'] is List, 'concepts must be an array');
    _check(
      !declaration.containsKey('supportedPlatforms'),
      'legacy declaration retained',
    );
    _check(
      File.fromUri(
        output.uri.resolve('module_registration.js.txt'),
      ).existsSync(),
      'reviewable registration fragment missing',
    );
    final parsed = await Process.run(dart, [
      'format',
      '--output=none',
      output.path,
    ]);
    _check(
      parsed.exitCode == 0,
      'generated Dart failed parsing: ${parsed.stderr}',
    );

    // Execute the emitted title literal to detect accidental interpolation or
    // escape changes, in addition to parsing all generated Flutter/test files.
    final page = File.fromUri(
      output.uri.resolve(
        'lib/modules/popup_table/candidate_lesson/module_root.dart',
      ),
    ).readAsLinesSync();
    final titleLine = page
        .firstWhere((line) => line.trim().startsWith('title:'))
        .trim();
    final literal = titleLine.substring('title: '.length, titleLine.length - 1);
    final literalTest = File.fromUri(temp.uri.resolve('literal_test.dart'));
    literalTest.writeAsStringSync(
      "import 'dart:convert'; import 'dart:io'; void main() { stdout.write(jsonEncode($literal)); }",
    );
    final roundTrip = await Process.run(dart, ['run', literalTest.path]);
    _check(roundTrip.exitCode == 0, 'emitted title literal did not execute');
    _check(
      jsonDecode(roundTrip.stdout as String) == title,
      'Dart title did not round trip',
    );

    final guard = await run([...base, '--apply']);
    _check(guard.exitCode == 64, 'existing output must require --force');
    final forced = await run([...base, '--apply', '--force']);
    _check(forced.exitCode == 0, 'force apply failed');
    final beforePreview = contractFile.readAsStringSync();
    final existingPreview = await run(base);
    _check(existingPreview.exitCode == 0, 'existing output preview failed');
    _check(
      contractFile.readAsStringSync() == beforePreview,
      'preview changed existing files',
    );

    for (final extra in [
      ['--platforms', 'android,web'],
      ['--supportedPlatforms', 'web'],
      ['--unknown', 'value'],
      ['--name', 'duplicate'],
      ['--optional-capabilities', 'unknown'],
      ['--optional-capabilities', 'file_selection'],
      ['--restriction-reason', 'deferred'],
      ['--restriction-sources', 'missing.md'],
      ['--minutes', '0'],
      ['--concepts', ','],
      ['--force'],
      ['--output'],
    ]) {
      final invalid = await run([...base, ...extra]);
      _check(invalid.exitCode == 64, 'invalid arguments accepted: $extra');
      _check((invalid.stdout as String).isEmpty, 'usage failure wrote stdout');
      _check(
        (invalid.stderr as String).contains('Usage:'),
        'usage failure omitted usage: $extra',
      );
    }
    _check(
      registry.readAsStringSync() == registryBefore,
      'scaffold edited registry',
    );
    stdout.writeln('module_scaffold_test: PASS');
  } finally {
    await temp.delete(recursive: true);
  }
}

void _check(bool condition, String message) {
  if (!condition) throw StateError(message);
}
