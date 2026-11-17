import 'gcode_command.dart';
import 'machine_position.dart';

class ToolpathSegment {
  const ToolpathSegment({
    required this.start,
    required this.end,
    required this.command,
    required this.type,
  });

  final MachinePosition start;
  final MachinePosition end;
  final GcodeCommand command;
  final GcodeSegmentType type;
}
