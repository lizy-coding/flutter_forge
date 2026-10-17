import Cocoa
import FlutterMacOS
import desktop_multi_window

@main
class AppDelegate: FlutterAppDelegate {
  private var childWindowCloseObserver: NSObjectProtocol?
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
      guard closingWindow !== self.mainFlutterWindow else { return }
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
    return false
  }

  override func applicationDidBecomeActive(_ notification: Notification) {
    super.applicationDidBecomeActive(notification)
    installNavigationMenu()
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

// Each engine keeps its existing root controller. Only the public wrapper
// receives a material sibling behind the Flutter render view.
private final class ForgeWindowHost: NSObject, NSToolbarDelegate {
  private weak var window: NSWindow?
  private weak var controller: FlutterViewController?
  private let channel: FlutterMethodChannel
  private static let sidebarID = NSToolbarItem.Identifier("forge.sidebar")
  private static let searchID = NSToolbarItem.Identifier("forge.search")
  private static let homeID = NSToolbarItem.Identifier("forge.home")

  init(window: NSWindow, controller: FlutterViewController) {
    self.window = window
    self.controller = controller
    channel = FlutterMethodChannel(
      name: "flutter_forge/desktop_host",
      binaryMessenger: controller.engine.binaryMessenger
    )
    super.init()
    window.isOpaque = true
    window.backgroundColor = .windowBackgroundColor
    window.titlebarAppearsTransparent = false
    window.titleVisibility = .visible
    window.toolbarStyle = .unifiedCompact
    controller.backgroundColor = .clear

    let root = controller.view
    let material = NSVisualEffectView(frame: root.bounds)
    material.autoresizingMask = [.width, .height]
    material.material = .sidebar
    material.blendingMode = .behindWindow
    material.state = .followsWindowActiveState
    root.addSubview(material, positioned: .below, relativeTo: nil)

    // Cocoa shares configurations for matching identifiers. Category windows
    // omit the sidebar item, so each window needs its own toolbar identity.
    let toolbar = NSToolbar(identifier: "forge.desktop.\(UUID().uuidString)")
    toolbar.delegate = self
    toolbar.displayMode = .iconOnly
    toolbar.allowsUserCustomization = false
    toolbar.showsBaselineSeparator = true
    window.toolbar = toolbar

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { result(nil); return }
      if call.method == "ensureMenus" {
        (NSApp.delegate as? AppDelegate)?.installNavigationMenu()
        result(nil)
      } else if call.method == "setAppearance" {
        switch call.arguments as? String {
        case "light": self.window?.appearance = NSAppearance(named: .aqua)
        case "dark": self.window?.appearance = NSAppearance(named: .darkAqua)
        default: self.window?.appearance = nil
        }
        result(nil)
      } else if call.method == "setTitle" {
        if let title = call.arguments as? String { self.window?.title = title }
        result(nil)
      } else if call.method == "setSidebarAvailable" {
        if call.arguments as? Bool == false,
           let toolbar = self.window?.toolbar,
           let index = toolbar.items.firstIndex(where: { $0.itemIdentifier == Self.sidebarID }) {
          toolbar.removeItem(at: index)
        }
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  func send(_ command: String) {
    if let input = controller?.view.subviews.first(where: { $0.acceptsFirstResponder }) {
      window?.makeFirstResponder(input)
    }
    channel.invokeMethod(command, arguments: nil)
  }

  @objc private func toggleSidebar(_ sender: Any?) { send("toggleSidebar") }
  @objc private func search(_ sender: Any?) { send("search") }
  @objc private func home(_ sender: Any?) { send("home") }

  func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    [Self.sidebarID, Self.homeID, .flexibleSpace, Self.searchID]
  }

  func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    toolbarDefaultItemIdentifiers(toolbar)
  }

  func toolbar(
    _ toolbar: NSToolbar,
    itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
    willBeInsertedIntoToolbar flag: Bool
  ) -> NSToolbarItem? {
    let item = NSToolbarItem(itemIdentifier: itemIdentifier)
    let symbol: String
    switch itemIdentifier {
    case Self.sidebarID:
      symbol = "sidebar.left"; item.label = "切换侧栏"
      item.action = #selector(toggleSidebar(_:))
    case Self.homeID:
      symbol = "house"; item.label = "主页"
      item.action = #selector(home(_:))
    case Self.searchID:
      symbol = "magnifyingglass"; item.label = "搜索模块"
      item.action = #selector(search(_:))
    default: return nil
    }
    item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: item.label)
    item.toolTip = item.label
    item.target = self
    return item
  }
}
