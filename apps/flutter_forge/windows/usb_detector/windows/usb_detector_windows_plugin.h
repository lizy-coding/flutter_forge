#ifndef USB_DETECTOR_WINDOWS_PLUGIN_H_
#define USB_DETECTOR_WINDOWS_PLUGIN_H_

#include <flutter/plugin_registrar_windows.h>
#include <flutter/plugin.h>

#include <memory>

namespace usb_detector_windows {

class UsbDetectorWindowsPlugin final : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(
      flutter::PluginRegistrarWindows* registrar);

  UsbDetectorWindowsPlugin(flutter::PluginRegistrarWindows* registrar);
  ~UsbDetectorWindowsPlugin() override;

 private:
  class Impl;
  std::unique_ptr<Impl> impl_;
};

}  // namespace usb_detector_windows

#ifdef FLUTTER_PLUGIN_IMPL
#define USB_DETECTOR_WINDOWS_EXPORT __declspec(dllexport)
#else
#define USB_DETECTOR_WINDOWS_EXPORT __declspec(dllimport)
#endif

extern "C" USB_DETECTOR_WINDOWS_EXPORT void
UsbDetectorWindowsPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

#endif  // USB_DETECTOR_WINDOWS_PLUGIN_H_
