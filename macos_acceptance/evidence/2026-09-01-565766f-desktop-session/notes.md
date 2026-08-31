# 565766f macOS Desktop UI Acceptance

The Release application was rebuilt from `565766f9c7d63ae160289d87da43d8023509105d` before this run.

The `debounce_throttle` page rendered without horizontal clipping at 360dp, 600dp, and 1024dp. Reopening the basic category focused the existing category window. The basic category window was then closed and reopened successfully for three consecutive rounds, with a valid first frame each time.

The platform child window opened the native file picker and returned normally after Cancel.

All requested macOS UI checks passed. `MACOS_GATE=PASS` and `windows_ready=true`. Windows self-test has not been started by this run.
