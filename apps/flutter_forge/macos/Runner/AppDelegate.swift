import Cocoa
import FlutterMacOS
import desktop_multi_window

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
      RegisterGeneratedPlugins(registry: controller)
      self.registerFilePickerChannel(on: controller.engine.binaryMessenger)
    }

    if let controller = mainFlutterWindow?.contentViewController as? FlutterViewController {
      registerFilePickerChannel(on: controller.engine.binaryMessenger)
    }

    super.applicationDidFinishLaunching(notification)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  private func registerFilePickerChannel(on messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "file_picker_bridge/file_picker",
      binaryMessenger: messenger
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
