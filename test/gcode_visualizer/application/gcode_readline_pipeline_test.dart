import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:main_app/modules/ui/gcode_visualizer/application/gcode_readline_pipeline.dart';
import 'package:main_app/modules/ui/gcode_visualizer/data/readers/file_gcode_line_reader.dart';
import 'package:main_app/modules/ui/gcode_visualizer/data/readers/string_gcode_line_reader.dart';
import 'package:main_app/modules/ui/gcode_visualizer/domain/gcode_load_stage.dart';

void main() {
  group('GcodeReadlinePipeline', () {
    test('reads string source line by line and builds segments', () async {
      const source = '''
G0 X0 Y0
G1 X10 Y0
G2 X10 Y10
G1 X10 Y10
''';

      final pipeline = GcodeReadlinePipeline(
        options: const GcodeReadlineOptions(snapshotBatchSize: 2),
      );
      final snapshots =
          await pipeline.load(const StringGcodeLineReader(source)).toList();

      expect(snapshots.first.stage, GcodeLoadStage.reading);
      expect(snapshots.last.stage, GcodeLoadStage.ready);
      expect(snapshots.last.linesRead, 4);
      expect(snapshots.last.commands, hasLength(3));
      expect(snapshots.last.errors, hasLength(1));
      expect(snapshots.last.segments, hasLength(2));
      expect(snapshots.last.segments.last.end.x, 10);
      expect(snapshots.last.segments.last.end.y, 10);
    });

    test('reads gcode from file path', () async {
      final file = File('${Directory.systemTemp.path}/gcode_readline_test.nc');
      await file.writeAsString('G0 X0 Y0\nG1 X5 Y5\n');
      addTearDown(() {
        if (file.existsSync()) {
          file.deleteSync();
        }
      });

      final pipeline = GcodeReadlinePipeline();
      final snapshots =
          await pipeline.load(FileGcodeLineReader(file.path)).toList();

      expect(snapshots.last.stage, GcodeLoadStage.ready);
      expect(snapshots.last.linesRead, 2);
      expect(snapshots.last.commands, hasLength(2));
      expect(snapshots.last.segments, hasLength(1));
      expect(snapshots.last.segments.single.end.x, 5);
      expect(snapshots.last.segments.single.end.y, 5);
    });

    test('normalizes copied file paths before opening', () async {
      final file =
          File('${Directory.systemTemp.path}/gcode readline copied path.nc');
      await file.writeAsString('G0 X0 Y0\nG1 X3 Y4\n');
      addTearDown(() {
        if (file.existsSync()) {
          file.deleteSync();
        }
      });

      final pipeline = GcodeReadlinePipeline();
      final quotedPathSnapshots =
          await pipeline.load(FileGcodeLineReader('"${file.path}"')).toList();
      final fileUriSnapshots = await pipeline
          .load(FileGcodeLineReader(file.uri.toString()))
          .toList();
      final escapedPathSnapshots = await pipeline
          .load(FileGcodeLineReader(file.path.replaceAll(' ', r'\ ')))
          .toList();

      expect(quotedPathSnapshots.last.stage, GcodeLoadStage.ready);
      expect(fileUriSnapshots.last.stage, GcodeLoadStage.ready);
      expect(escapedPathSnapshots.last.stage, GcodeLoadStage.ready);
      expect(escapedPathSnapshots.last.segments.single.end.x, 3);
      expect(escapedPathSnapshots.last.segments.single.end.y, 4);
    });
  });
}
