import '../models/gcode_command.dart';
import '../parser/gcode_parse_result.dart';
import 'gcode_line_record.dart';

enum ParsedGcodeLineKind { command, error, skipped }

class ParsedGcodeLine {
  const ParsedGcodeLine._({
    required this.kind,
    required this.record,
    this.command,
    this.error,
  });

  factory ParsedGcodeLine.command(
    GcodeLineRecord record,
    GcodeCommand command,
  ) {
    return ParsedGcodeLine._(
      kind: ParsedGcodeLineKind.command,
      record: record,
      command: command,
    );
  }

  factory ParsedGcodeLine.error(
    GcodeLineRecord record,
    GcodeParseError error,
  ) {
    return ParsedGcodeLine._(
      kind: ParsedGcodeLineKind.error,
      record: record,
      error: error,
    );
  }

  factory ParsedGcodeLine.skipped(GcodeLineRecord record) {
    return ParsedGcodeLine._(
      kind: ParsedGcodeLineKind.skipped,
      record: record,
    );
  }

  final ParsedGcodeLineKind kind;
  final GcodeLineRecord record;
  final GcodeCommand? command;
  final GcodeParseError? error;

  bool get hasCommand => kind == ParsedGcodeLineKind.command;
  bool get hasError => kind == ParsedGcodeLineKind.error;
}
