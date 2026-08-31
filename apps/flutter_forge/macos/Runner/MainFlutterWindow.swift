import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    precondition(
      flutterViewController.engine.run(withEntrypoint: nil),
      "Failed to start the main Flutter engine"
    )
    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
