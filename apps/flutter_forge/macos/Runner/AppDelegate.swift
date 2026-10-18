import Cocoa
import FlutterMacOS
import desktop_multi_window

@main
class AppDelegate: FlutterAppDelegate {
  private var childWindowCloseObserver: NSObjectProtocol?
  private var terminating = false
  private var desktopHosts: [ObjectIdentifier: ForgeWindowHost] = [:]

  override func applicationDidFinishLaunching(_ notification: Notification) {
    FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
      RegisterGeneratedPlugins(registry: controller)
      self.registerFilePickerChannel(on: controller.engine.binaryMessenger)
      self.registerDesktopHost(controller)
    }

    if let controller = mainFlutterWindow?.contentViewController as? FlutterViewController {
      registerFilePickerChannel(on: controller.engine.binaryMessenger)
      registerDesktopHost(controller)
    }

    childWindowCloseObserver = NotificationCenter.default.addObserver(
      forName: NSWindow.willCloseNotification,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      guard let self,
            let closingWindow = notification.object as? NSWindow else {
        return
      }
      if closingWindow === self.mainFlutterWindow {
        self.terminating = true
        DispatchQueue.main.async { NSApp.terminate(nil) }
        return
      }
      guard !self.terminating else { return }
      self.desktopHosts.removeValue(forKey: ObjectIdentifier(closingWindow))
      guard let mainWindow = self.mainFlutterWindow else { return }
      DispatchQueue.main.async {
        NSApp.activate(ignoringOtherApps: true)
        mainWindow.makeKeyAndOrderFront(nil)
      }
    }

