#include "usb_detector_windows_plugin.h"

#include <dbt.h>
#include <setupapi.h>
#include <usbiodef.h>
#include <windows.h>

#include <memory>
#include <string>
#include <vector>

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

namespace usb_detector_windows {
namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

std::wstring GetDeviceProperty(HDEVINFO info, SP_DEVINFO_DATA* data,
                               DWORD property) {
  DWORD type = 0;
  DWORD size = 0;
  if (!SetupDiGetDeviceRegistryPropertyW(info, data, property, &type, nullptr,
                                         0, &size) &&
      GetLastError() != ERROR_INSUFFICIENT_BUFFER) {
    return {};
  }
  std::vector<BYTE> buffer(size);
  if (!SetupDiGetDeviceRegistryPropertyW(info, data, property, &type,
                                         buffer.data(), size, &size)) {
    return {};
  }
  return std::wstring(reinterpret_cast<wchar_t*>(buffer.data()));
}

EncodableList EnumerateUsbDevices() {
  HDEVINFO info = SetupDiGetClassDevsW(
      &GUID_DEVINTERFACE_USB_DEVICE, nullptr, nullptr,
      DIGCF_DEVICEINTERFACE | DIGCF_PRESENT);
  if (info == INVALID_HANDLE_VALUE) {
    return {};
  }

  EncodableList devices;
  for (DWORD index = 0;; ++index) {
    SP_DEVICE_INTERFACE_DATA interface_data = {};
    interface_data.cbSize = sizeof(interface_data);
    if (!SetupDiEnumDeviceInterfaces(info, nullptr, &GUID_DEVINTERFACE_USB_DEVICE,
                                     index, &interface_data)) {
      if (GetLastError() == ERROR_NO_MORE_ITEMS) {
        break;
      }
      continue;
    }

    DWORD required_size = 0;
    SetupDiGetDeviceInterfaceDetailW(info, &interface_data, nullptr, 0,
                                     &required_size, nullptr);
    if (required_size == 0) {
      continue;
    }
    std::vector<BYTE> detail_buffer(required_size);
    auto* detail = reinterpret_cast<SP_DEVICE_INTERFACE_DETAIL_DATA_W*>(
        detail_buffer.data());
    detail->cbSize = sizeof(SP_DEVICE_INTERFACE_DETAIL_DATA_W);
    SP_DEVINFO_DATA device_data = {};
    device_data.cbSize = sizeof(device_data);
    if (!SetupDiGetDeviceInterfaceDetailW(
            info, &interface_data, detail, required_size, nullptr,
            &device_data)) {
      continue;
    }

    wchar_t instance_id[MAX_DEVICE_ID_LEN] = {};
    std::wstring id;
    if (SetupDiGetDeviceInstanceIdW(info, &device_data, instance_id,
                                    MAX_DEVICE_ID_LEN, nullptr)) {
      id = instance_id;
    } else {
      id = detail->DevicePath;
    }
    std::wstring name = GetDeviceProperty(info, &device_data,
                                          SPDRP_FRIENDLYNAME);
    if (name.empty()) {
      name = GetDeviceProperty(info, &device_data, SPDRP_DEVICEDESC);
    }

    EncodableMap device;
    device[EncodableValue("id")] = EncodableValue(id);
    device[EncodableValue("name")] = EncodableValue(name);
    devices.emplace_back(std::move(device));
  }
  SetupDiDestroyDeviceInfoList(info);
  return devices;
}

}  // namespace

class UsbDetectorWindowsPlugin::Impl {
 public:
  explicit Impl(flutter::PluginRegistrarWindows* registrar)
      : channel_(std::make_unique<flutter::MethodChannel<EncodableValue>>(
            registrar->messenger(), "usb_detector/usb",
            &flutter::StandardMethodCodec::GetInstance())) {
    channel_->SetMethodCallHandler(
        [this](const auto& call, auto result) {
          if (call.method_name() == "enumerate") {
            result->Success(EncodableValue(EnumerateUsbDevices()));
            return;
          }
          result->NotImplemented();
        });

    WNDCLASSW window_class = {};
    window_class.lpfnWndProc = &Impl::WindowProc;
    window_class.hInstance = GetModuleHandle(nullptr);
    window_class.lpszClassName = L"FlutterUsbDetectorMessageWindow";
    RegisterClassW(&window_class);
    window_ = CreateWindowExW(0, window_class.lpszClassName, L"", 0, 0, 0,
                              0, 0, HWND_MESSAGE, nullptr,
                              window_class.hInstance, this);
    if (window_ == nullptr) {
      return;
    }

    DEV_BROADCAST_DEVICEINTERFACE_W filter = {};
    filter.dbcc_size = sizeof(filter);
    filter.dbcc_devicetype = DBT_DEVTYP_DEVICEINTERFACE;
    filter.dbcc_classguid = GUID_DEVINTERFACE_USB_DEVICE;
    notification_ = RegisterDeviceNotificationW(
        window_, &filter, DEVICE_NOTIFY_WINDOW_HANDLE);
  }

  ~Impl() {
    if (notification_ != nullptr) {
      UnregisterDeviceNotification(notification_);
    }
    if (window_ != nullptr) {
      DestroyWindow(window_);
    }
    UnregisterClassW(L"FlutterUsbDetectorMessageWindow", GetModuleHandle(nullptr));
  }

 private:
  static LRESULT CALLBACK WindowProc(HWND window, UINT message, WPARAM wparam,
                                     LPARAM lparam) {
    auto* self = reinterpret_cast<Impl*>(GetWindowLongPtrW(window, GWLP_USERDATA));
    if (message == WM_NCCREATE) {
      auto* create = reinterpret_cast<CREATESTRUCTW*>(lparam);
      self = static_cast<Impl*>(create->lpCreateParams);
      SetWindowLongPtrW(window, GWLP_USERDATA,
                        reinterpret_cast<LONG_PTR>(self));
    }
    if (self != nullptr && message == WM_DEVICECHANGE &&
        (wparam == DBT_DEVICEARRIVAL || wparam == DBT_DEVICEREMOVECOMPLETE)) {
      self->channel_->InvokeMethod(
          "onDevicesChanged",
          std::make_unique<EncodableValue>(EnumerateUsbDevices()));
    }
    return DefWindowProcW(window, message, wparam, lparam);
  }

  std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel_;
  HWND window_ = nullptr;
  HDEVNOTIFY notification_ = nullptr;
};

UsbDetectorWindowsPlugin::UsbDetectorWindowsPlugin(
    flutter::PluginRegistrarWindows* registrar)
    : impl_(std::make_unique<Impl>(registrar)) {}

UsbDetectorWindowsPlugin::~UsbDetectorWindowsPlugin() = default;

void UsbDetectorWindowsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  registrar->AddPlugin(std::make_unique<UsbDetectorWindowsPlugin>(registrar));
}

}  // namespace usb_detector_windows

void UsbDetectorWindowsPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  usb_detector_windows::UsbDetectorWindowsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
