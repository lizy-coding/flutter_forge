import Cocoa
import FlutterMacOS
import IOKit.ps

// System notifications own this channel. No polling timers are created.
final class BatteryChangesHandler: NSObject, FlutterStreamHandler {
    private weak var monitor: BatteryMonitor?
    private var sink: FlutterEventSink?
    private var runLoopSource: CFRunLoopSource?
    private var samples: [String] = []
    init(monitor: BatteryMonitor) { self.monitor = monitor }

    func configure(_ arguments: Any?) -> Bool {
        guard let args = arguments as? [String: Any],
              let level = args["monitorBatteryLevel"] as? Bool,
              let info = args["monitorBatteryInfo"] as? Bool,
              let health = args["monitorBatteryHealth"] as? Bool else { return false }
        samples = [(level, "level"), (info, "info"), (health, "health")].filter { $0.0 }.map { $0.1 }
        if sink != nil { emit() }
        return true
    }
    private func emit() {
        guard let monitor = monitor, let sink = sink else { return }
        for sample in samples {
            var payload = monitor.readBattery(sample: sample)
            payload["type"] = sample == "info" ? "BATTERY_INFO" : sample == "health" ? "BATTERY_HEALTH" : "BATTERY_LEVEL"
            sink(payload)
        }
    }
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        dispose()
        sink = events
        guard let source = IOPSNotificationCreateRunLoopSource({ context in
            guard let context = context else { return }
            Unmanaged<BatteryChangesHandler>.fromOpaque(context).takeUnretainedValue().emit()
        }, Unmanaged.passUnretained(self).toOpaque())?.takeRetainedValue() else {
            sink = nil
            return FlutterError(code: "UNAVAILABLE", message: "Power-source notifications unavailable", details: nil)
        }
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        emit()
        return nil
    }
    func onCancel(withArguments arguments: Any?) -> FlutterError? { dispose(); return nil }
    func dispose() {
        if let source = runLoopSource { CFRunLoopSourceInvalidate(source) }
        runLoopSource = nil
        sink = nil
    }
}
