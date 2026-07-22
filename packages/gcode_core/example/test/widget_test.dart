import 'package:gcode_core/gcode_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GcodeReadlinePipeline smoke test', (WidgetTester tester) async {
    final pipeline = GcodeReadlinePipeline(
      options: const GcodeReadlineOptions(snapshotBatchSize: 2),
    );

    final snapshots = await pipeline
        .load(const StringGcodeLineReader('G0 X0 Y0\nG1 X10 Y0\n'))
        .toList();

    expect(snapshots.isNotEmpty, true);
    final last = snapshots.last;
    expect(last.stage, GcodeLoadStage.ready);
    expect(last.commands.length, 2);
  });
}
