"""Checks real IOKit notification/timer ownership with minimal channel type stubs.

Run on macOS with Swift installed. This does not simulate a Flutter engine or
claim native-window acceptance; it checks the checked-in handlers' destruction.
"""
from pathlib import Path
import subprocess
import tempfile

classes = Path(__file__).resolve().parents[2] / 'macos/flutter_battery/Classes'
stubs = '''
public typealias FlutterEventSink = (Any?) -> Void
public protocol FlutterStreamHandler {}
public final class FlutterError: NSObject {
    public init(code: String, message: String, details: Any?) { super.init() }
}
public final class BatteryMonitor {
    public func readBattery(sample: String) -> [String: Any] { ["availability": "unknown"] }
}
'''
code = 'import Cocoa\nimport IOKit.ps\n' + stubs
for name in ('BatteryChangesHandler.swift', 'BatteryStreamHandler.swift'):
    code += (classes / name).read_text().replace('import FlutterMacOS\n', '')
code += '''
extension BatteryChangesHandler {
    func observedSource() -> CFRunLoopSource? { runLoopSource }
}
extension BatteryStreamHandler {
    func observedTimers() -> [Timer] { timers }
}
let monitor = BatteryMonitor()
var changes: BatteryChangesHandler? = BatteryChangesHandler(monitor: monitor)
weak var weakChanges = changes
assert(changes!.onListen(withArguments: nil, eventSink: { _ in }) == nil)
let previous = changes!.observedSource()!
assert(changes!.onListen(withArguments: nil, eventSink: { _ in }) == nil)
assert(!CFRunLoopSourceIsValid(previous))
let current = changes!.observedSource()!
assert(CFRunLoopSourceIsValid(current))
changes = nil
assert(weakChanges == nil)
assert(!CFRunLoopSourceIsValid(current))
assert(!CFRunLoopContainsSource(CFRunLoopGetMain(), current, .commonModes))

var sampler: BatteryStreamHandler? = BatteryStreamHandler(batteryMonitor: monitor)
weak var weakSampler = sampler
assert(sampler!.onListen(withArguments: nil, eventSink: { _ in }) == nil)
let timers = sampler!.observedTimers()
assert(!timers.isEmpty && timers.allSatisfy { $0.isValid })
sampler = nil
assert(weakSampler == nil)
assert(timers.allSatisfy { !$0.isValid })
print("macOS battery source and timer teardown: PASS")
'''
with tempfile.TemporaryDirectory(prefix='forge-battery-lifecycle-') as directory:
    script = Path(directory) / 'lifecycle.swift'
    script.write_text(code)
    subprocess.run(['swift', str(script)], check=True)