    super.applicationDidFinishLaunching(notification)
    installNavigationMenu()
  }

  private func registerDesktopHost(_ controller: FlutterViewController) {
    guard let window = controller.view.window else { return }
    desktopHosts[ObjectIdentifier(window)] = ForgeWindowHost(
      window: window, controller: controller
    )
  }

  private func sendDesktopCommand(_ command: String) {
    guard let window = NSApp.keyWindow ?? mainFlutterWindow else { return }
    desktopHosts[ObjectIdentifier(window)]?.send(command)
  }

  @objc private func searchModules(_ sender: Any?) { sendDesktopCommand("search") }
  @objc private func showHome(_ sender: Any?) { sendDesktopCommand("home") }
  @objc private func goBack(_ sender: Any?) { sendDesktopCommand("back") }
  @objc private func toggleSidebar(_ sender: Any?) { sendDesktopCommand("toggleSidebar") }

  fileprivate func installNavigationMenu() {
    guard let mainMenu = NSApp.mainMenu else { return }
    guard !mainMenu.items.contains(where: { $0.title == "导航" }) else { return }
    // Reuse the standard Find command instead of installing a second Cmd-F.
    func configureFind(in menu: NSMenu) {
      for item in menu.items {
        if item.keyEquivalent == "f" && item.keyEquivalentModifierMask == .command {
          item.title = "搜索模块…"
          item.target = self
          item.action = #selector(searchModules(_:))
        }
        if let submenu = item.submenu { configureFind(in: submenu) }
      }
    }
    configureFind(in: mainMenu)
    let menu = NSMenu(title: "导航")
    let commands: [(String, Selector, String)] = [
      ("主页", #selector(showHome(_:)), "1"),
      ("返回", #selector(goBack(_:)), "["),
      ("搜索模块…", #selector(searchModules(_:)), ""),
      ("切换侧栏", #selector(toggleSidebar(_:)), "s"),
    ]
    for (title, action, key) in commands {
      let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
      item.target = self
      item.keyEquivalentModifierMask = key == "s" ? [.command, .control] : .command
      menu.addItem(item)
    }
    let item = NSMenuItem(title: "导航", action: nil, keyEquivalent: "")
    item.submenu = menu
    mainMenu.insertItem(item, at: min(3, mainMenu.items.count))
  }

  deinit {
    if let childWindowCloseObserver {
      NotificationCenter.default.removeObserver(childWindowCloseObserver)
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationDidBecomeActive(_ notification: Notification) {
    super.applicationDidBecomeActive(notification)
    installNavigationMenu()
    guard !terminating, let mainWindow = mainFlutterWindow,
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

// Every engine uses the same Flutter chrome; AppKit only handles window actions.
private final class ForgeWindowHost: NSObject {
  private weak var window: NSWindow?
  private weak var controller: FlutterViewController?
  private let channel: FlutterMethodChannel
  private var observers: [NSObjectProtocol] = []
  private var fullscreenTransitioning = false

  init(window: NSWindow, controller: FlutterViewController) {
    self.window = window
    self.controller = controller
    channel = FlutterMethodChannel(
      name: "flutter_forge/desktop_host",
      binaryMessenger: controller.engine.binaryMessenger
    )
    super.init()
    window.toolbar = nil
    window.styleMask.insert(.fullSizeContentView)
    window.collectionBehavior.insert(.fullScreenPrimary)
    window.titlebarAppearsTransparent = true
    window.titleVisibility = .hidden
    window.isMovableByWindowBackground = false
    window.isOpaque = true
    window.backgroundColor = .windowBackgroundColor
    window.contentMinSize = NSSize(width: 800, height: 600)
    for button: NSWindow.ButtonType in [.closeButton, .miniaturizeButton, .zoomButton] {
      window.standardWindowButton(button)?.isHidden = false
    }
    for name in [NSWindow.didBecomeKeyNotification, NSWindow.didResignKeyNotification,
                 NSWindow.didResizeNotification, NSWindow.didEndLiveResizeNotification,
                 NSWindow.willEnterFullScreenNotification, NSWindow.willExitFullScreenNotification,
                 NSWindow.didEnterFullScreenNotification, NSWindow.didExitFullScreenNotification] {
      observers.append(NotificationCenter.default.addObserver(
        forName: name, object: window, queue: .main
      ) { [weak self] notification in
        guard let self else { return }
        if notification.name == NSWindow.willEnterFullScreenNotification ||
           notification.name == NSWindow.willExitFullScreenNotification {
          self.fullscreenTransitioning = true
        }
        if notification.name == NSWindow.didEnterFullScreenNotification ||
           notification.name == NSWindow.didExitFullScreenNotification {
          self.fullscreenTransitioning = false
          for button: NSWindow.ButtonType in [.closeButton, .miniaturizeButton, .zoomButton] {
            self.window?.standardWindowButton(button)?.isHidden = false
          }
        }
        self.publishState()
      })
    }
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self, let window = self.window else { result(nil); return }
      switch call.method {
      case "configure":
        let arguments = call.arguments as? [String: Any] ?? [:]
        if let title = arguments["title"] as? String { window.title = title }
        switch arguments["themeMode"] as? String {
        case "light": window.appearance = NSAppearance(named: .aqua)
        case "dark": window.appearance = NSAppearance(named: .darkAqua)
        default: window.appearance = nil
        }
        (NSApp.delegate as? AppDelegate)?.installNavigationMenu()
        result(self.state())
      case "drag":
        result(self.state())
        if !window.styleMask.contains(.fullScreen), let event = NSApp.currentEvent {
          window.performDrag(with: event)
        }
      case "minimize":
        window.miniaturize(nil)
        result(self.state())
      case "captionDoubleClick":
        if window.styleMask.contains(.fullScreen) {
          result(self.state())
          return
        }
        switch UserDefaults.standard.string(forKey: "AppleActionOnDoubleClick") {
        case "Minimize": window.miniaturize(nil)
        case "None": break
        default: window.zoom(nil)
        }
        result(self.state())
      case "toggleFullscreen":
        result(self.state())
        if !self.fullscreenTransitioning {
          self.fullscreenTransitioning = true
          window.toggleFullScreen(nil)
        }
      case "getState": result(self.state())
      case "close":
        result(self.state())
        DispatchQueue.main.async {
          if window === (NSApp.delegate as? AppDelegate)?.mainFlutterWindow {
            NSApp.terminate(nil)
          } else {
            window.performClose(nil)
          }
        }
      default: result(FlutterMethodNotImplemented)
      }
    }
  }

  private func state() -> [String: Any] {
    ["active": window?.isKeyWindow ?? false,
     "fullscreen": window?.styleMask.contains(.fullScreen) ?? false,
     "leadingInset": 80.0, "trailingInset": 6.0]
  }

  private func publishState() { channel.invokeMethod("windowState", arguments: state()) }

  func send(_ command: String) {
    channel.invokeMethod(command, arguments: nil)
  }

  deinit {
    for observer in observers { NotificationCenter.default.removeObserver(observer) }
    channel.setMethodCallHandler(nil)
  }
}
