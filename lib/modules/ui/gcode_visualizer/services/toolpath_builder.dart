import '../models/gcode_command.dart';
import '../models/machine_position.dart';
import '../models/toolpath_segment.dart';

class ToolpathBuilder {
  static List<ToolpathSegment> build(List<GcodeCommand> commands) {
    final segments = <ToolpathSegment>[];
    var current = const MachinePosition();

    for (final cmd in commands) {
      final next = cmd.toPosition(current);

      final hasMovement = (cmd.x != null && cmd.x != current.x) ||
          (cmd.y != null && cmd.y != current.y);

      if (hasMovement) {
        final type =
            cmd.code == 'G0' ? GcodeSegmentType.rapid : GcodeSegmentType.linear;

        segments.add(
          ToolpathSegment(
            start: current,
            end: next,
            command: cmd,
            type: type,
          ),
        );
      }

      current = next;
    }

    return segments;
  }
}

class IncrementalToolpathBuilder {
  MachinePosition _current = const MachinePosition();

  MachinePosition get current => _current;

  ToolpathSegment? accept(GcodeCommand command) {
    final next = command.toPosition(_current);

    final hasMovement = (command.x != null && command.x != _current.x) ||
        (command.y != null && command.y != _current.y);

    if (!hasMovement) {
      _current = next;
      return null;
    }

    final segment = ToolpathSegment(
      start: _current,
      end: next,
      command: command,
      type: command.code == 'G0'
          ? GcodeSegmentType.rapid
          : GcodeSegmentType.linear,
    );

    _current = next;
    return segment;
  }

  void reset() {
    _current = const MachinePosition();
  }
}
