import 'flutter_battery_platform_interface.dart';

/// Notification operations. The host owns permission requests and messaging.
class BatteryNotifications {
  Future<bool?> send({
    required String title,
    required String message,
    int delayMinutes = 0,
  }) {
    if (delayMinutes < 0) {
      throw ArgumentError.value(delayMinutes, 'delayMinutes');
    }
    return FlutterBatteryPlatform.instance.sendNotification(
      title: title,
      message: message,
      delay: delayMinutes,
    );
  }
}
