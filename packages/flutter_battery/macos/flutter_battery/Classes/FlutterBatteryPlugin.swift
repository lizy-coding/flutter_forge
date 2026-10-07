import Cocoa

public class FlutterBatteryPlugin: NSObject, FlutterPlugin {
    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var batteryMonitor: BatteryMonitor?
    private var eventChannelHandler: BatteryStreamHandler?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let plugin = FlutterBatteryPlugin()

        // Method Channel
        let methodChannel = FlutterMethodChannel(
            name: "flutter_battery",
            binaryMessenger: registrar.messenger
        )
        registrar.addMethodCallDelegate(plugin, channel: methodChannel)
        plugin.methodChannel = methodChannel

        // Event Channel
        let eventChannel = FlutterEventChannel(
            name: "flutter_battery/battery_stream",
            binaryMessenger: registrar.messenger
        )
        plugin.eventChannel = eventChannel

        // Initialize battery monitor
        plugin.batteryMonitor = BatteryMonitor()

        // Setup event channel handler
        let eventHandler = BatteryStreamHandler(batteryMonitor: plugin.batteryMonitor!)
        eventChannel.setStreamHandler(eventHandler)
        plugin.eventChannelHandler = eventHandler

        // Wire callback bridge (R005)
        plugin.wireCallbackBridge()
    }

    private func wireCallbackBridge() {
        guard let batteryMonitor = batteryMonitor else { return }

        batteryMonitor.setOnBatteryLevelChangeCallback { [weak self] level in
            self?.methodChannel?.invokeMethod("onBatteryLevelChanged", arguments: ["batteryLevel": level])
        }

        batteryMonitor.setOnBatteryInfoChangeCallback { [weak self] info in
            self?.methodChannel?.invokeMethod("onBatteryInfoChanged", arguments: info)
        }

        batteryMonitor.setOnBatteryHealthChangeCallback { [weak self] health in
            self?.methodChannel?.invokeMethod("onBatteryHealthChanged", arguments: health)
        }

        batteryMonitor.setOnLowBatteryCallback { [weak self] level in
            self?.methodChannel?.invokeMethod("onLowBattery", arguments: ["batteryLevel": level])
        }
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let batteryMonitor = batteryMonitor else {
            result(FlutterError(code: "UNAVAILABLE", message: "Battery monitor not available", details: nil))
            return
        }

        switch call.method {
        case "getPlatformVersion":
            let version = ProcessInfo.processInfo.operatingSystemVersionString
            result("macOS \(version)")

        case "getPlatformCapabilities":
            result(getPlatformCapabilities())

        case "configureBatteryStream":
            guard let config = BatteryStreamConfiguration.parse(call.arguments) else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid battery sampling configuration", details: nil))
                return
            }
            eventChannelHandler?.configure(config)
            result(true)

        case "getBatteryLevel":
            let level = batteryMonitor.getBatteryLevel()
            result(level)

        case "getBatteryInfo":
            let info = batteryMonitor.getBatteryInfo()
            result(info)

        case "getBatteryHealth":
            let health = batteryMonitor.getBatteryHealth()
            result(health)

        case "getBatteryOptimizationTips":
            let tips = batteryMonitor.getBatteryOptimizationTips()
            result(tips)

        case "startBatteryLevelListening":
            batteryMonitor.startBatteryLevelListening()
            result(true)

        case "stopBatteryLevelListening":
            batteryMonitor.stopBatteryLevelListening()
            result(true)

        case "startBatteryInfoListening":
            if let args = call.arguments as? [String: Any],
               let intervalMs = args["intervalMs"] as? Int {
                batteryMonitor.startBatteryInfoListening(intervalMs: intervalMs)
            } else {
                batteryMonitor.startBatteryInfoListening()
            }
            result(true)

        case "stopBatteryInfoListening":
            batteryMonitor.stopBatteryInfoListening()
            result(true)

        case "startBatteryHealthListening":
            if let args = call.arguments as? [String: Any],
               let intervalMs = args["intervalMs"] as? Int {
                batteryMonitor.startBatteryHealthListening(intervalMs: intervalMs)
            } else {
                batteryMonitor.startBatteryHealthListening()
            }
            result(true)

        case "stopBatteryHealthListening":
            batteryMonitor.stopBatteryHealthListening()
            result(true)

        case "setPushInterval":
            if let args = call.arguments as? [String: Any],
               let intervalMs = args["intervalMs"] as? Int {
                batteryMonitor.setBatteryLevelPushInterval(intervalMs: intervalMs)
            }
            result(true)

        case "setBatteryLevelThreshold":
            if let args = call.arguments as? [String: Any],
               let threshold = args["threshold"] as? Int {
                batteryMonitor.setBatteryThreshold(threshold)
            }
            result(true)

        case "stopBatteryMonitoring":
            batteryMonitor.stopMonitoring()
            result(true)

        case "scheduleNotification":
            result(FlutterError(code: "NOT_SUPPORTED", message: "Scheduled notifications not supported on macOS", details: nil))

        case "showNotification":
            result(FlutterError(code: "NOT_SUPPORTED", message: "Native notifications not supported on macOS", details: nil))

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func getPlatformCapabilities() -> [String: Bool] {
        return [
            "scopedObservations": true,
            "batteryLevel": true,
            "batteryInfo": true,
            "batteryHealth": true,
            "batteryLevelStream": true,
            "batteryInfoStream": true,
            "batteryHealthStream": true,
            "lowBatteryMonitoring": true,
            "nativeNotifications": false,
            "scheduledNotifications": false,
            "blePeerSync": false,
            "bleCharacteristicNotifications": false,
            "iotExampleBridge": false,
        ]
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        eventChannelHandler?.dispose()
        batteryMonitor?.dispose()
        methodChannel = nil
        eventChannel = nil
        eventChannelHandler = nil
    }
}
