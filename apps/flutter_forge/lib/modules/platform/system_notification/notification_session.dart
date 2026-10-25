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
  final List<String> logs = [];

  Future<void> initialize() async {
    loading = true;
    notifyListeners();
    capabilities = await _notifications.queryCapabilities();
    if (capabilities!.permissionQuerySupported) {
      final outcome = await _notifications.queryPermissionState();
      if (outcome.isAvailable) permissionState = outcome.value;
    }
    loading = false;
    notifyListeners();
  }

  String get permissionText {
    final state = permissionState;
    if (state == null) {
      return '授权状态不可用（capability=${capabilities?.permissionQuerySupported ?? false}）';
    }
    return switch (state) {
      NotificationPermissionState.granted => '已授权：通知可以立即投递',
      NotificationPermissionState.denied => '已拒绝：投递会返回 permissionDenied',
      NotificationPermissionState.notDetermined => '未决定：下一次请求授权时会弹出系统询问',
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
    if (loading || !(capabilities?.permissionRequestSupported ?? false)) return;
    loading = true;
    notifyListeners();
    final outcome = await _notifications.requestPermission();
    logs.add(
      '请求授权 → ${outcome.status.name}'
      '${outcome.isAvailable ? '（${permissionName(outcome.value)}）' : '（${outcome.reason?.code ?? 'unspecified_reason'}）'}',
    );
    if (outcome.isAvailable) {
      permissionState = outcome.value;
    }
    loading = false;
    notifyListeners();
  }

  Future<void> post(String title, String body) async {
    if (loading) return;
    loading = true;
    notifyListeners();
    final outcome = await _notifications.post(
      NotificationContent(title: title, body: body),
    );
    if (outcome.isAvailable) {
      logs.add('投递成功 id=${outcome.value!.id}');
    } else {
      logs.add(
        '投递失败 ${outcome.status.name}（${outcome.reason?.code ?? 'unspecified_reason'}）',
      );
    }
    loading = false;
    notifyListeners();
  }

  Future<void> cancel(String id) async {
    if (loading || id.trim().isEmpty) return;
    loading = true;
    notifyListeners();
    final outcome = await _notifications.cancel(id.trim());
    logs.add(
      outcome.isAvailable
          ? '撤回成功 id=$id'
          : '撤回失败 ${outcome.status.name}（${outcome.reason?.code ?? 'unspecified_reason'}）',
    );
    loading = false;
    notifyListeners();
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
