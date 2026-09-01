# 5ef5a81 window lifecycle fix regression

Changed `apps/flutter_forge/macos/Runner/AppDelegate.swift` so closing the last window does not terminate the application process. The fresh macOS Release build passed and `bash tool/quality_gate.sh` passed all six stages.

The prior immediate process exit was not reproduced: after opening the Isolate category window, the Flutter Forge process remained alive according to `ps` after the close/read sequence. However, the Computer Use channel timed out repeatedly while reading the UI, so post-close UI reconnection and adsorption_line visual checks remain blocked. The report therefore keeps `MACOS_GATE=HOLD` and does not authorize Windows testing.
