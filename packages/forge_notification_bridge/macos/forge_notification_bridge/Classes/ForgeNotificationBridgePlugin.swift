import Cocoa
import UserNotifications
import FlutterMacOS

/// UNUserNotificationCenter adapter over the
/// forge_notification/notifications channel. Authorization queries and
/// notification posts resolve to typed status maps; nothing throws.
public class ForgeNotificationBridgePlugin: NSObject, FlutterPlugin {
    private static let channelName = "forge_notification/notifications"

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: ForgeNotificationBridgePlugin.channelName,
            binaryMessenger: registrar.messenger
        )
        registrar.addMethodCallDelegate(ForgeNotificationBridgePlugin(), channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "queryCapabilities":
            result([
                "postingSupported": true,
                "permissionQuerySupported": true,
                "permissionRequestSupported": true,
                "cancelSupported": true,
            ])
        case "queryPermissionState":
            queryPermissionState(result: result)
        case "requestPermission":
            requestPermission(result: result)
        case "post":
            post(arguments: call.arguments, result: result)
        case "cancel":
            cancel(arguments: call.arguments, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // Completion handlers arrive on a private queue; platform channel
    // results must be delivered on the main thread.
    private func queryPermissionState(result: @escaping FlutterResult) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                result(["status": "available", "state": self.stateName(settings.authorizationStatus)])
            }
        }
    }

    private func requestPermission(result: @escaping FlutterResult) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, error in
            DispatchQueue.main.async {
                if let error = error as NSError? {
                    result([
                        "status": "failed",
                        "reason": "macos_error_\(error.code)",
                        "message": error.localizedDescription,
                    ])
                    return
                }
                // The request answer alone is not the stored state; re-query
                // so a denied request reads back as denied on later runs.
                center.getNotificationSettings { settings in
                    DispatchQueue.main.async {
                        result([
                            "status": "available",
                            "state": self.stateName(settings.authorizationStatus),
                        ])
                    }
                }
            }
        }
    }

    private func post(arguments: Any?, result: @escaping FlutterResult) {
        let args = arguments as? [String: Any]
        let title = args?["title"] as? String ?? ""
        let body = args?["body"] as? String ?? ""
        if title.trimmingCharacters(in: .whitespaces).isEmpty ||
            body.trimmingCharacters(in: .whitespaces).isEmpty {
            result([
                "status": "invalidData",
                "reason": "missing_content",
                "message": "标题与内容不能为空",
            ])
            return
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let identifier = UUID().uuidString
        let request = UNNotificationRequest(
            identifier: identifier, content: content, trigger: nil)
        let center = UNUserNotificationCenter.current()
        center.add(request) { error in
            DispatchQueue.main.async {
                if let error = error as NSError? {
                    result([
                        "status": "failed",
                        "reason": "post_failed",
                        "message": error.localizedDescription,
                    ])
                    return
                }
                result(["status": "available", "notificationId": identifier])
            }
        }
    }

    private func cancel(arguments: Any?, result: @escaping FlutterResult) {
        let args = arguments as? [String: Any]
        guard let identifier = args?["notificationId"] as? String,
            !identifier.isEmpty else {
            result([
                "status": "invalidData",
                "reason": "missing_id",
                "message": "通知标识不能为空",
            ])
            return
        }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
        result(["status": "available", "cancelled": true])
    }

    private func stateName(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized:
            return "granted"
        case .denied:
            return "denied"
        case .notDetermined:
            return "notDetermined"
        case .provisional:
            return "provisional"
        default:
            return "unavailable"
        }
    }
}
