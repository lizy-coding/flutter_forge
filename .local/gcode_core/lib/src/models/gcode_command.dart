import 'machine_position.dart';

enum GcodeSegmentType { rapid, linear }

class GcodeCommand {
  const GcodeCommand({
    required this.lineNumber,
    required this.rawLine,
    required this.code,
    required this.params,
    this.comment = '',
  });

  final int lineNumber;
  final String rawLine;
  final String code;
  final Map<String, double> params;
  final String comment;

  double? get x => params['X'];
  double? get y => params['Y'];
  double? get feedRate => params['F'];

  MachinePosition toPosition(MachinePosition current) {
    return MachinePosition(
      x: x ?? current.x,
      y: y ?? current.y,
      feedRate: feedRate ?? current.feedRate,
    );
  }
}
