# Full macOS UI automation

Fresh Release automation verified startup, the asynchronous category window first frame, process survival after category close, and main-window accessibility recovery after explicit Window-menu refocus. Two close/reopen rounds passed.

The full run found a concrete product failure in `adsorption_line`: at 360dp the horizontally scrolling toolbar still clips the color controls and line-width controls. The third lifecycle round was blocked by coordinate-based retargeting after route state changed, and the native file picker flow was not reached in this run.

Because the compact layout failure is explicit, `macos_ui_interaction=FAIL`, `MACOS_GATE=HOLD`, and `windows_ready=false`. Windows self-test was not started.
