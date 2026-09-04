import Cocoa
import FlutterMacOS
import desktop_multi_window

@main
class AppDelegate: FlutterAppDelegate {
  private var childWindowCloseObserver: NSObjectProtocol?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
      RegisterGeneratedPlugins(registry: controller)
      self.registerFilePickerChannel(on: controller.engine.binaryMessenger)
    }

    if let controller = mainFlutterWindow?.contentViewController as? FlutterViewController {
      registerFilePickerChannel(on: controller.engine.binaryMessenger)
    }

    childWindowCloseObserver = NotificationCenter.default.addObserver(
      forName: NSWindow.willCloseNotification,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      guard let self,
            let closingWindow = notification.object as? NSWindow,
            closingWindow !== self.mainFlutterWindow else {
        return
      }
      guard let mainWindow = self.mainFlutterWindow else { return }
      DispatchQueue.main.async {
        NSApp.activate(ignoringOtherApps: true)
        mainWindow.makeKeyAndOrderFront(nil)
      }
    }

    super.applicationDidFinishLaunching(notification)
  }

  deinit {
    if let childWindowCloseObserver {
      NotificationCenter.default.removeObserver(childWindowCloseObserver)
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationDidBecomeActive(_ notification: Notification) {
    super.applicationDidBecomeActive(notification)
    guard let mainWindow = mainFlutterWindow,
          !mainWindow.isVisible || NSApp.keyWindow == nil else {
      return
    }
    mainWindow.makeKeyAndOrderFront(nil)
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
