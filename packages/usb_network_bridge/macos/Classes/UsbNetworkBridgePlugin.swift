import FlutterMacOS

@_silgen_name("ForgeUsbMacNcmInterfacesLinkAnchor")
private func linkInterfaces()
@_silgen_name("ForgeUsbMacBoundTcpLinkAnchor")
private func linkTransport()

public class UsbNetworkBridgePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    linkInterfaces()
    linkTransport()
  }
}
