import Cocoa
import FlutterMacOS

struct BatteryStreamConfiguration {
    let level: Bool
    let info: Bool
    let health: Bool
    let levelInterval: Int
    let infoInterval: Int
    let healthInterval: Int
    let debounce: Bool

    static let initial = BatteryStreamConfiguration(level: true, info: false, health: false,
        levelInterval: 1000, infoInterval: 5000, healthInterval: 10000, debounce: true)

    static func parse(_ arguments: Any?) -> BatteryStreamConfiguration? {
        guard let args = arguments as? [String: Any],
              let level = args["monitorBatteryLevel"] as? Bool,
              let info = args["monitorBatteryInfo"] as? Bool,
              let health = args["monitorBatteryHealth"] as? Bool,
              let levelInterval = args["intervalMs"] as? Int,
              let infoInterval = args["batteryInfoIntervalMs"] as? Int,
              let healthInterval = args["batteryHealthIntervalMs"] as? Int,
              let debounce = args["enableDebounce"] as? Bool,
              [levelInterval, infoInterval, healthInterval].allSatisfy({ (100...3600000).contains($0) })
        else { return nil }
        return BatteryStreamConfiguration(level: level, info: info, health: health,
            levelInterval: levelInterval, infoInterval: infoInterval, healthInterval: healthInterval, debounce: debounce)
    }
}

// Event sampling owns its timers; legacy MethodChannel callbacks own separate timers.
public class BatteryStreamHandler: NSObject, FlutterStreamHandler {
    private weak var monitor: BatteryMonitor?
    private var sink: FlutterEventSink?
    private var timers: [Timer] = []
    private var configuration = BatteryStreamConfiguration.initial
    private var lastPowerState: String?

    public init(batteryMonitor: BatteryMonitor) { monitor = batteryMonitor; super.init() }

    func configure(_ config: BatteryStreamConfiguration) {
        configuration = config
        stopTimers()
        guard sink != nil else { return }
        lastPowerState = nil
        if config.level { start(interval: config.levelInterval, type: "BATTERY_LEVEL") }
        if config.info { start(interval: config.infoInterval, type: "BATTERY_INFO") }
        if config.health { start(interval: config.healthInterval, type: "BATTERY_HEALTH") }
    }

    private func start(interval: Int, type: String) {
        sample(type)
        timers.append(Timer.scheduledTimer(withTimeInterval: Double(interval) / 1000, repeats: true) { [weak self] _ in
            self?.sample(type)
        })
    }

    private func sample(_ type: String) {
        guard let monitor = monitor, let sink = sink else { return }
        let sample = type == "BATTERY_INFO" ? "info" : type == "BATTERY_HEALTH" ? "health" : "level"
        var payload = monitor.readBattery(sample: sample)
        let signature = ["level", "powerSource", "isCharging", "isCharged"].map { String(describing: payload[$0]) }.joined(separator: "|")
        if type == "BATTERY_LEVEL" && payload["availability"] as? String == "available" && configuration.debounce && lastPowerState == signature { return }
        if type == "BATTERY_LEVEL" { lastPowerState = signature }
        payload["type"] = payload["availability"] as? String == "available" ? type : "BATTERY_UNAVAILABLE"
        sink(payload)
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        sink = events
        configure(configuration)
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        stopTimers()
        sink = nil
        lastPowerState = nil
        return nil
    }

    private func stopTimers() {
        timers.forEach { $0.invalidate() }
        timers.removeAll()
    }

    func dispose() { stopTimers(); sink = nil }
}
