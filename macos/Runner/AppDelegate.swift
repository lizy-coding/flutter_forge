import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    if let controller = mainFlutterWindow?.contentViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "flutter_study/file_picker",
        binaryMessenger: controller.engine.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "pickFile":
          result(self.pickFile(call.arguments))
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    super.applicationDidFinishLaunching(notification)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  private func pickFile(_ arguments: Any?) -> [String: String]? {
    let params = arguments as? [String: Any]
    let extensions = params?["allowedExtensions"] as? [String] ?? []
    let title = params?["title"] as? String
    let message = params?["message"] as? String

    let panel = NSOpenPanel()
    panel.title = title ?? "选择文件"
    panel.message = message ?? "选择要导入的文件"
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = false
    if !extensions.isEmpty {
      panel.allowedFileTypes = extensions
    }

    guard panel.runModal() == .OK else {
      return nil
    }

    guard let url = panel.url else {
      return nil
    }

    return [
      "path": url.path,
      "name": url.lastPathComponent
    ]
  }
}
