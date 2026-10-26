import Cocoa
import LocalAuthentication
import FlutterMacOS

final class FakeContext: LAContext {
    var completion: ((Bool, Error?) -> Void)?
    var invalidated = false
    override func evaluatePolicy(_ policy: LAPolicy, localizedReason: String, reply: @escaping (Bool, Error?) -> Void) {
        completion = reply
    }
    override func invalidate() { invalidated = true }
}
func drain() { RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.03)) }
let plugin = FlutterBiometricPlugin()
let first = FakeContext()
plugin.contextFactory = { first }
var replies: [[String: Any]] = []
func authenticate(_ id: String, strength: String = "strong") {
    plugin.handle(FlutterMethodCall(methodName: "authenticate", arguments: ["reason":"fake test", "operationId":id, "strength":strength])) { value in
        replies.append(value as! [String:Any])
    }
}
authenticate("first")
authenticate("busy")
assert(replies.last?["reason"] as? String == "authentication_in_progress")
plugin.handle(FlutterMethodCall(methodName:"cancel",arguments:["operationId":"other"])) { _ in }
assert(!first.invalidated)
plugin.handle(FlutterMethodCall(methodName:"cancel",arguments:["operationId":"first"])) { _ in }
assert(first.invalidated)
assert(replies.last?["status"] as? String == "systemCancel")
let second = FakeContext()
plugin.contextFactory = { second }
authenticate("second", strength: "strongWithCredential")
first.completion?(true,nil)
drain()
assert(replies.count == 2)
second.completion?(true,nil)
drain()
assert(replies.count == 3)
assert(replies.last?["authenticationMethod"] as? String == "unknown")
print("PASS: native macOS authentication busy/cancel/late callback/unknown, without system prompts")
