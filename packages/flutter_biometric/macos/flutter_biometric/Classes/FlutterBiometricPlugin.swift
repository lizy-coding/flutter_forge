import Cocoa
import LocalAuthentication
import FlutterMacOS

/// LocalAuthentication adapter over the flutter_biometric/auth channel.
/// Capability queries and prompt replies resolve to typed status maps;
/// nothing on this channel throws.
public class FlutterBiometricPlugin: NSObject, FlutterPlugin {
    var contextFactory: () -> LAContext = { LAContext() }
    private var activeContext: LAContext?
    private var activeId: String?
    private var activeCompletion: (([String: Any]) -> Void)?


    private func cancelActive(reason: String) {
        let context = activeContext
        activeCompletion?(["status": "systemCancel", "reason": reason, "message": "认证操作已中断"])
        context?.invalidate()
    }

    private var closeObserver: NSObjectProtocol?
    private weak var hostView: NSView?

    private func bindLifetime(_ registrar: FlutterPluginRegistrar) {
        hostView = registrar.view
        closeObserver = NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: nil, queue: .main) { [weak self] note in
            guard let self = self, let window = note.object as? NSWindow,
                  self.hostView?.window === window else { return }
            self.cancelActive(reason: "window_closed")
        }
    }

    deinit {
        if let observer = closeObserver { NotificationCenter.default.removeObserver(observer) }
        activeContext?.invalidate()
    }

    private static let channelName = "flutter_biometric/auth"

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: FlutterBiometricPlugin.channelName,
            binaryMessenger: registrar.messenger
        )
        let plugin = FlutterBiometricPlugin()
        plugin.bindLifetime(registrar)
        registrar.addMethodCallDelegate(plugin, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "queryCapabilities":
            result(queryCapabilities())
        case "cancel":
            let args = call.arguments as? [String: Any]
            if let id = args?["operationId"] as? String, id == activeId {
                cancelActive(reason: "owner_cancelled")
            }
            result(nil)
        case "authenticate":
            authenticate(arguments: call.arguments, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func queryCapabilities() -> [String: Any] {
        let context = LAContext()
        var biometricError: NSError?
        let canBiometrics = context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics, error: &biometricError)

        // biometryType is only meaningful after a canEvaluatePolicy call.
        var fingerprint = false
        var face = false
        var enrolled: [String] = []
        if canBiometrics {
            switch context.biometryType {
            case .touchID:
                fingerprint = true
                enrolled.append("fingerprint")
            case .faceID:
                face = true
                enrolled.append("face")
            default:
                break
            }
        }

        let credentialContext = LAContext()
        var credentialError: NSError?
        let canCredential = credentialContext.canEvaluatePolicy(
            .deviceOwnerAuthentication, error: &credentialError)

        return [
            "deviceSupported": fingerprint || face || canCredential,
            "fingerprintAvailable": fingerprint,
            "faceAvailable": face,
            "deviceCredentialAvailable": canCredential,
            "enrolledTypes": enrolled,
            "sensorEnrollmentKnown": true,
            "strongAvailable": canBiometrics,
            "weakAvailable": canBiometrics,
        ]
    }

    private func authenticate(arguments: Any?, result: @escaping FlutterResult) {
        guard activeId == nil else {
            result(["status": "unavailable", "reason": "authentication_in_progress", "message": "已有认证进行中"])
            return
        }
        let args = arguments as? [String: Any]
        guard let reason = args?["reason"] as? String, !reason.trimmingCharacters(in: .whitespaces).isEmpty else {
            result([
                "status": "invalidData",
                "reason": "missing_reason",
                "message": "认证原因不能为空",
            ])
            return
        }
        let strength = args?["strength"] as? String ?? "strong"
        let policy: LAPolicy = strength == "strongWithCredential"
            ? .deviceOwnerAuthentication
            : .deviceOwnerAuthenticationWithBiometrics

        let context = contextFactory()
        let id = args?["operationId"] as? String ?? UUID().uuidString
        activeId = id
        activeContext = context
        var replied = false
        let complete: ([String: Any]) -> Void = { [weak self] map in
            guard let self = self else { return }
            if !replied {
                replied = true
                if self.activeId == id {
                    self.activeId = nil
                    self.activeContext = nil
                    self.activeCompletion = nil
                }
                result(map)
            }
        }

        activeCompletion = complete
        // evaluatePolicy replies on a private queue; platform channel results
        // must be delivered on the main thread.
        context.evaluatePolicy(policy, localizedReason: reason) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    complete([
                        "status": "authenticated",
                        "authenticationMethod": strength == "strongWithCredential" ? "unknown" : "biometric",
                    ])
                    return
                }
                guard let self = self else { return }
                complete(self.mapError(error as NSError?))
            }
        }
    }

    private func mapError(_ error: NSError?) -> [String: Any] {
        guard let error = error else {
            return [
                "status": "failed",
                "reason": "macos_error_unknown",
                "message": "LocalAuthentication 未返回错误详情",
            ]
        }
        let status: String
        switch error.code {
        case LAError.userCancel.rawValue, LAError.userFallback.rawValue:
            status = "userCancel"
        case LAError.systemCancel.rawValue, LAError.appCancel.rawValue:
            status = "systemCancel"
        case LAError.passcodeNotSet.rawValue:
            status = "credentialNotSet"
        case LAError.biometryNotAvailable.rawValue:
            status = "noHardware"
        case LAError.biometryNotEnrolled.rawValue:
            status = "notEnrolled"
        case LAError.biometryLockout.rawValue:
            status = "lockout"
        case LAError.invalidContext.rawValue:
            status = "unavailable"
        case LAError.authenticationFailed.rawValue:
            status = "failed"
        default:
            status = "failed"
        }
        return [
            "status": status,
            "reason": "macos_error_\(error.code)",
            "message": error.localizedDescription,
        ]
    }
}
