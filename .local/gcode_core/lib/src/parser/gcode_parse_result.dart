import '../models/gcode_command.dart';

class GcodeParseError {
  const GcodeParseError({
    required this.lineNumber,
    required this.rawLine,
    required this.message,
  });

  final int lineNumber;
  final String rawLine;
  final String message;

  @override
  String toString() => 'Line $lineNumber: $message (raw: "$rawLine")';
}

class GcodeParseResult {
  const GcodeParseResult({
    required this.commands,
    required this.errors,
  });

  final List<GcodeCommand> commands;
  final List<GcodeParseError> errors;

  bool get hasErrors => errors.isNotEmpty;
}
