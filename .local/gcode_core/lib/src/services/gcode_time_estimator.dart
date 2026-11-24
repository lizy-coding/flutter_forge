import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

/// Calibration and initial feed rates for the BSL demo timing model.
///
/// This model includes rapid moves, marking, point exposure, jump settling,
/// explicit waits and axis moves. It does not model acceleration, homing or
/// arbitrary M-command delays, and is not a measured device duration.
class GcodeTimeOptions {
  const GcodeTimeOptions({
    this.pulsePerMm = 1000,
    this.initialXMode = true,
    this.rapidFeedRate,
    this.markFeedRate,
  });

  /// Axis pulses per millimetre; must be finite and positive.
  final double pulsePerMm;

  /// Initial axis mode; true adds axis displacement to Y, false to X.
  final bool initialXMode;

  /// Initial G0 speed in mm/min; null requires an explicit G0 F before moving.
  final double? rapidFeedRate;

  /// Initial G1 speed in mm/min; null requires an explicit G1 F before moving.
  final double? markFeedRate;
}

/// An unsupported or invalid timing line, identified independently of rendering.
class GcodeTimingIssue {
  const GcodeTimingIssue({required this.lineNumber, required this.message});

  final int lineNumber;
  final String message;
}

/// An immutable timing snapshot for the lines processed so far.
class GcodeTimeEstimate {
  GcodeTimeEstimate({
    required this.knownSeconds,
    required List<GcodeTimingIssue> issues,
    int? issueCount,
  })  : issues = List.unmodifiable(issues),
        issueCount = issueCount ?? issues.length;

  /// Subtotal of calculable durations, not a guaranteed lower bound or full time.
  final double knownSeconds;
  final List<GcodeTimingIssue> issues;

  /// The total diagnostic count, including diagnostics omitted from [issues].
  final int issueCount;

  /// Whether the diagnostic list is a bounded preview.
  bool get issuesTruncated => issues.length < issueCount;

  /// Whether every processed line can be accounted for under the demo model.
  bool get isComplete => issueCount == 0;

  /// Estimated seconds, or null if any processed line cannot be timed.
  double? get estimatedSeconds => isComplete ? knownSeconds : null;
}

/// Estimates a string in one pass, including G0 travel by default.
///
/// [options] supplies real axis calibration and optional initial speeds. G0/G1
/// speeds are independent and modal, F is mm/min, G25/G103 T is microseconds,
/// G4 T is milliseconds and G102 F is pulses/second. X/Y accept integer or
/// decimal values. G90/G91 switch absolute/relative coordinates.
/// Unlike preview segment filtering, trailing G4 and stationary G103 durations
/// are included. Unsupported commands or invalid data produce timing issues.
GcodeTimeEstimate estimateGcodeTime(
  String source, {
  GcodeTimeOptions options = const GcodeTimeOptions(),
}) {
  final estimator = GcodeTimeEstimator(options: options);
  var lineNumber = 0;
  for (final line in const LineSplitter().convert(source)) {
    estimator.append(line, lineNumber: ++lineNumber);
  }
  return estimator.snapshot;
}

/// Incrementally accumulates timing without retaining source or geometry.
///
/// Create one instance per load. [snapshot] copies diagnostics so earlier
/// results do not change as more lines are accepted. Invalid options throw
/// [ArgumentError]; invalid input lines are reported through the snapshot.
class GcodeTimeEstimator {
  GcodeTimeEstimator({this.options = const GcodeTimeOptions()})
      : _xMode = options.initialXMode,
        _jumpSpeed = (options.rapidFeedRate ?? 0) / 60,
        _markSpeed = (options.markFeedRate ?? 0) / 60 {
    for (final value in [
      options.pulsePerMm,
      options.rapidFeedRate,
      options.markFeedRate,
    ]) {
      if (value != null && (!value.isFinite || value <= 0)) {
        throw ArgumentError(
          'Pulse calibration and supplied speeds must be finite and positive',
        );
      }
    }
  }

