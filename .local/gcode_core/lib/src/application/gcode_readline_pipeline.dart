import 'dart:async';
import 'dart:isolate';

import '../data/readers/gcode_line_reader.dart';
import '../data/readers/file_gcode_line_reader.dart';
import '../data/readers/string_gcode_line_reader.dart';
import '../domain/gcode_load_snapshot.dart';
import '../domain/gcode_load_stage.dart';
import '../domain/parsed_gcode_line.dart';
import '../models/gcode_command.dart';
import '../models/toolpath_segment.dart';
import '../parser/gcode_parse_result.dart';
import '../parser/gcode_parser.dart';
import '../services/toolpath_builder.dart';
import '../services/gcode_time_estimator.dart';

class GcodeReadlineOptions {
  const GcodeReadlineOptions({
    this.snapshotBatchSize = 200,
    this.previewLimit,
    this.minimumSnapshotInterval = Duration.zero,
    this.timeOptions = const GcodeTimeOptions(),
  });

  final int snapshotBatchSize;

  /// Caps intermediate geometry; terminal snapshots always contain all data.
  /// Null preserves cumulative snapshots for existing consumers.
  final int? previewLimit;

  /// Minimum interval for intermediate snapshots; terminal events are immediate.
  final Duration minimumSnapshotInterval;

  /// Axis calibration and initial speeds used by every loading entrypoint.
  final GcodeTimeOptions timeOptions;
}

class GcodeReadlinePipeline {
  static final _occupiedBuilders = Expando<bool>('loading toolpath builders');

  /// Creates a pipeline for source timing and toolpath loading.
  ///
  /// [parser] and [toolpathBuilder] are used by [load]. A supplied builder is
  /// reset for each load and retained after completion. Concurrent loads using
  /// that same builder, including through another pipeline, throw [StateError].
  /// Background entrypoints use their own default parser and builder.
  GcodeReadlinePipeline({
    GcodeParser? parser,
    IncrementalToolpathBuilder? toolpathBuilder,
    this.options = const GcodeReadlineOptions(),
  })  : _parser = parser ?? GcodeParser(),
        _toolpathBuilder = toolpathBuilder;

  final GcodeParser _parser;
  final IncrementalToolpathBuilder? _toolpathBuilder;
  final GcodeReadlineOptions options;

  /// Reads source records and emits immutable loading snapshots.
  ///
  /// Default builders are independent for concurrent loads. Cancelling the
  /// subscription releases the reader and any injected builder's occupancy.
  /// Invalid timing options produce [ArgumentError] on the stream. Read errors
  /// produce a failed snapshot whose complete duration is unavailable.
  Stream<GcodeLoadSnapshot> load(GcodeLineReader reader) async* {
    final injectedBuilder = _toolpathBuilder;
    if (injectedBuilder != null && _occupiedBuilders[injectedBuilder] == true) {
      throw StateError('The injected toolpath builder is already loading');
    }
    if (injectedBuilder != null) _occupiedBuilders[injectedBuilder] = true;
    try {
      yield* _load(reader, injectedBuilder ?? IncrementalToolpathBuilder());
    } finally {
      if (injectedBuilder != null) _occupiedBuilders[injectedBuilder] = null;
    }
  }

  Stream<GcodeLoadSnapshot> _load(
    GcodeLineReader reader,
    IncrementalToolpathBuilder builder,
  ) async* {
    final commands = <GcodeCommand>[];
    final errors = <GcodeParseError>[];
    final segments = <ToolpathSegment>[];
    final estimator = GcodeTimeEstimator(options: options.timeOptions);
    var linesRead = 0;
    var changedSinceSnapshot = 0;
    final snapshotClock = Stopwatch()..start();
    final previewLimit = options.previewLimit;
    if (previewLimit != null && previewLimit < 0) {
      throw ArgumentError.value(previewLimit, 'previewLimit');
    }
    List<GcodeCommand>? previewCommands;
    List<GcodeParseError>? previewErrors;
    List<ToolpathSegment>? previewSegments;

    builder.reset();

    yield const GcodeLoadSnapshot(
      stage: GcodeLoadStage.reading,
      commands: [],
      errors: [],
      segments: [],
      linesRead: 0,
      message: '开始逐行读取',
    );

    try {
      await for (final record in reader.readLines()) {
        linesRead = record.lineNumber;
        estimator.append(record.rawLine, lineNumber: record.lineNumber);
        final parsed = _parser.parseRecord(record);

        switch (parsed.kind) {
          case ParsedGcodeLineKind.command:
            final command = parsed.command!;
            commands.add(command);
            final segment = builder.accept(command);
            if (segment != null) {
              segments.add(segment);
            }
          case ParsedGcodeLineKind.error:
            errors.add(parsed.error!);
          case ParsedGcodeLineKind.skipped:
            break;
        }

        changedSinceSnapshot++;
        if (changedSinceSnapshot >= options.snapshotBatchSize &&
            snapshotClock.elapsed >= options.minimumSnapshotInterval) {
          snapshotClock.reset();
          changedSinceSnapshot = 0;
          if (previewLimit != null &&
              linesRead >= previewLimit &&
              previewSegments == null) {
            previewCommands = List.unmodifiable(commands.take(previewLimit));
            previewErrors = List.unmodifiable(errors.take(previewLimit));
            previewSegments = List.unmodifiable(segments.take(previewLimit));
          }
          yield _snapshot(
            builder: builder,
            stage: GcodeLoadStage.parsing,
            commands: previewCommands ?? commands,
            errors: previewErrors ?? errors,
            segments: previewSegments ?? segments,
            timeEstimate: estimator.snapshot,
            linesRead: linesRead,
            message: '已读取 $linesRead 行',
          );
        }
      }

      yield _snapshot(
        builder: builder,
        stage: GcodeLoadStage.ready,
        commands: commands,
        errors: errors,
        segments: segments,
        timeEstimate: estimator.snapshot,
        linesRead: linesRead,
        message: '逐行读取完成: $linesRead 行, '
            '${commands.length} 条指令, ${errors.length} 个错误, '
            '${segments.length} 条轨迹段',
      );
    } catch (error) {
      yield _snapshot(
        builder: builder,
        stage: GcodeLoadStage.failed,
        commands: commands,
        errors: errors,
        segments: segments,
        timeEstimate: estimator.snapshot,
        linesRead: linesRead,
        message: '读取失败: $error',
      );
    }
  }

