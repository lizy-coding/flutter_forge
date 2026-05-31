import '../data/readers/gcode_line_reader.dart';
import '../domain/gcode_load_snapshot.dart';
import '../domain/gcode_load_stage.dart';
import '../domain/parsed_gcode_line.dart';
import '../models/gcode_command.dart';
import '../models/toolpath_segment.dart';
import '../parser/gcode_parse_result.dart';
import '../parser/gcode_parser.dart';
import '../services/toolpath_builder.dart';

class GcodeReadlineOptions {
  const GcodeReadlineOptions({
    this.snapshotBatchSize = 200,
  });

  final int snapshotBatchSize;
}

class GcodeReadlinePipeline {
  GcodeReadlinePipeline({
    GcodeParser? parser,
    IncrementalToolpathBuilder? toolpathBuilder,
    this.options = const GcodeReadlineOptions(),
  })  : _parser = parser ?? GcodeParser(),
        _toolpathBuilder = toolpathBuilder ?? IncrementalToolpathBuilder();

  final GcodeParser _parser;
  final IncrementalToolpathBuilder _toolpathBuilder;
  final GcodeReadlineOptions options;

  Stream<GcodeLoadSnapshot> load(GcodeLineReader reader) async* {
    final commands = <GcodeCommand>[];
    final errors = <GcodeParseError>[];
    final segments = <ToolpathSegment>[];
    var linesRead = 0;
    var changedSinceSnapshot = 0;

    _toolpathBuilder.reset();

    yield const GcodeLoadSnapshot(
      stage: GcodeLoadStage.reading,
      commands: [],
      errors: [],
      segments: [],
      linesRead: 0,
      message: '开始逐行读取',
    );

    try {
      await for (final record in reader.readLines()) {
        linesRead = record.lineNumber;
        final parsed = _parser.parseRecord(record);

        switch (parsed.kind) {
          case ParsedGcodeLineKind.command:
            final command = parsed.command!;
            commands.add(command);
            final segment = _toolpathBuilder.accept(command);
            if (segment != null) {
              segments.add(segment);
            }
          case ParsedGcodeLineKind.error:
            errors.add(parsed.error!);
          case ParsedGcodeLineKind.skipped:
            break;
        }

        changedSinceSnapshot++;
        if (changedSinceSnapshot >= options.snapshotBatchSize) {
          changedSinceSnapshot = 0;
          yield _snapshot(
            stage: GcodeLoadStage.parsing,
            commands: commands,
            errors: errors,
            segments: segments,
            linesRead: linesRead,
            message: '已读取 $linesRead 行',
          );
        }
      }

      yield _snapshot(
        stage: GcodeLoadStage.ready,
        commands: commands,
        errors: errors,
        segments: segments,
        linesRead: linesRead,
        message: '逐行读取完成: $linesRead 行, '
            '${commands.length} 条指令, ${errors.length} 个错误, '
            '${segments.length} 条轨迹段',
      );
    } catch (error) {
      yield _snapshot(
        stage: GcodeLoadStage.failed,
        commands: commands,
        errors: errors,
        segments: segments,
        linesRead: linesRead,
        message: '读取失败: $error',
      );
    }
  }

  GcodeLoadSnapshot _snapshot({
    required GcodeLoadStage stage,
    required List<GcodeCommand> commands,
    required List<GcodeParseError> errors,
    required List<ToolpathSegment> segments,
    required int linesRead,
    required String message,
  }) {
    return GcodeLoadSnapshot(
      stage: stage,
      commands: List.unmodifiable(commands),
      errors: List.unmodifiable(errors),
      segments: List.unmodifiable(segments),
      linesRead: linesRead,
      message: message,
    );
  }
}