  static final _word = RegExp(r'([A-Za-z])([-+]?(?:\d+\.?\d*|\.\d+))');
  static final _parentheses = RegExp(r'\([^)]*\)');
  static const _motionParameters = {
    'X',
    'Y',
    'F',
    'T',
    'L',
    'H',
    'N',
    'O',
    'S',
    'Q',
  };
  static const _ignoredM = {2, 3, 5, 200, 201};
  final GcodeTimeOptions options;
  final _issues = <GcodeTimingIssue>[];
  bool _xMode;
  bool _relative = false;
  String _motion = 'G0';
  double _lastX = 0, _lastY = 0, _axisPos = 0;
  double _jumpSpeed, _markSpeed;
  double _delayMin = 200, _delayMax = 700, _delayDist = 20;
  double _seconds = 0;
  int _lineNumber = 0;

  GcodeTimeEstimate get snapshot => snapshotWithIssueLimit(null);

  /// Copies at most [limit] diagnostics while preserving their total count.
  ///
  /// A `null` limit returns all diagnostics. Truncation never makes an
  /// incomplete estimate complete. Negative limits throw [ArgumentError].
  GcodeTimeEstimate snapshotWithIssueLimit(int? limit) {
    if (limit != null && limit < 0) throw ArgumentError.value(limit, 'limit');
    return GcodeTimeEstimate(
      knownSeconds: _seconds,
      issues: limit == null ? _issues : _issues.take(limit).toList(),
      issueCount: _issues.length,
    );
  }

