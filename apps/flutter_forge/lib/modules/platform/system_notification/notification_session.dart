import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:forge_notification_bridge/forge_notification_bridge.dart';

/// One module session: permission state, authorization request, local posts
/// and cancels. All native access stays behind the typed bridge interface so
/// the session is fully testable with fakes.
class NotificationSession extends ChangeNotifier {
  NotificationSession(this._notifications);

  final ForgeNotifications _notifications;

  NotificationCapabilities? capabilities;
  NotificationPermissionState? permissionState;
  bool loading = false;
  bool _closed = false;
  final _disposed = Completer<void>();
  Future<T> _owned<T>(Future<T> operation) => Future.any([
    operation,
    _disposed.future.then<T>((_) => throw const _SessionClosed()),
  ]);
  int _epoch = 0;
  bool _current(int epoch) => !_closed && epoch == _epoch;

  @override
  void dispose() {
    if (_closed) return;
    _closed = true;
    _disposed.complete();
    ++_epoch;
    loading = false;
    super.dispose();
  }

  final List<String> logs = [];

  Future<void> initialize() async {
    if (_closed || loading) return;
    final epoch = ++_epoch;
    loading = true;
    notifyListeners();
    try {
      final result = await _owned(_notifications.queryCapabilities());
      if (!_current(epoch)) return;
      capabilities = result;
      if (capabilities!.permissionQuerySupported) {
        final outcome = await _owned(_notifications.queryPermissionState());
        if (!_current(epoch)) return;
        permissionState = outcome.isAvailable ? outcome.value : null;
      }
    } on _SessionClosed {
      return;
    } finally {
      if (_current(epoch)) {
        loading = false;
        notifyListeners();
      }
    }
  }

  String get permissionText {
    final state = permissionState;
    if (state == null) {
      return '授权状态不可用（capability=${capabilities?.permissionQuerySupported ?? false}）';
    }
    return switch (state) {
      NotificationPermissionState.granted => '已授权：系统可受理投递；实际展示取决于系统设置',
      NotificationPermissionState.denied => '已拒绝：投递会返回 permissionDenied',
      NotificationPermissionState.notDetermined => '未决定：请求授权时由系统决定是否显示询问',
      NotificationPermissionState.provisional => '临时授权：通知静默展示',
      NotificationPermissionState.unavailable => '授权状态不可用',
    };
  }

  String get permissionStateName => switch (permissionState) {
    null => 'unknown',
    NotificationPermissionState.granted => 'granted',
    NotificationPermissionState.denied => 'denied',
    NotificationPermissionState.notDetermined => 'notDetermined',
    NotificationPermissionState.provisional => 'provisional',
    NotificationPermissionState.unavailable => 'unavailable',
  };

  Future<void> requestPermission() async {
    if (_closed ||
        loading ||
        !(capabilities?.permissionRequestSupported ?? false)) {
      return;
    }
    final epoch = ++_epoch;
    loading = true;
    notifyListeners();
    try {
      final outcome = await _owned(_notifications.requestPermission());
      if (!_current(epoch)) return;
      logs.add(
        '请求授权 → ${outcome.status.name}'
        '${outcome.isAvailable ? '（${permissionName(outcome.value)}）' : '（${outcome.reason?.code ?? 'unspecified_reason'}）'}',
      );
      if (outcome.isAvailable) {
        permissionState = outcome.value;
      } else {
        final refreshed = await _owned(_notifications.queryPermissionState());
        if (!_current(epoch)) return;
        permissionState = refreshed.isAvailable ? refreshed.value : null;
      }
    } on _SessionClosed {
      return;
    } finally {
      if (_current(epoch)) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> post(String title, String body) async {
    if (_closed || loading) return;
    final epoch = ++_epoch;
    loading = true;
    notifyListeners();
    try {
      final outcome = await _owned(
        _notifications.post(NotificationContent(title: title, body: body)),
      );
      if (!_current(epoch)) return;
      if (outcome.isAvailable) {
        logs.add('系统已受理通知（不保证可见） id=${outcome.value!.id}');
      } else {
        logs.add(
          '投递失败 ${outcome.status.name}（${outcome.reason?.code ?? 'unspecified_reason'}）',
        );
      }
    } on _SessionClosed {
      return;
    } finally {
      if (_current(epoch)) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> cancel(String id) async {
    if (_closed || loading || id.trim().isEmpty) return;
    final epoch = ++_epoch;
    loading = true;
    notifyListeners();
    try {
      final outcome = await _owned(_notifications.cancel(id.trim()));
      if (!_current(epoch)) return;
      logs.add(
        outcome.isAvailable && outcome.value == true
            ? '系统已受理撤回请求 id=$id'
            : '撤回失败 ${outcome.status.name}（${outcome.reason?.code ?? 'unspecified_reason'}）',
      );
    } on _SessionClosed {
      return;
    } finally {
      if (_current(epoch)) {
        loading = false;
        notifyListeners();
      }
    }
  }

  static String permissionName(NotificationPermissionState? state) =>
      switch (state) {
        null => 'unknown',
        NotificationPermissionState.granted => 'granted',
        NotificationPermissionState.denied => 'denied',
        NotificationPermissionState.notDetermined => 'notDetermined',
        NotificationPermissionState.provisional => 'provisional',
        NotificationPermissionState.unavailable => 'unavailable',
      };
}

class _SessionClosed implements Exception {
  const _SessionClosed();
}
