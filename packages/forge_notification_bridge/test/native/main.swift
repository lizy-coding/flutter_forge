import Cocoa
import FlutterMacOS
import UserNotifications
let plugin = ForgeNotificationBridgePlugin()
var results: [[String: Any]] = []
let first = plugin.ownedResult { results.append($0 as! [String: Any]) }
first(["status":"available"])
first(["status":"failed"])
assert(results.count == 1)
let second = plugin.ownedResult({ results.append($0 as! [String: Any]) }, permission: true)
plugin.closePending()
assert(results.count == 2)
assert(results.last?["reason"] as? String == "owner_closed")
second(["status":"available"])
assert(results.count == 2)
plugin.operationDeadline = 0.001
let third = plugin.ownedResult { results.append($0 as! [String: Any]) }
RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.03))
assert(results.count == 3)
assert(results.last?["reason"] as? String == "operation_unresolved")
third(["status":"available"])
assert(results.count == 3)
print("PASS: native notification unique completion/close/unresolved deadline/late reply, without system prompts")

let denied = ForgeNotificationBridgePlugin.errorOutcome(NSError(domain: UNErrorDomain, code: UNError.Code.notificationsNotAllowed.rawValue), operation: "permission")
assert(denied["status"] as? String == "permissionDenied")
assert(denied["reason"] as? String == "notifications_not_allowed")
let unrelated = ForgeNotificationBridgePlugin.errorOutcome(NSError(domain: "other", code: 1), operation: "post")
assert(unrelated["status"] as? String == "failed")
print("PASS: native UNErrorDomain notificationsNotAllowed mapping is permissionDenied; other domains stay failed")
