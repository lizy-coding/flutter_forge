import '../models/gcode_command.dart';
import '../domain/gcode_line_record.dart';
import '../domain/parsed_gcode_line.dart';
import 'gcode_parse_result.dart';

class GcodeParser {
  static const _supportedCodes = {'G0', 'G00', 'G1', 'G01'};
  static final _paramPattern = RegExp(r'^([A-Za-z])(-?(?:\d+\.?\d*|\.\d+))$');

  GcodeParseResult parse(String source) {
    final commands = <GcodeCommand>[];
    final errors = <GcodeParseError>[];
    final lines = source.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final lineNumber = i + 1;
      final rawLine = lines[i].trim();

      if (rawLine.isEmpty) continue;

      final result = parseLine(rawLine, lineNumber);

      result.when(
        command: (cmd) => commands.add(cmd),
        error: (err) => errors.add(err),
        skipped: () {},
      );
    }

    return GcodeParseResult(commands: commands, errors: errors);
  }

  ParsedGcodeLine parseRecord(GcodeLineRecord record) {
    final result = parseLine(record.rawLine.trim(), record.lineNumber);
    return result.when(
      command: (cmd) => ParsedGcodeLine.command(record, cmd),
      error: (err) => ParsedGcodeLine.error(record, err),
      skipped: () => ParsedGcodeLine.skipped(record),
    );
  }

  LineParseResult parseLine(String rawLine, int lineNumber) {
    var line = rawLine;

    line = _removeParenthesesComments(line);

    final comment = _extractSemicolonComment(line);
    line = comment != null
        ? line.substring(0, line.indexOf(';')).trim()
        : line.trim();

    if (line.isEmpty) {
      return LineParseResult.skipped();
    }

    final tokens = _tokenize(line);
    if (tokens.isEmpty) {
      return LineParseResult.skipped();
    }

    final commandCode = tokens[0].toUpperCase();

    final normalized = _normalizeCode(commandCode);
    if (!_supportedCodes.contains(normalized)) {
      return LineParseResult.error(
        GcodeParseError(
          lineNumber: lineNumber,
          rawLine: rawLine,
          message: 'Unsupported code: $commandCode',
        ),
      );
    }

    final params = <String, double>{};
    for (var i = 1; i < tokens.length; i++) {
      final token = tokens[i];
      final match = _paramPattern.firstMatch(token);
      if (match == null) {
        return LineParseResult.error(
          GcodeParseError(
            lineNumber: lineNumber,
            rawLine: rawLine,
            message: 'Malformed parameter: $token',
          ),
        );
      }
      final key = match.group(1)!.toUpperCase();
      final valueStr = match.group(2);
      if (valueStr == null) {
        return LineParseResult.error(
          GcodeParseError(
            lineNumber: lineNumber,
            rawLine: rawLine,
            message: 'Missing numeric value in: $token',
          ),
        );
      }
      final value = double.tryParse(valueStr);
      if (value == null) {
        return LineParseResult.error(
          GcodeParseError(
            lineNumber: lineNumber,
            rawLine: rawLine,
            message: 'Invalid numeric value: $token',
          ),
        );
      }
      params[key] = value;
    }

    return LineParseResult.command(
      GcodeCommand(
        lineNumber: lineNumber,
        rawLine: rawLine,
        code: normalized,
        params: params,
        comment: comment ?? '',
      ),
    );
  }

  String _removeParenthesesComments(String line) {
    final result = StringBuffer();
    var inComment = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '(') {
        inComment = true;
      } else if (ch == ')') {
        inComment = false;
      } else if (!inComment) {
        result.write(ch);
      }
    }
    return result.toString();
  }

  String? _extractSemicolonComment(String line) {
    final index = line.indexOf(';');
    if (index == -1) return null;
    return line.substring(index + 1).trim();
  }

  List<String> _tokenize(String line) {
    final tokens = <String>[];
    final buffer = StringBuffer();
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == ' ' || ch == '\t') {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
      } else {
        buffer.write(ch);
      }
    }
    if (buffer.isNotEmpty) {
      tokens.add(buffer.toString());
    }
    return tokens;
  }

  String _normalizeCode(String code) {
    return switch (code) {
      'G0' || 'G00' => 'G0',
      'G1' || 'G01' => 'G1',
      _ => code,
    };
  }
}

sealed class LineParseResult {
  const LineParseResult();

  factory LineParseResult.command(GcodeCommand cmd) => _CommandResult(cmd);
  factory LineParseResult.error(GcodeParseError err) => _ErrorResult(err);
  factory LineParseResult.skipped() => const _SkippedResult();

  T when<T>({
    required T Function(GcodeCommand) command,
    required T Function(GcodeParseError) error,
    required T Function() skipped,
  }) {
    return switch (this) {
      _CommandResult(:final cmd) => command(cmd),
      _ErrorResult(:final err) => error(err),
      _SkippedResult() => skipped(),
    };
  }
}

class _CommandResult extends LineParseResult {
  const _CommandResult(this.cmd);
  final GcodeCommand cmd;
}

class _ErrorResult extends LineParseResult {
  const _ErrorResult(this.err);
  final GcodeParseError err;
}

class _SkippedResult extends LineParseResult {
  const _SkippedResult();
}
