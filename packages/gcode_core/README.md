# gcode_core

![example](https://github.com/lizy-coding/gcode_core/blob/master/gcode_print.gif)

G-code parsing and visualization package extracted from `flutter_study`.

## Scope

- Read G-code from strings or files line by line.
- Parse G0/G1 commands with X/Y/F parameters.
- Collect parse errors with line metadata.
- Build incremental or batch toolpath segments.
- Render toolpaths with Flutter `CustomPaint`.
- Render command timelines and playback controls for Flutter frontends.

This package does not open system file pickers or own app-level playback state.

## Test

```bash
flutter test
```

## Example

Run the Flutter example app:

```bash
cd example
flutter run
```

The example demonstrates local file selection, streaming parse snapshots,
`GcodeCanvas` drawing, `CommandTimeline`, and `PlaybackControls`.

Run the console example:

```bash
dart run example/gcode_core_example.dart
```

Minimal usage:

```dart
import 'package:gcode_core/gcode_core.dart';

Future<void> main() async {
  const source = '''
G0 X0 Y0
G1 X10 Y0 F1200
G1 X10 Y10
''';

  final pipeline = GcodeReadlinePipeline();

  await for (final snapshot
      in pipeline.load(const StringGcodeLineReader(source))) {
    if (snapshot.stage == GcodeLoadStage.ready) {
      print(snapshot.commands.length);
      print(snapshot.segments.length);
      print(snapshot.errors.length);
    }
  }
}
```
