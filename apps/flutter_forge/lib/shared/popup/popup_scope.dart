import 'dart:async';

import 'package:flutter/material.dart';

/// Owns popup routes, overlay entries, and cancellable opening sequences.
///
/// A page disposes its scope when it leaves the navigator. Cleanup removes only
/// resources created through this scope, including barriers still being closed.
class PopupScope {
  final Map<Object, Route<dynamic>> _routes = {};
  final Map<Object, List<OverlayEntry>> _overlays = {};
  final Map<String, Object> _sequences = {};
  final Map<String, _Pause> _pauses = {};
  bool _disposed = false;

  /// Pushes a route and retains ownership until it is closed or disposed.
  Future<T?> push<T>(NavigatorState navigator, Route<T> route, {Object? id}) {
    if (_disposed) return Future<T?>.value();
    final key = id ?? Object();
    closeRoute(key);
    _routes[key] = route;
    try {
      return navigator.push(route).whenComplete(() {
        if (identical(_routes[key], route)) _routes.remove(key);
      });
    } catch (_) {
      _routes.remove(key);
      rethrow;
    }
  }

  /// Closes an owned route without popping unrelated navigation entries.
  void closeRoute(Object id) {
    final route = _routes.remove(id);
    _removeRoute(route);
  }

  void _removeRoute(Route<dynamic>? route) {
    final navigator = route?.navigator;
    if (route != null &&
        route.isActive &&
        navigator != null &&
        navigator.mounted) {
      navigator.removeRoute(route);
    }
  }

  /// Inserts a group of overlay entries under one ownership key.
  void insertOverlay(
    Object id,
    OverlayState overlay,
    List<OverlayEntry> entries,
  ) {
    if (_disposed) {
      for (final entry in entries) {
        entry.dispose();
      }
      return;
    }
    closeOverlay(id);
    overlay.insertAll(entries);
    _overlays[id] = List.of(entries);
  }

  /// Closes an entire overlay group, including its modal barrier.
  void closeOverlay(Object id) {
    final entries = _overlays.remove(id);
    if (entries == null) return;
    for (final entry in entries.reversed) {
      entry.remove();
      entry.dispose();
    }
  }

  /// Rearranges owned groups while preserving each group's barrier order.
  void rearrange(OverlayState overlay, List<Object> order) {
    if (_disposed) return;
    final entries = [for (final id in order) ...?_overlays[id]];
    if (entries.isNotEmpty) overlay.rearrange(entries);
  }

  /// Runs a sequence until replaced on its channel or disposed.
  ///
  /// Opening and closing share a channel so a close request cancels pending
  /// opens. Delays are cancelled immediately when ownership ends.
  Future<void> sequence<T>(
    String channel,
    Iterable<T> items,
    void Function(T) step, {
    Duration interval = const Duration(milliseconds: 120),
  }) async {
    if (_disposed) return;
    final token = Object();
    _sequences[channel] = token;
    _pauses.remove(channel)?.cancel();
    try {
      for (final item in items) {
        if (_disposed || !identical(_sequences[channel], token)) return;
        step(item);
        if (_disposed || !identical(_sequences[channel], token)) return;
        final pause = _Pause(interval);
        _pauses[channel] = pause;
        await pause.done;
        if (identical(_pauses[channel], pause)) _pauses.remove(channel);
      }
    } finally {
      if (identical(_sequences[channel], token)) _sequences.remove(channel);
    }
  }

  /// Cancels pending work and releases all owned popup resources.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final pause in _pauses.values) {
      pause.cancel();
    }
    _pauses.clear();
    _sequences.clear();
    for (final id in _overlays.keys.toList()) {
      closeOverlay(id);
    }
    final routes = _routes.values.toList();
    _routes.clear();
    // Page disposal may run while the Navigator is updating its route stack.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final route in routes) {
        _removeRoute(route);
      }
    });
  }
}

class _Pause {
  _Pause(Duration duration) {
    _timer = Timer(duration, cancel);
  }

  late final Timer _timer;
  final Completer<void> _completion = Completer<void>();

  Future<void> get done => _completion.future;

  void cancel() {
    _timer.cancel();
    if (!_completion.isCompleted) _completion.complete();
  }
}
