import 'dart:convert';
import 'dart:io';

import '../../domain/gcode_line_record.dart';
import 'gcode_line_reader.dart';

class FileGcodeLineReader implements GcodeLineReader {
  const FileGcodeLineReader(this.path);

  final String path;

  @override
  Stream<GcodeLineRecord> readLines() async* {
    final file = File(path);
    var lineNumber = 0;
    var byteOffset = 0;

    await for (final line in file
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      lineNumber++;
      yield GcodeLineRecord(
        lineNumber: lineNumber,
        rawLine: line,
        byteOffset: byteOffset,
      );
      byteOffset += utf8.encode(line).length + 1;
    }
  }
}
