#include "desktop_window_host.h"

#include <windows.h>
#include <commctrl.h>
#include <dwmapi.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <iostream>
#include <memory>
#include <string>

namespace {
using Value = flutter::EncodableValue;
using Map = flutter::EncodableMap;

bool SupportsSystemBackdrop() {
  // Public system backdrops require Windows 11 22H2 (build 22621).
  // The runner manifest declares Windows 10/11 compatibility. A failed
  // version check deliberately keeps Windows 10 and unknown hosts solid.
  OSVERSIONINFOEXW version{};
  version.dwOSVersionInfoSize = sizeof(version);
  version.dwBuildNumber = 22621;
  const DWORDLONG conditions =
      VerSetConditionMask(0, VER_BUILDNUMBER, VER_GREATER_EQUAL);
  return VerifyVersionInfoW(&version, VER_BUILDNUMBER, conditions) != FALSE;
}

class DesktopWindowHost final : public flutter::Plugin {
 public:
  DesktopWindowHost(flutter::PluginRegistrarWindows* registrar, HWND window)
      : window_(window), channel_(std::make_unique<flutter::MethodChannel<Value>>(
            registrar->messenger(), "flutter_forge/desktop_host",
            &flutter::StandardMethodCodec::GetInstance())) {
    channel_->SetMethodCallHandler([this](const auto& call, auto result) {
      const auto& method = call.method_name();
      if (method == "configure") {
        if (!configured_) {
          std::cerr << "[desktop_host] first configure received hwnd="
                    << window_ << std::endl;
        }
        configured_ = true;
        const auto* args = std::get_if<Map>(call.arguments());
        if (args) {
          const auto title = args->find(Value("title"));
          if (title != args->end()) {
            if (const auto* text = std::get_if<std::string>(&title->second)) {
              const int length = MultiByteToWideChar(CP_UTF8, 0, text->data(),
                  static_cast<int>(text->size()), nullptr, 0);
              std::wstring wide(static_cast<size_t>(length), L'\0');
              MultiByteToWideChar(CP_UTF8, 0, text->data(),
                  static_cast<int>(text->size()), wide.data(), length);
              SetWindowTextW(window_, wide.c_str());
            }
          }
          const auto theme = args->find(Value("themeMode"));
          if (theme != args->end()) {
            if (const auto* mode = std::get_if<std::string>(&theme->second)) {
              theme_mode_ = *mode;
            }
          }
        }
        ApplyTheme();
        result->Success(State());
      } else if (method == "minimize") {
        ShowWindow(window_, SW_MINIMIZE);
        result->Success(State());
      } else if (method == "captionDoubleClick") {
        if (!fullscreen_) ShowWindow(window_, IsZoomed(window_) ? SW_RESTORE : SW_MAXIMIZE);
        result->Success(State());
      } else if (method == "toggleFullscreen") {
        ToggleFullscreen();
        result->Success(State());
      } else if (method == "getState") {
        result->Success(State());
      } else if (method == "drag") {
        result->Success(State());
        if (!fullscreen_) {
          ReleaseCapture();
          POINT cursor{};
          if (GetCursorPos(&cursor)) {
            PostMessage(window_, WM_NCLBUTTONDOWN, HTCAPTION, MAKELPARAM(cursor.x, cursor.y));
          }
        }
      } else if (method == "close") {
        result->Success(State());
        PostMessage(window_, WM_CLOSE, 0, 0);
      } else {
        result->NotImplemented();
      }
    });
    // Install the handler before frame changes can re-enter message dispatch.
    SetWindowSubclass(window_, WindowProc, reinterpret_cast<UINT_PTR>(this),
                      reinterpret_cast<DWORD_PTR>(this));
    ConfigureFrame();
    std::cerr << "[desktop_host] registered hwnd=" << window_ << std::endl;
  }

  ~DesktopWindowHost() override {
    // Registrar teardown can run after the messenger's engine has been cleared.
    // The engine owns its message handlers; do not call messenger APIs here.
    *alive_ = false;
    DetachWindowSubclass();
  }

 private:
  void DetachWindowSubclass() {
    if (IsWindow(window_)) {
      RemoveWindowSubclass(window_, WindowProc, reinterpret_cast<UINT_PTR>(this));
    }
  }

  void ConfigureFrame() {
    const LONG_PTR style = GetWindowLongPtr(window_, GWL_STYLE);
    SetWindowLongPtr(window_, GWL_STYLE, style | WS_CAPTION | WS_SYSMENU |
        WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_THICKFRAME);
    SetWindowPos(window_, nullptr, 0, 0, 0, 0,
        SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED);
  }

  Value State() const {
    return Value(Map{
        {Value("active"), Value(GetForegroundWindow() == window_)},
        {Value("leadingInset"), Value(6.0)},
        {Value("trailingInset"), Value(6.0)},
        {Value("fullscreen"), Value(fullscreen_)},
        {Value("frameMode"), Value("system")},
        {Value("materialActive"), Value(false)},
        {Value("systemBackdropSupported"), Value(supports_system_backdrop_)},
        {Value("transparencyAllowed"), Value(TransparencyAllowed())},
    });
  }

