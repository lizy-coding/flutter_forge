#ifndef RUNNER_DESKTOP_WINDOW_HOST_H_
#define RUNNER_DESKTOP_WINDOW_HOST_H_

#include <flutter/flutter_view_controller.h>

// Supply the top-level HWND when the Flutter view is not parented yet.
void RegisterDesktopWindowHost(flutter::FlutterViewController* controller,
                               HWND window = nullptr);

#endif  // RUNNER_DESKTOP_WINDOW_HOST_H_
