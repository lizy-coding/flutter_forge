import 'dart:convert';

import '../../domain/gcode_line_record.dart';
import 'gcode_line_reader.dart';

class StringGcodeLineReader implements GcodeLineReader {
  const StringGcodeLineReader(this.source);

  final String source;

  @override
  Stream<GcodeLineRecord> readLines() async* {
    var lineNumber = 0;
    var start = 0;
    for (final line in LineSplitter.split(source)) {
      lineNumber++;
      yield GcodeLineRecord(
        lineNumber: lineNumber,
        rawLine: line,
        byteOffset: start,
      );
      start += line.length;
      if (start < source.length && source.codeUnitAt(start) == 13) start++;
      if (start < source.length && source.codeUnitAt(start) == 10) start++;
    }
  }
}
