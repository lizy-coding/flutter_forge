import 'dart:async';

import 'package:a2ui_core/a2ui_core.dart' as a2ui;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';

import 'model_source.dart';

/// Shared run machinery for streaming A2UI sessions.
///
/// Owns the epoch/cancel/busy state machine, the bounded activity record and
/// the progressive parse-and-apply submit loop. Each protocol message is
/// fully validated by [applyStreamMessage] before it commits, so an invalid
/// tail leaves earlier messages rendered. Subclasses provide the catalog,
/// their validation rules and the user-facing wording.
abstract class GenuiSessionCore extends ChangeNotifier {
  GenuiSessionCore({this.recordLimit = 20});

  /// Maximum number of entries kept in [records]; the oldest are dropped.
  final int recordLimit;

  bool busy = false;
  String? error;
  final List<String> records = [];

  bool _disposed = false;
  bool _notificationPending = false;
  int _epoch = 0;
  CancelToken? _token;

  bool get disposed => _disposed;

  /// Transport for the run started by [submit]. Return null while no source
  /// is connected; [submitGuard] should reject prompts in that state, and a
  /// null after an accepted guard fails the run safely instead of crashing.
  WorkbenchSource? get activeSource;

  /// Rejects a trimmed prompt before a run starts by returning the error to
  /// show; null accepts the prompt.
  String? submitGuard(String prompt);

  /// Request payload for an accepted prompt; called once per run.
  WorkbenchRequest buildRequest(String prompt);

  /// Validates and applies one protocol message mid-stream. Throwing
  /// [FormatException] aborts the run while keeping applied messages.
  void applyStreamMessage(a2ui.A2uiMessage message);

  /// Message shown when a run fails; protocol rejections keep their message.
  String describeError(Object cause) =>
      cause is FormatException ? cause.message : fallbackError;

  /// Message shown when a run fails without a protocol-level cause.
  String get fallbackError;

  /// Records a failed run; subclasses append their own activity entries.
  void recordError(Object cause, String message) {}

  /// Called when a run is accepted, before the stream opens.
  void onRunStarted(String prompt) {}

  /// Called after each applied protocol message.
  void onMessageApplied(a2ui.A2uiMessage message) {}

  /// Called when the stream completes with at least one applied message.
  void onSuccess(String prompt, int appliedMessages) {}

  /// Called from [cancel]; resets any pending interaction state.
  void onCancelled() {}

  /// Streaming budget for one run.
  int get maxGeneratedChars => 48000;
  String get generatedOverflowMessage => '生成内容过长';
  String get textLeakMessage => '响应不是完整的界面协议';
  String get emptyResultMessage => '没有收到推荐界面';
  Duration get generationTimeout => const Duration(seconds: 100);

  /// Whether an empty trimmed prompt is ignored silently instead of being
  /// reported through [submitGuard].
  bool get silentEmptyPrompt => false;

  /// Appends one activity entry, truncating oversized content and keeping
  /// the buffer bounded.
  void addRecord(String entry) {
    records.add(entry.length > 4000 ? '${entry.substring(0, 4000)}…' : entry);
    if (records.length > recordLimit) {
      records.removeRange(0, records.length - recordLimit);
    }
  }

  /// Coalesces notifications within the current microtask so bursts of
  /// stream updates rebuild listeners once.
  void notifyChanged() {
    if (_disposed || _notificationPending) return;
    _notificationPending = true;
    scheduleMicrotask(() {
      _notificationPending = false;
      if (!_disposed) notifyListeners();
    });
  }

  Future<void> submit(String prompt) async {
    if (_disposed || busy) return;
    final trimmed = prompt.trim();
    if (trimmed.isEmpty && silentEmptyPrompt) return;
    final blocked = submitGuard(trimmed);
    if (blocked != null) {
      error = blocked;
      notifyChanged();
      return;
    }
    final source = activeSource;
    if (source == null) {
      // A guard that accepts prompts guarantees a transport; failing safe
      // keeps a future subclass mistake from becoming a crash.
      error = fallbackError;
      notifyChanged();
      return;
    }
    final epoch = ++_epoch;
    final token = _token = CancelToken();
    busy = true;
    error = null;
    onRunStarted(trimmed);
    notifyChanged();
    var applied = 0;
    var length = 0;
    try {
      // Apply each protocol message as it is parsed so partial results
      // render progressively; every message is fully validated before it
      // commits, and an invalid tail leaves earlier messages in place.
      await for (final event
          in source
              .generate(buildRequest(trimmed), token)
              .timeout(generationTimeout)
              .map((chunk) {
                length += chunk.length;
                if (length > maxGeneratedChars) {
                  throw FormatException(generatedOverflowMessage);
                }
                return chunk;
              })
              .transform(const A2uiParserTransformer())) {
        if (_disposed || epoch != _epoch) return;
        if (event is A2uiMessageEvent) {
          applyStreamMessage(event.message);
          applied++;
          onMessageApplied(event.message);
        } else if (event is TextEvent && event.text.trim().isNotEmpty) {
          throw FormatException(textLeakMessage);
        }
      }
      if (_disposed || epoch != _epoch) return;
      if (applied == 0) throw FormatException(emptyResultMessage);
      onSuccess(trimmed, applied);
    } catch (cause) {
      if (!_disposed && epoch == _epoch) {
        error = describeError(cause);
        recordError(cause, error!);
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        busy = false;
        _token = null;
        notifyChanged();
      }
    }
  }

  void cancel() {
    if (_disposed) return;
    _epoch++;
    _token?.cancel('cancelled');
    _token = null;
    busy = false;
    onCancelled();
    notifyChanged();
  }

  @override
  @mustCallSuper
  void dispose() {
    _disposed = true;
    _epoch++;
    _token?.cancel('disposed');
    super.dispose();
  }
}