  void ToggleFullscreen() {
    if (!fullscreen_) {
      placement_.length = sizeof(placement_);
      MONITORINFO monitor{};
      monitor.cbSize = sizeof(monitor);
      if (!GetWindowPlacement(window_, &placement_) ||
          !GetMonitorInfo(MonitorFromWindow(window_, MONITOR_DEFAULTTONEAREST), &monitor)) {
        return;
      }
      saved_style_ = GetWindowLongPtr(window_, GWL_STYLE);
      fullscreen_ = true;
      SetWindowLongPtr(window_, GWL_STYLE,
          saved_style_ & ~static_cast<LONG_PTR>(WS_CAPTION | WS_THICKFRAME));
      const RECT bounds = monitor.rcMonitor;
      SetWindowPos(window_, HWND_TOP, bounds.left, bounds.top,
          bounds.right - bounds.left, bounds.bottom - bounds.top,
          SWP_NOOWNERZORDER | SWP_FRAMECHANGED);
    } else {
      fullscreen_ = false;
      SetWindowLongPtr(window_, GWL_STYLE, saved_style_);
      SetWindowPlacement(window_, &placement_);
      SetWindowPos(window_, nullptr, 0, 0, 0, 0,
          SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_FRAMECHANGED);
    }
  }

  void ApplyTheme() {
    DWORD light = 1;
    DWORD size = sizeof(light);
    if (theme_mode_ == "system") {
      RegGetValueW(HKEY_CURRENT_USER,
          L"Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize",
          L"AppsUseLightTheme", RRF_RT_REG_DWORD, nullptr, &light, &size);
    }
    const BOOL dark = theme_mode_ == "dark" ||
                     (theme_mode_ == "system" && light == 0);
    DwmSetWindowAttribute(window_, 20, &dark, sizeof(dark));
    // Compatibility mode keeps the standard non-client frame and an opaque
    // client area. Do not extend DWM into the Flutter view or activate Mica.
    if (supports_system_backdrop_) {
      const int backdrop = 1;  // DWMSBT_NONE
      DwmSetWindowAttribute(window_, 38, &backdrop, sizeof(backdrop));
    }
  }

  bool TransparencyAllowed() const {
    HIGHCONTRASTW contrast{};
    contrast.cbSize = sizeof(contrast);
    if (SystemParametersInfoW(SPI_GETHIGHCONTRAST, sizeof(contrast), &contrast, 0) &&
        (contrast.dwFlags & HCF_HIGHCONTRASTON)) return false;
    DWORD enabled = 1;
    DWORD size = sizeof(enabled);
    RegGetValueW(HKEY_CURRENT_USER,
        L"Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize",
        L"EnableTransparency", RRF_RT_REG_DWORD, nullptr, &enabled, &size);
    return enabled != 0;
  }

  static LRESULT CALLBACK WindowProc(HWND window, UINT message, WPARAM wparam,
      LPARAM lparam, UINT_PTR /*subclass_id*/, DWORD_PTR reference) {
    auto* host = reinterpret_cast<DesktopWindowHost*>(reference);
    if (message == WM_DESTROY || message == WM_NCDESTROY) {
      // The original procedure synchronously destroys the controller and this
      // plugin. Detach before delegating and never touch host afterwards.
      host->DetachWindowSubclass();
      return DefSubclassProc(window, message, wparam, lparam);
    }
    // The standard system frame owns WM_NCCALCSIZE, WM_NCHITTEST and all
    // non-client button messages. Never overlap or cut holes in the view.
    if (message == WM_SIZE || message == WM_ACTIVATE || message == WM_DPICHANGED ||
        message == WM_SHOWWINDOW || message == WM_SETTINGCHANGE ||
        message == WM_DWMCOLORIZATIONCOLORCHANGED) {
      // Delegation can re-enter window teardown. Keep a separate lifetime token
      // so this callback does not dereference a plugin destroyed by that call.
      const auto alive = host->alive_;
      const auto result = DefSubclassProc(window, message, wparam, lparam);
      if (!*alive) return result;
      host->ApplyTheme();
      if (host->configured_) {
        host->channel_->InvokeMethod("windowState", std::make_unique<Value>(host->State()));
      }
      return result;
    }
    // WM_DESTROY may synchronously destroy the engine and this plugin. Never
    // access host after delegating to the original window procedure.
    return DefSubclassProc(window, message, wparam, lparam);
  }

  HWND window_;
  const std::shared_ptr<bool> alive_ = std::make_shared<bool>(true);
  const bool supports_system_backdrop_ = SupportsSystemBackdrop();
  bool fullscreen_ = false;
  bool configured_ = false;
  WINDOWPLACEMENT placement_{};
  LONG_PTR saved_style_ = 0;
  std::unique_ptr<flutter::MethodChannel<Value>> channel_;
  std::string theme_mode_ = "system";
};
}  // namespace

void RegisterDesktopWindowHost(flutter::FlutterViewController* controller,
                               HWND window) {
  if (!window) {
    window = GetAncestor(controller->view()->GetNativeWindow(), GA_ROOT);
  }
  auto* registrar = flutter::PluginRegistrarManager::GetInstance()
      ->GetRegistrar<flutter::PluginRegistrarWindows>(
          controller->engine()->GetRegistrarForPlugin("ForgeDesktopHost"));
  registrar->AddPlugin(std::make_unique<DesktopWindowHost>(registrar, window));
}
