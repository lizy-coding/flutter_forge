import '../core/gcode_bounds.dart';
import '../models/gcode_command.dart';
import '../models/machine_position.dart';
import '../models/toolpath_segment.dart';

enum CoordinateMode { absolute, relative }

MachinePosition _applyCommand(
    GcodeCommand cmd, MachinePosition current, CoordinateMode mode) {
  if (mode == CoordinateMode.absolute) {
    return cmd.toPosition(current);
  }
  return MachinePosition(
    x: cmd.x != null ? current.x + cmd.x! : current.x,
    y: cmd.y != null ? current.y + cmd.y! : current.y,
    feedRate: cmd.feedRate ?? current.feedRate,
  );
}

class ToolpathBuilder {
  static List<ToolpathSegment> build(List<GcodeCommand> commands) {
    final segments = <ToolpathSegment>[];
    var current = const MachinePosition();
    var mode = CoordinateMode.absolute;

    for (final cmd in commands) {
      if (cmd.code == 'G90') {
        mode = CoordinateMode.absolute;
        continue;
      }
      if (cmd.code == 'G91') {
        mode = CoordinateMode.relative;
        continue;
      }

      final next = _applyCommand(cmd, current, mode);

      if (next.x != current.x || next.y != current.y) {
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
  GcodeBounds _bounds = GcodeBounds.zero;
  CoordinateMode _mode = CoordinateMode.absolute;

  MachinePosition get current => _current;

  GcodeBounds get bounds => _bounds;

  CoordinateMode get coordinateMode => _mode;

  ToolpathSegment? accept(GcodeCommand command) {
    if (command.code == 'G90') {
      _mode = CoordinateMode.absolute;
      return null;
    }
    if (command.code == 'G91') {
      _mode = CoordinateMode.relative;
      return null;
    }

    final next = _applyCommand(command, _current, _mode);

    if (next.x == _current.x && next.y == _current.y) {
      _current = next;
      return null;
    }

    _bounds = _bounds.expand(_current.x, _current.y).expand(next.x, next.y);

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
    _bounds = GcodeBounds.zero;
    _mode = CoordinateMode.absolute;
  }
}
