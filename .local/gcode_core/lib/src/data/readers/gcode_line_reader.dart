import '../../domain/gcode_line_record.dart';

abstract interface class GcodeLineReader {
  Stream<GcodeLineRecord> readLines();
}
