import 'package:flutter_test/flutter_test.dart';
import 'package:main_app/modules/ui/gcode_visualizer/domain/gcode_line_record.dart';
import 'package:main_app/modules/ui/gcode_visualizer/domain/parsed_gcode_line.dart';
import 'package:main_app/modules/ui/gcode_visualizer/parser/gcode_parser.dart';

void main() {
  group('GcodeParser', () {
    final parser = GcodeParser();

    test('parses G0 uppercase', () {
      final result = parser.parse('G0 X10 Y20');
      expect(result.commands, hasLength(1));
      expect(result.commands.first.code, 'G0');
      expect(result.commands.first.x, 10);
      expect(result.commands.first.y, 20);
    });

    test('parses G1 uppercase', () {
      final result = parser.parse('G1 X30 Y40 F500');
      expect(result.commands, hasLength(1));
      expect(result.commands.first.code, 'G1');
      expect(result.commands.first.x, 30);
      expect(result.commands.first.y, 40);
      expect(result.commands.first.feedRate, 500);
    });

    test('parses lowercase', () {
      final result = parser.parse('g0 x10 y20');
      expect(result.commands, hasLength(1));
      expect(result.commands.first.code, 'G0');
      expect(result.commands.first.x, 10);
    });

    test('parses G00 and G01 aliases', () {
      final r1 = parser.parse('G00 X5 Y5');
      expect(r1.commands.first.code, 'G0');

      final r2 = parser.parse('G01 X5 Y5');
      expect(r2.commands.first.code, 'G1');
    });

    test('parses semicolon comments', () {
      final result = parser.parse('G1 X10 Y10 ; move to position');
      expect(result.commands, hasLength(1));
      expect(result.commands.first.comment, 'move to position');
    });

    test('parses parentheses comments', () {
      final result = parser.parse('G1 X10 Y10 (comment here)');
      expect(result.commands, hasLength(1));
      expect(result.commands.first.x, 10);
    });

    test('skips empty lines', () {
      final result = parser.parse('''

G0 X0 Y0

G1 X10 Y10

''');
      expect(result.commands, hasLength(2));
      expect(result.errors, isEmpty);
    });

    test('rejects unsupported G2', () {
      final result = parser.parse('G2 X10 Y10 I5 J5');
      expect(result.errors, hasLength(1));
      expect(result.errors.first.message, contains('Unsupported code'));
    });

    test('rejects malformed X value', () {
      final result = parser.parse('G1 Xabc Y10');
      expect(result.errors, hasLength(1));
      expect(result.errors.first.message, contains('Malformed parameter'));
    });

    test('rejects parameter with trailing junk', () {
      final result = parser.parse('G1 X10abc Y10');
      expect(result.commands, isEmpty);
      expect(result.errors, hasLength(1));
      expect(result.errors.first.message, contains('Malformed parameter'));
    });

    test('handles negative coordinates', () {
      final result = parser.parse('G1 X-10.5 Y-20.3');
      expect(result.commands, hasLength(1));
      expect(result.commands.first.x, -10.5);
      expect(result.commands.first.y, -20.3);
    });

    test('handles leading decimal coordinates', () {
      final result = parser.parse('G1 X.5 Y-.25');
      expect(result.commands, hasLength(1));
      expect(result.commands.first.x, 0.5);
      expect(result.commands.first.y, -0.25);
    });

    test('multi-line parse with errors preserves valid commands', () {
      final result = parser.parse('''
G0 X0 Y0
G2 X10 Y10
G1 X20 Y20
''');
      expect(result.commands, hasLength(2));
      expect(result.errors, hasLength(1));
      expect(result.errors.first.lineNumber, 2);
    });

    test('parseRecord preserves readline metadata', () {
      final parsed = parser.parseRecord(
        const GcodeLineRecord(
          lineNumber: 12,
          rawLine: 'G1 X20 Y30',
          byteOffset: 128,
        ),
      );

      expect(parsed.kind, ParsedGcodeLineKind.command);
      expect(parsed.record.lineNumber, 12);
      expect(parsed.record.byteOffset, 128);
      expect(parsed.command?.lineNumber, 12);
      expect(parsed.command?.x, 20);
    });
  });
}
