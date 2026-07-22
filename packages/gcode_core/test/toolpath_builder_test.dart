import 'package:test/test.dart';
import 'package:gcode_core/gcode_core.dart';

void main() {
  group('ToolpathBuilder', () {
    test('builds linear segments from G1 commands', () {
      final commands = [
        const GcodeCommand(
          lineNumber: 1,
          rawLine: 'G1 X10 Y0',
          code: 'G1',
          params: {'X': 10, 'Y': 0},
        ),
        const GcodeCommand(
          lineNumber: 2,
          rawLine: 'G1 X10 Y10',
          code: 'G1',
          params: {'X': 10, 'Y': 10},
        ),
      ];

      final segments = ToolpathBuilder.build(commands);

      expect(segments, hasLength(2));
      expect(segments[0].type, GcodeSegmentType.linear);
      expect(segments[0].start.x, 0);
      expect(segments[0].start.y, 0);
      expect(segments[0].end.x, 10);
      expect(segments[0].end.y, 0);
      expect(segments[1].end.x, 10);
      expect(segments[1].end.y, 10);
    });

    test('builds rapid segments from G0 commands', () {
      final commands = [
        const GcodeCommand(
          lineNumber: 1,
          rawLine: 'G0 X50 Y50',
          code: 'G0',
          params: {'X': 50, 'Y': 50},
        ),
      ];

      final segments = ToolpathBuilder.build(commands);

      expect(segments, hasLength(1));
      expect(segments[0].type, GcodeSegmentType.rapid);
    });

    test('keeps previous coordinate when X/Y omitted', () {
      final commands = [
        const GcodeCommand(
          lineNumber: 1,
          rawLine: 'G1 X10 Y20',
          code: 'G1',
          params: {'X': 10, 'Y': 20},
        ),
        const GcodeCommand(
          lineNumber: 2,
          rawLine: 'G1 X30',
          code: 'G1',
          params: {'X': 30},
        ),
      ];

      final segments = ToolpathBuilder.build(commands);

      expect(segments, hasLength(2));
      expect(segments[1].start.y, 20); // kept from previous
      expect(segments[1].end.x, 30);
      expect(segments[1].end.y, 20);
    });

    test('no segment when no movement', () {
      final commands = [
        const GcodeCommand(
          lineNumber: 1,
          rawLine: 'G1 X0 Y0',
          code: 'G1',
          params: {'X': 0, 'Y': 0},
        ),
      ];

      final segments = ToolpathBuilder.build(commands);
      expect(segments, isEmpty);
    });

    test('empty commands returns empty segments', () {
      final segments = ToolpathBuilder.build([]);
      expect(segments, isEmpty);
    });

    test('G90 sets absolute mode', () {
      final commands = [
        const GcodeCommand(
          lineNumber: 1,
          rawLine: 'G90',
          code: 'G90',
          params: {},
        ),
        const GcodeCommand(
          lineNumber: 2,
          rawLine: 'G1 X10 Y10',
          code: 'G1',
          params: {'X': 10, 'Y': 10},
        ),
      ];

      final segments = ToolpathBuilder.build(commands);
      expect(segments, hasLength(1));
      expect(segments[0].end.x, 10);
      expect(segments[0].end.y, 10);
    });

    test('G91 sets relative mode', () {
      final commands = [
        const GcodeCommand(
          lineNumber: 1,
          rawLine: 'G91',
          code: 'G91',
          params: {},
        ),
        const GcodeCommand(
          lineNumber: 2,
          rawLine: 'G1 X10 Y10',
          code: 'G1',
          params: {'X': 10, 'Y': 10},
        ),
        const GcodeCommand(
          lineNumber: 3,
          rawLine: 'G1 X10 Y10',
          code: 'G1',
          params: {'X': 10, 'Y': 10},
        ),
      ];

      final segments = ToolpathBuilder.build(commands);
      expect(segments, hasLength(2));
      expect(segments[0].end.x, 10);
      expect(segments[0].end.y, 10);
      expect(segments[1].start.x, 10);
      expect(segments[1].start.y, 10);
      expect(segments[1].end.x, 20);
      expect(segments[1].end.y, 20);
    });

    test('mode changes do not create segments', () {
      final commands = [
        const GcodeCommand(
          lineNumber: 1,
          rawLine: 'G90',
          code: 'G90',
          params: {},
        ),
        const GcodeCommand(
          lineNumber: 2,
          rawLine: 'G91',
          code: 'G91',
          params: {},
        ),
      ];

      final segments = ToolpathBuilder.build(commands);
      expect(segments, isEmpty);
    });

    test('mixed G90/G91 sequence', () {
      final commands = [
        const GcodeCommand(
          lineNumber: 1,
          rawLine: 'G90',
          code: 'G90',
          params: {},
        ),
        const GcodeCommand(
          lineNumber: 2,
          rawLine: 'G1 X10 Y10',
          code: 'G1',
          params: {'X': 10, 'Y': 10},
        ),
        const GcodeCommand(
          lineNumber: 3,
          rawLine: 'G91',
          code: 'G91',
          params: {},
        ),
        const GcodeCommand(
          lineNumber: 4,
          rawLine: 'G1 X10 Y10',
          code: 'G1',
          params: {'X': 10, 'Y': 10},
        ),
      ];

      final segments = ToolpathBuilder.build(commands);
      expect(segments, hasLength(2));
      expect(segments[0].end.x, 10); // absolute: 0 -> 10
      expect(segments[0].end.y, 10);
      expect(segments[1].end.x, 20); // relative: 10 + 10
      expect(segments[1].end.y, 20);
    });
  });
}
