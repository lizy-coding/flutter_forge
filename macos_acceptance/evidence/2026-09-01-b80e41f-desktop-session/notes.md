# b80e41f macOS Desktop UI Acceptance

The Codex Desktop interaction channel was operational in this run. The Release application created the basic, state, and platform category windows, and each window rendered its first frame without a black screen.

The platform child window opened the native file picker and returned normally after Cancel.

The `debounce_throttle` page rendered acceptably at 1024dp and 600dp. At 360dp, the visualization remains laid out wider than the viewport and the right card is clipped. This is a real UI failure, so the macOS gate remains HOLD. Same-category reuse and three complete close/reopen rounds were not used to override this result because the 360dp failure already prevents PASS.

Windows self-test was not started.
