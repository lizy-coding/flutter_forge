# 5ef5a81 macOS lifecycle fix rerun

Cold-started the freshly built Release and opened the Isolate category window successfully. After closing it, the Release process remained alive (`ps` observed pid 43719), so the previous immediate process-exit symptom is not reproduced.

The Computer Use accessibility channel still timed out while reconnecting to the post-close UI. This leaves main-window recovery and the remaining adsorption_line visual path blocked. Keep `MACOS_GATE=HOLD`; do not start Windows self-test.
