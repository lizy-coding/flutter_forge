import Cocoa
import UserNotifications
import FlutterMacOS

/// UNUserNotificationCenter adapter over the
/// forge_notification/notifications channel. Authorization queries and
/// notification posts resolve to typed status maps; nothing throws.
public class ForgeNotificationBridgePlugin: NSObject, FlutterPlugin {
    private var pending: [UUID: FlutterResult] = [:]
    private var deadlines: [UUID: DispatchWorkItem] = [:]
    private var permissionPending = false

    func closePending(reason: String = "owner_closed") {
        let callbacks = Array(pending.values)
        pending.removeAll()
        deadlines.values.forEach { $0.cancel() }
        deadlines.removeAll()
        permissionPending = false
        callbacks.forEach { $0(["status": "unavailable", "reason": reason, "message": "引擎已退出；系统操作可能仍会完成，请重新查询状态"]) }
    }

    var operationDeadline: TimeInterval = 10
    var permissionDeadline: TimeInterval = 120

    func ownedResult(_ result: @escaping FlutterResult, permission: Bool = false) -> FlutterResult {
        let id = UUID()
        pending[id] = result
        let complete: FlutterResult = { [weak self] value in
            guard let self = self, let callback = self.pending.removeValue(forKey: id) else { return }
            self.deadlines.removeValue(forKey: id)?.cancel()
            if permission { self.permissionPending = false }
            callback(value)
        }
        let deadline = DispatchWorkItem {
            complete(["status": "unavailable", "reason": "operation_unresolved", "message": "系统结果未返回，操作可能仍会完成，请查询状态后重试"])
        }
        deadlines[id] = deadline
        DispatchQueue.main.asyncAfter(deadline: .now() + (permission ? permissionDeadline : operationDeadline), execute: deadline)
        return complete
    }

    private var closeObserver: NSObjectProtocol?
    private weak var hostView: NSView?

    private func bindLifetime(_ registrar: FlutterPluginRegistrar) {
        hostView = registrar.view
        closeObserver = NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: nil, queue: .main) { [weak self] note in
            guard let self = self, let window = note.object as? NSWindow,
                  self.hostView?.window === window else { return }
            self.closePending(reason: "window_closed")
        }
    }

    deinit {
        if let observer = closeObserver { NotificationCenter.default.removeObserver(observer) }
        deadlines.values.forEach { $0.cancel() }
    }

    private static let channelName = "forge_notification/notifications"

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: ForgeNotificationBridgePlugin.channelName,
            binaryMessenger: registrar.messenger
        )
        let plugin = ForgeNotificationBridgePlugin()
        plugin.bindLifetime(registrar)
        registrar.addMethodCallDelegate(plugin, channel: channel)
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
            queryPermissionState(result: ownedResult(result))
        case "requestPermission":
            if permissionPending {
                result(["status": "unavailable", "reason": "request_in_progress", "message": "已有授权请求进行中"])
            } else {
                permissionPending = true
                requestPermission(result: ownedResult(result, permission: true))
            }
        case "post":
            post(arguments: call.arguments, result: ownedResult(result))
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
                result(["status": "available", "state": Self.stateName(settings.authorizationStatus)])
            }
        }
    }

    private func requestPermission(result: @escaping FlutterResult) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, error in
            DispatchQueue.main.async {
                if let error = error as NSError? {
                    result(Self.errorOutcome(error, operation: "permission"))
                    return
                }
                // The request answer alone is not the stored state; re-query
                // so a denied request reads back as denied on later runs.
                center.getNotificationSettings { settings in
                    DispatchQueue.main.async {
                        result([
                            "status": "available",
                            "state": Self.stateName(settings.authorizationStatus),
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
                    result(Self.errorOutcome(error, operation: "post"))
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

    static func errorOutcome(_ error: NSError, operation: String) -> [String: Any] {
        let permissionDenied = error.domain == UNErrorDomain && error.code == UNError.Code.notificationsNotAllowed.rawValue
        return [
            "status": permissionDenied ? "permissionDenied" : "failed",
            "reason": permissionDenied ? "notifications_not_allowed" : (operation == "post" ? "post_failed" : "macos_error_\(error.code)"),
            "message": "\(error.domain) (\(error.code)): \(error.localizedDescription)",
        ]
    }

    private static func stateName(_ status: UNAuthorizationStatus) -> String {
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
