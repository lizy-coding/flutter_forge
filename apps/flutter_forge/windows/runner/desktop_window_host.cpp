#include "desktop_window_host.h"

#include <windows.h>
#include <windowsx.h>
#include <algorithm>
#include <commctrl.h>
#include <dwmapi.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

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
  DesktopWindowHost(flutter::PluginRegistrarWindows* registrar, HWND window, HWND view)
      : window_(window), view_(view), channel_(std::make_unique<flutter::MethodChannel<Value>>(
            registrar->messenger(), "flutter_forge/desktop_host",
            &flutter::StandardMethodCodec::GetInstance())) {
    SetWindowSubclass(window_, WindowProc, reinterpret_cast<UINT_PTR>(this),
                      reinterpret_cast<DWORD_PTR>(this));
    ConfigureFrame();
    channel_->SetMethodCallHandler([this](const auto& call, auto result) {
      const auto& method = call.method_name();
      if (method == "configure") {
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
          const auto material = args->find(Value("materialEnabled"));
          material_requested_ = material != args->end() &&
              std::get_if<bool>(&material->second) && std::get<bool>(material->second);
        }
        ApplyTheme();
        RefreshChrome();
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
    RefreshChrome();
  }

  int ResizeBorder() const {
    const UINT dpi = GetDpiForWindow(window_);
    return GetSystemMetricsForDpi(SM_CYSIZEFRAME, dpi) +
           GetSystemMetricsForDpi(SM_CXPADDEDBORDER, dpi);
  }

  bool CaptionBounds(RECT* bounds) const {
    if (fullscreen_ || !IsWindowVisible(window_) || IsIconic(window_) ||
        FAILED(DwmGetWindowAttribute(window_, DWMWA_CAPTION_BUTTON_BOUNDS,
                                     bounds, sizeof(*bounds))) ||
        bounds->right <= bounds->left || bounds->bottom <= bounds->top) {
      return false;
    }
    RECT frame{};
    GetWindowRect(window_, &frame);
    POINT top_left{frame.left + bounds->left, frame.top + bounds->top};
    POINT bottom_right{frame.left + bounds->right, frame.top + bounds->bottom};
    ScreenToClient(view_, &top_left);
    ScreenToClient(view_, &bottom_right);
    *bounds = RECT{top_left.x, top_left.y, bottom_right.x, bottom_right.y};
    return true;
  }

  void RefreshChrome() {
    if (!IsWindow(view_) || IsIconic(window_)) return;
    const int top = fullscreen_ ? 0 : MulDiv(48, GetDpiForWindow(window_), 96);
    const MARGINS margins = material_active_
        ? MARGINS{-1, -1, -1, -1} : MARGINS{0, 0, top, 0};
    DwmExtendFrameIntoClientArea(window_, &margins);
    if (fullscreen_) {
      SetWindowRgn(view_, nullptr, TRUE);
      return;
    }
    RECT client{};
    GetClientRect(view_, &client);
    // The child must leave native buttons visible, not just forward their input.
    const int border = IsZoomed(window_) ? 0 : ResizeBorder();
    HRGN region = CreateRectRgn(0, border, client.right, client.bottom);
    RECT caption{};
    if (CaptionBounds(&caption)) {
      HRGN buttons = CreateRectRgnIndirect(&caption);
      CombineRgn(region, region, buttons, RGN_DIFF);
      DeleteObject(buttons);
    }
    if (!SetWindowRgn(view_, region, TRUE)) DeleteObject(region);
  }

  Value State() const {
    RECT client{};
    RECT caption{};
    GetClientRect(view_, &client);
    const double scale = static_cast<double>(GetDpiForWindow(window_)) / 96.0;
    const double trailing = fullscreen_ ? 6.0 : CaptionBounds(&caption)
        ? std::max(0.0, static_cast<double>(client.right - caption.left) / scale)
        : 138.0;
    return Value(Map{
        {Value("active"), Value(GetForegroundWindow() == window_)},
        {Value("leadingInset"), Value(6.0)},
        {Value("trailingInset"), Value(trailing)},
        {Value("fullscreen"), Value(fullscreen_)},
        {Value("materialActive"), Value(material_active_)},
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
    RefreshChrome();
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
    if (!supports_system_backdrop_) {
      material_active_ = false;
      return;
    }
    const int backdrop = material_requested_ && TransparencyAllowed() ? 2 : 1;
    // Public DWMWA_SYSTEMBACKDROP_TYPE (Windows 11 22H2+). Failure leaves
    // older Windows on the existing opaque background; no undocumented APIs.
    material_active_ = SUCCEEDED(DwmSetWindowAttribute(window_, 38, &backdrop,
                                                     sizeof(backdrop))) && backdrop == 2;
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
    LRESULT dwm_result = 0;
    if (!host->fullscreen_ &&
        DwmDefWindowProc(window, message, wparam, lparam, &dwm_result)) {
      return dwm_result;
    }
    if (message == WM_NCCALCSIZE && wparam && !host->fullscreen_) {
      auto* params = reinterpret_cast<NCCALCSIZE_PARAMS*>(lparam);
      const LONG proposed_top = params->rgrc[0].top;
      const auto result = DefSubclassProc(window, message, wparam, lparam);
      params->rgrc[0].top = proposed_top + (IsZoomed(window) ? host->ResizeBorder() : 0);
      return result;
    }
    if (message == WM_NCHITTEST && !host->fullscreen_ && !IsZoomed(window)) {
      RECT frame{};
      GetWindowRect(window, &frame);
      const LONG y = GET_Y_LPARAM(lparam);
      if (y >= frame.top && y < frame.top + host->ResizeBorder()) {
        const LONG x = GET_X_LPARAM(lparam);
        const int border = host->ResizeBorder();
        if (x < frame.left + border) return HTTOPLEFT;
        if (x >= frame.right - border) return HTTOPRIGHT;
        return HTTOP;
      }
    }
    if (message == WM_SIZE || message == WM_ACTIVATE || message == WM_DPICHANGED ||
        message == WM_SHOWWINDOW || message == WM_SETTINGCHANGE ||
        message == WM_DWMCOLORIZATIONCOLORCHANGED) {
      // Delegation can re-enter window teardown. Keep a separate lifetime token
      // so this callback does not dereference a plugin destroyed by that call.
      const auto alive = host->alive_;
      const auto result = DefSubclassProc(window, message, wparam, lparam);
      if (!*alive) return result;
      host->ApplyTheme();
      host->RefreshChrome();
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
  HWND view_;
  const std::shared_ptr<bool> alive_ = std::make_shared<bool>(true);
  const bool supports_system_backdrop_ = SupportsSystemBackdrop();
  bool fullscreen_ = false;
  bool configured_ = false;
  bool material_requested_ = false;
  bool material_active_ = false;
  WINDOWPLACEMENT placement_{};
  LONG_PTR saved_style_ = 0;
  std::unique_ptr<flutter::MethodChannel<Value>> channel_;
  std::string theme_mode_ = "system";
};
}  // namespace

void RegisterDesktopWindowHost(flutter::FlutterViewController* controller) {
  const HWND window = GetAncestor(controller->view()->GetNativeWindow(), GA_ROOT);
  auto* registrar = flutter::PluginRegistrarManager::GetInstance()
      ->GetRegistrar<flutter::PluginRegistrarWindows>(
          controller->engine()->GetRegistrarForPlugin("ForgeDesktopHost"));
  registrar->AddPlugin(std::make_unique<DesktopWindowHost>(registrar, window,
      controller->view()->GetNativeWindow()));
}
