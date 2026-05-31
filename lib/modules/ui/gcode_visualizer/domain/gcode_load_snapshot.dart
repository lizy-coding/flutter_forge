import '../models/gcode_command.dart';
import '../models/toolpath_segment.dart';
import '../parser/gcode_parse_result.dart';
import 'gcode_load_stage.dart';

class GcodeLoadSnapshot {
  const GcodeLoadSnapshot({
    required this.stage,
    required this.commands,
    required this.errors,
    required this.segments,
    required this.linesRead,
    this.message = '',
    this.diagnosticMessage = '',
  });

  factory GcodeLoadSnapshot.empty() {
    return const GcodeLoadSnapshot(
      stage: GcodeLoadStage.idle,
      commands: [],
      errors: [],
      segments: [],
      linesRead: 0,
    );
  }

  final GcodeLoadStage stage;
  final List<GcodeCommand> commands;
  final List<GcodeParseError> errors;
  final List<ToolpathSegment> segments;
  final int linesRead;
  final String message;
  final String diagnosticMessage;

  GcodeParseResult toParseResult() {
    return GcodeParseResult(commands: commands, errors: errors);
  }
}