  /// Loads a native file through an isolated default pipeline.
  ///
  /// Invalid timing options produce [ArgumentError] before a worker starts.
  /// Read errors produce failed snapshots. Unexpected worker failures produce
  /// stream errors. Cancelling the subscription stops the worker.
  Stream<GcodeLoadSnapshot> loadFileInBackground(String filePath) =>
      _loadInBackground(filePath, true);

  /// Loads text through an isolated default pipeline.
  ///
  /// Error and cancellation behavior matches [loadFileInBackground].
  Stream<GcodeLoadSnapshot> loadStringInBackground(String source) =>
      _loadInBackground(source, false);

  Stream<GcodeLoadSnapshot> _loadInBackground(
    String input,
    bool isFile,
  ) async* {
    // Validate in the caller isolate so invalid options have the same error
    // behavior as direct loads, before a worker is started.
    GcodeTimeEstimator(options: options.timeOptions);
    final receivePort = ReceivePort();
    Isolate? worker;
    try {
      worker = await Isolate.spawn(
        _isolateLoad,
        (input, isFile, options, receivePort.sendPort),
        onError: receivePort.sendPort,
        onExit: receivePort.sendPort,
      );
      var hasTerminalSnapshot = false;
      SendPort? acknowledge;
      await for (final message in receivePort) {
        if (message is SendPort) {
          acknowledge = message;
          continue;
        }
        if (message is _IsolateDone) {
          if (!hasTerminalSnapshot) {
            throw StateError(
              'Background load completed without a final snapshot',
            );
          }
          break;
        }
        if (message is _IsolateFailure) {
          throw RemoteError(message.error, message.stackTrace);
        }
        if (message == null) {
          throw StateError('Background worker exited before load completion');
        }
        if (message is List && message.length == 2) {
          // Uncaught isolate errors arrive as description/stack trace pairs.
          throw RemoteError(message[0].toString(), message[1].toString());
        }
        if (message is! GcodeLoadSnapshot) {
          throw StateError('Unexpected background load message');
        }
        hasTerminalSnapshot = message.stage == GcodeLoadStage.ready ||
            message.stage == GcodeLoadStage.failed;
        yield message;
        acknowledge?.send(true);
      }
    } finally {
      receivePort.close();
      worker?.kill(priority: Isolate.immediate);
    }
  }

  GcodeLoadSnapshot _snapshot({
    required IncrementalToolpathBuilder builder,
    required GcodeLoadStage stage,
    required List<GcodeCommand> commands,
    required List<GcodeParseError> errors,
    required List<ToolpathSegment> segments,
    required GcodeTimeEstimate timeEstimate,
    required int linesRead,
    required String message,
  }) {
    final b = builder.bounds;
    return GcodeLoadSnapshot(
      stage: stage,
      commands: stage == GcodeLoadStage.parsing &&
              options.previewLimit != null &&
              linesRead >= options.previewLimit!
          ? commands
          : List.unmodifiable(commands),
      errors: stage == GcodeLoadStage.parsing &&
              options.previewLimit != null &&
              linesRead >= options.previewLimit!
          ? errors
          : List.unmodifiable(errors),
      segments: stage == GcodeLoadStage.parsing &&
              options.previewLimit != null &&
              linesRead >= options.previewLimit!
          ? segments
          : List.unmodifiable(segments),
      timeEstimate: timeEstimate,
      linesRead: linesRead,
      message: message,
      bounds:
          b.minX != 0 || b.maxX != 0 || b.minY != 0 || b.maxY != 0 ? b : null,
    );
  }

  static Future<void> _isolateLoad(
    (String, bool, GcodeReadlineOptions, SendPort) args,
  ) async {
    final (input, isFile, options, sendPort) = args;
    final acknowledgements = ReceivePort();
    final iterator = StreamIterator(acknowledgements);
    sendPort.send(acknowledgements.sendPort);
    try {
      final reader =
          isFile ? FileGcodeLineReader(input) : StringGcodeLineReader(input);
      // Reuse one pipeline so timing, bounds and immutable snapshots cannot
      // diverge between direct, file-isolate and string-isolate loading.
      await for (final snapshot in GcodeReadlinePipeline(
        options: options,
      ).load(reader)) {
        sendPort.send(snapshot);
        if (!await iterator.moveNext()) break;
      }
      sendPort.send(const _IsolateDone());
    } catch (error, stackTrace) {
      sendPort.send(_IsolateFailure(error.toString(), stackTrace.toString()));
    } finally {
      await iterator.cancel();
      acknowledgements.close();
    }
  }
}

class _IsolateDone {
  const _IsolateDone();
}

class _IsolateFailure {
  const _IsolateFailure(this.error, this.stackTrace);

  final String error;
  final String stackTrace;
}
