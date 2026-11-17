import '../core/gcode_bounds.dart';
import '../models/gcode_command.dart';
import '../models/toolpath_segment.dart';
import '../parser/gcode_parse_result.dart';
import 'gcode_load_stage.dart';
import '../services/gcode_time_estimator.dart';

class GcodeLoadSnapshot {
  const GcodeLoadSnapshot({
    required this.stage,
    required this.commands,
    required this.errors,
    required this.segments,
    required this.linesRead,
    this.message = '',
    this.diagnosticMessage = '',
    this.bounds,
    this.timeEstimate,
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
  final GcodeBounds? bounds;

  /// Timing of the source prefix; independent of the renderer parse subset.
  final GcodeTimeEstimate? timeEstimate;

  /// Full estimated seconds only after a successful, complete load.
  double? get estimatedSeconds =>
      stage == GcodeLoadStage.ready ? timeEstimate?.estimatedSeconds : null;

  GcodeParseResult toParseResult() {
    return GcodeParseResult(commands: commands, errors: errors);
  }
}
