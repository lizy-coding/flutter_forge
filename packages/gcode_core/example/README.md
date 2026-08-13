# gcode_core example

Flutter example for the `gcode_core` package.

It demonstrates the full local workflow:

- Pick a local `.gcode`, `.nc`, `.tap`, or `.txt` file.
- Read the file line by line with `FileGcodeLineReader`.
- Parse supported `G0/G1` commands with `GcodeReadlinePipeline`.
- Dynamically refresh parsed snapshots while reading.
- Draw toolpath segments with the package-provided `GcodeCanvas`.
- Show `G0` jump moves as red dashed lines and `G1` cutting moves as solid paths.
- Show commands and parse errors with `CommandTimeline`.
- Preview the generated path with `PlaybackControls`.

The main integration points are:

```dart
final pipeline = GcodeReadlinePipeline(
  options: const GcodeReadlineOptions(snapshotBatchSize: 1),
);

await for (final snapshot in pipeline.load(FileGcodeLineReader(file.path))) {
  setState(() => _snapshot = snapshot);
}

GcodeCanvas(
  segments: snapshot.segments,
  progress: playbackProgress,
  errorCount: snapshot.errors.length,
);
```

Run it from this directory:

```bash
flutter run
```
