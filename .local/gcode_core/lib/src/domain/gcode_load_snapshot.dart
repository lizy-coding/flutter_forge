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
    this.previewLineLimit,
    int? commandCount,
    int? errorCount,
    int? segmentCount,
  })  : _commandCount = commandCount,
        _errorCount = errorCount,
        _segmentCount = segmentCount;

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

  /// The source-line cutoff of a frozen intermediate preview, or `null`.
  ///
  /// Commands, segments and bounds describe this same prefix. Terminal
  /// snapshots always contain complete data and have no preview cutoff.
  final int? previewLineLimit;
  final int? _commandCount;
  final int? _errorCount;
  final int? _segmentCount;

  /// The total command count, including commands omitted from the preview.
  int get commandCount => _commandCount ?? commands.length;

  /// The total parser error count, including errors omitted from the preview.
  int get errorCount => _errorCount ?? errors.length;

  /// The total segment count, including segments omitted from the preview.
  int get segmentCount => _segmentCount ?? segments.length;

  /// Timing of the source prefix; independent of the renderer parse subset.
  final GcodeTimeEstimate? timeEstimate;

  /// Full estimated seconds only after a successful, complete load.
  double? get estimatedSeconds =>
      stage == GcodeLoadStage.ready ? timeEstimate?.estimatedSeconds : null;

  GcodeParseResult toParseResult() {
    return GcodeParseResult(commands: commands, errors: errors);
  }
}
