import '../data/readers/file_gcode_line_reader.dart';
import 'gcode_time_estimator.dart';

/// Estimates a local GCode file without building or rendering a toolpath.
///
/// [path] accepts a native path, quoted path or file URI as supported by
/// [FileGcodeLineReader]. UTF-8 lines are processed once; memory usage does not
/// grow with valid source lines. [options] supplies axis calibration and optional
/// initial speeds. G0 travel is included by default.
///
/// Returns timing diagnostics for unsupported or invalid GCode. A complete
/// result exposes non-negative seconds; incomplete results expose null seconds.
/// Invalid options fail with [ArgumentError]. Missing files, invalid UTF-8 and
/// other read errors propagate through the Future; no partial result is returned.
/// The file subscription is released on completion or failure.
Future<GcodeTimeEstimate> estimateGcodeFileTime(
  String path, {
  GcodeTimeOptions options = const GcodeTimeOptions(),
}) =>
    estimateGcodeStreamTime(
      FileGcodeLineReader(path).readLines().map((record) => record.rawLine),
      options: options,
    );

/// Estimates a stream containing one GCode source line per event.
///
/// [lines] is subscribed to once and consumed until completion. Diagnostics use
/// one-based event numbers. [options] has the same units and defaults as
/// [estimateGcodeTime]. Source lines and geometry are not retained; diagnostics
/// are retained for invalid lines. An empty stream returns a complete zero result.
///
/// Invalid options fail with [ArgumentError]; stream errors propagate through
/// the Future and end its subscription, without returning a partial result.
/// The stream must complete for this Future to return; the caller owns any
/// upstream producer and its cancellation policy.
Future<GcodeTimeEstimate> estimateGcodeStreamTime(
  Stream<String> lines, {
  GcodeTimeOptions options = const GcodeTimeOptions(),
}) async {
  final estimator = GcodeTimeEstimator(options: options);
  await for (final line in lines) {
    estimator.append(line);
  }
  return estimator.snapshot;
}