  /// Accepts one source line; [lineNumber] defaults to the next sequential line.
  void append(String source, {int? lineNumber}) {
    _lineNumber = lineNumber ?? _lineNumber + 1;
    final line = source.replaceAll(_parentheses, '').split(';').first.trim();
    if (line.isEmpty) return;
    final words = <String, double>{};
    final codes = <String, int>{};
    var end = 0;
    for (final match in _word.allMatches(line)) {
      if (line.substring(end, match.start).trim().isNotEmpty) {
        _issue('Malformed instruction');
        return;
      }
      end = match.end;
      final key = match.group(1)!.toUpperCase();
      final value = double.parse(match.group(2)!);
      if (!value.isFinite) {
        _issue('Non-finite parameter $key');
        return;
      }
      if (key == 'G' || key == 'M') {
        if (codes.containsKey(key) || value != value.truncateToDouble()) {
          _issue('Multiple or fractional $key codes');
          return;
        }
        codes[key] = value.toInt();
      } else {
        words[key] = value;
      }
    }
    if (line.substring(end).trim().isNotEmpty || end == 0) {
      _issue('Malformed instruction');
      return;
    }
    final g = codes['G'];
    final m = codes['M'];
    if (m != null) {
      if (m == 202) {
        final low = words['L'] ?? _delayMin;
        final high = words['H'] ?? _delayMax;
        final dist = words['N'] ?? _delayDist;
        if (low < 0 || high < low || dist < 0) {
          _issue('Invalid M202 jump delay');
          return;
        }
        _delayMin = low;
        _delayMax = high;
        _delayDist = dist;
      } else if (!_ignoredM.contains(m)) {
        _issue('Unsupported M$m');
        return;
      }
      if (g == null) return;
    }
    final unsupported = words.keys.where(
      (key) => !_motionParameters.contains(key),
    );
    if (unsupported.isNotEmpty) {
      _issue('Unsupported parameters: ${unsupported.join('/')}');
      return;
    }
    if (g == 90 || g == 91) {
      if (words.containsKey('X') || words.containsKey('Y')) {
        _issue('Coordinate mode and movement must be on separate lines');
        return;
      }
      _relative = g == 91;
      return;
    }
    if (g == 4) {
      final t = words['T'];
      if (t == null || t < 0) {
        _issue('G4 requires non-negative T in milliseconds');
      } else {
        _add(t / 1000);
      }
      return;
    }
    if (g != null && !const {0, 1, 25, 102, 103}.contains(g)) {
      _issue('Unsupported G$g');
      return;
    }
    if (g != null) _motion = 'G$g';
    if (g == null &&
        words.keys.every((key) => !const {'X', 'Y', 'F', 'T'}.contains(key))) {
      _issue('No motion or timing instruction');
      return;
    }
    if (words['F'] case final double feed) {
      if (feed <= 0) _issue('F must be positive');
      if (_motion == 'G0') _jumpSpeed = feed / 60;
      if (_motion == 'G1') _markSpeed = feed / 60;
    }
    var x = words['X'] == null
        ? _lastX
        : words['X']! + (_relative ? _lastX : (_xMode ? 0 : _axisPos));
    var y = words['Y'] == null
        ? _lastY
        : words['Y']! + (_relative ? _lastY : (_xMode ? _axisPos : 0));
    double seconds = 0;
    if (_motion == 'G102' || _motion == 'G103') {
      final rotary = _motion == 'G103';
      if (!rotary && words['O'] == 1) {
        _motion = 'G0';
        return; // Demo excludes homing.
      }
      final required = rotary ? ['T', 'L', 'N', 'O'] : ['O', 'H', 'N', 'F'];
      if (required.any((key) => words[key] == null)) {
        _issue('$_motion requires ${required.join('/')}');
        return;
      }
      for (final key in rotary ? ['L', 'O'] : ['O', 'H']) {
        if (words[key] != words[key]!.truncateToDouble()) {
          _issue('$_motion $key must be an integer');
          return;
        }
      }
      final pulse = words['N']!;
      if (pulse != pulse.truncateToDouble() ||
          pulse < -2147483648 ||
          pulse > 2147483647) {
        _issue('Axis N must be a signed int32 pulse count');
        return;
      }
      if (rotary ? words['T']! < 0 : words['F']! <= 0) {
        _issue('$_motion has invalid duration or axis speed');
        return;
      }
      final offset = Float32List.fromList([
        Float32List.fromList([pulse]).first / options.pulsePerMm,
      ]).first;
      if (!offset.isFinite) {
        _issue('Axis displacement is not finite');
        return;
      }
      if (rotary) {
        seconds = words['T']! / 1000000;
        _axisPos += offset;
        _xMode = words['O']!.toInt() == 0;
        _motion = words['L']!.toInt() != 0 ? 'G1' : 'G0';
      } else {
        seconds = pulse.abs() / words['F']!;
        _axisPos -= offset;
        _motion = 'G0';
      }
      if (_xMode) {
        y += offset;
      } else {
        x += offset;
      }
    } else {
      final dx = x - _lastX, dy = y - _lastY;
      final distance = math.sqrt(dx * dx + dy * dy);
      final speed = _motion == 'G1' ? _markSpeed : _jumpSpeed;
      if (distance > 1e-6) {
        if (speed > 1e-6 && speed.isFinite) {
          seconds = distance / speed;
        } else {
          _issue('$_motion movement requires a positive F speed');
        }
      }
      if (_motion == 'G25') {
        if (words['T'] case final double exposure) {
          if (exposure < 0) {
            _issue('G25 requires non-negative exposure');
          } else {
            final delay = _delayDist > 1e-6
                ? math.min(
                    _delayMin + (_delayMax - _delayMin) * distance / _delayDist,
                    _delayMax,
                  )
                : _delayMin;
            seconds += (exposure + delay) / 1000000;
          }
        } else {
          _issue('G25 requires T exposure in microseconds');
        }
      }
    }
    if (!x.isFinite || !y.isFinite || !_axisPos.isFinite)
      _issue('Position is not finite');
    _add(seconds);
    _lastX = x;
    _lastY = y;
  }

  void _add(double seconds) {
    if (!seconds.isFinite || seconds < 0 || !(_seconds + seconds).isFinite) {
      _issue('Non-finite or negative computed duration');
    } else {
      _seconds += seconds;
    }
  }

  void _issue(String message) =>
      _issues.add(GcodeTimingIssue(lineNumber: _lineNumber, message: message));
}
