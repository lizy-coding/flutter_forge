import '../../domain/gcode_line_record.dart';
import 'gcode_line_reader.dart';

class StringGcodeLineReader implements GcodeLineReader {
  const StringGcodeLineReader(this.source);

  final String source;

  @override
  Stream<GcodeLineRecord> readLines() async* {
    var lineNumber = 0;
    var byteOffset = 0;
    var start = 0;

    for (var i = 0; i < source.length; i++) {
      final codeUnit = source.codeUnitAt(i);
      if (codeUnit != 10) continue;

      lineNumber++;
      final end = i > start && source.codeUnitAt(i - 1) == 13 ? i - 1 : i;
      yield GcodeLineRecord(
        lineNumber: lineNumber,
        rawLine: source.substring(start, end),
        byteOffset: byteOffset,
      );
      byteOffset = i + 1;
      start = i + 1;
    }

    if (start < source.length || source.isEmpty) {
      lineNumber++;
      yield GcodeLineRecord(
        lineNumber: lineNumber,
        rawLine: source.substring(start),
        byteOffset: byteOffset,
      );
    }
  }
}
